// ExportManager.swift - Export system coordinator
// Part of Phase 06 - Export System

import SwiftUI
import AppKit

/// Export errors
enum ExportError: Error {
    case noImage
    case saveFailed(Error)
    case clipboardFailed
    case exportInProgress

    var localizedDescription: String {
        switch self {
        case .noImage: return "No image to export"
        case .saveFailed(let error): return "Save failed: \(error.localizedDescription)"
        case .clipboardFailed: return "Failed to copy to clipboard"
        case .exportInProgress: return "Export already in progress"
        }
    }
}

/// Export coordinator managing file save, clipboard, and format export
@MainActor
final class ExportManager: ObservableObject {
    // MARK: - Published State

    @Published var isExporting = false
    @Published var exportProgress: Double = 0
    @Published var errorMessage: String?

    // File manager for file operations
    // Since this class is @MainActor, this is on main actor too
    private let fileManager = FileManager.default

    // MARK: - Export

    func export(
        image: NSImage,
        options: ExportOptions,
        cropper: some ImageCropper
    ) async throws {
        guard !isExporting else {
            throw ExportError.exportInProgress
        }

        isExporting = true
        exportProgress = 0
        errorMessage = nil

        defer {
            isExporting = false
        }

        do {
            exportProgress = 0.2
            let cropped = cropper.crop(image)

            if let url = options.outputPath {
                exportProgress = 0.4
                try await saveFile(cropped, to: url, options: options)
            }

            if options.copyToClipboard {
                exportProgress = 0.8
                copyToClipboard(cropped)
            }

            exportProgress = 1.0
        } catch {
            errorMessage = (error as? ExportError)?.localizedDescription ?? error.localizedDescription
            throw error
        }
    }

    // MARK: - File Save

    private func saveFile(_ image: NSImage, to url: URL, options: ExportOptions) async throws {
        switch options.format {
        case .png:
            try exportPNG(image: image, to: url)
        case .jpeg:
            try exportJPEG(image: image, quality: options.jpegQuality, to: url)
        }
    }

    func generateFilename(format: ExportFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "MacShot_\(timestamp).\(format.fileExtension)"
    }

    func validateOutputURL(_ url: URL) -> URL? {
        let directory = url.deletingLastPathComponent()
        guard (try? fileManager.attributesOfItem(atPath: directory.path)) != nil else {
            return nil
        }
        return url
    }

    // MARK: - Clipboard

    private func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    func copyToClipboard(data: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
    }

    func quickCopyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    func quickSaveToDesktop(_ image: NSImage) -> URL? {
        guard let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            return nil
        }
        let filename = generateFilename(format: .png)
        let destination = desktopURL.appendingPathComponent(filename)

        do {
            try exportPNG(image: image, to: destination)
            return destination
        } catch {
            return nil
        }
    }

    // MARK: - Defaults from Settings

    /// Create default ExportOptions from SettingsStore
    /// Think of it like "get user's saved export preferences"
    static func defaultOptions() -> ExportOptions {
        var options = ExportOptions()

        // Load format from settings
        options.format = SettingsStore.defaultFormat

        // Load quality from settings
        options.jpegQuality = SettingsStore.defaultQuality

        // Load output folder from settings
        options.outputPath = SettingsStore.getOutputFolderURL()

        // Copy to clipboard by default (can be made configurable later)
        options.copyToClipboard = true

        return options
    }

    /// Create ExportOptions with specific format, using settings for other values
    /// Think of it like "use this format, but keep other preferences from settings"
    static func optionsWithFormat(_ format: ExportFormat) -> ExportOptions {
        var options = defaultOptions()
        options.format = format
        return options
    }
}
