// ExportManager.swift - Export system coordinator
// Part of Phase 06 - Export System

import SwiftUI
import AppKit

/// Export errors
enum ExportError: Error, LocalizedError {
    case noImage
    case saveFailed(Error)
    case clipboardFailed
    case exportInProgress
    case insufficientDiskSpace(required: Int64, available: Int64)
    case noOutputLocation
    case locationNotWritable(URL)
    case fileNotWritable(URL)
    case invalidOutputLocation(URL)
    case invalidImage(size: CGSize)
    case tiffConversionFailed(size: CGSize, reason: String)
    case bitmapCreationFailed(size: CGSize, tiffSize: Int)
    case pngEncodingFailed(size: CGSize, bitsPerSample: Int, samplesPerPixel: Int)
    case jpegEncodingFailed(size: CGSize, quality: Double)
    case conversionFailed

    var localizedDescription: String {
        switch self {
        case .noImage: return "No image to export"
        case .saveFailed(let error): return "Save failed: \(error.localizedDescription)"
        case .clipboardFailed: return "Failed to copy to clipboard"
        case .exportInProgress: return "Export already in progress"
        case .insufficientDiskSpace(let required, let available):
            let requiredMB = required / 1_000_000
            let availableMB = available / 1_000_000
            return "Not enough disk space. Need \(requiredMB)MB, only \(availableMB)MB available."
        case .noOutputLocation: return "No output location specified"
        case .locationNotWritable(let url): return "Cannot write to: \(url.path)"
        case .fileNotWritable(let url): return "File is locked or read-only: \(url.lastPathComponent)"
        case .invalidOutputLocation(let url): return "Invalid output location: \(url.path)"
        case .invalidImage(let size): return "Invalid image for export: \(Int(size.width)) x \(Int(size.height))"
        case .tiffConversionFailed(let size, let reason): return "TIFF conversion failed for \(Int(size.width)) x \(Int(size.height)) image: \(reason)"
        case .bitmapCreationFailed(let size, let tiffSize): return "Bitmap creation failed: image=\(Int(size.width))x\(Int(size.height)), tiff=\(tiffSize) bytes"
        case .pngEncodingFailed(let size, let bits, let samples): return "PNG encoding failed: \(Int(size.width))x\(Int(size.height)), \(bits) bits, \(samples) samples"
        case .jpegEncodingFailed(let size, let quality): return "JPEG encoding failed: \(Int(size.width))x\(Int(size.height)) at quality \(Int(quality * 100))%"
        case .conversionFailed: return "Failed to convert image format"
        }
    }

    var errorDescription: String? {
        localizedDescription
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidImage: return "Try capturing the screenshot again."
        case .pngEncodingFailed, .jpegEncodingFailed: return "Try using a different export format."
        case .tiffConversionFailed, .bitmapCreationFailed: return "The image may be corrupted. Try recapturing."
        case .insufficientDiskSpace: return "Free up disk space or choose a different location."
        case .locationNotWritable, .fileNotWritable: return "Choose a different save location or check permissions."
        default: return nil
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

    // MARK: - Validation

    private func validateOutputLocation(_ url: URL) async throws {
        let manager = FileManager.default

        // Check if parent directory exists
        let parentURL = url.deletingLastPathComponent()
        var isDirectory: ObjCBool = false

        if !manager.fileExists(atPath: parentURL.path, isDirectory: &isDirectory) {
            // Try to create directory
            try manager.createDirectory(at: parentURL, withIntermediateDirectories: true)
        }

        guard isDirectory.boolValue || manager.fileExists(atPath: parentURL.path, isDirectory: &isDirectory) else {
            throw ExportError.invalidOutputLocation(url)
        }

        // Check write permission
        if !manager.isWritableFile(atPath: parentURL.path) {
            throw ExportError.locationNotWritable(url)
        }

        // Check if file exists and is locked
        if manager.fileExists(atPath: url.path) {
            if !manager.isWritableFile(atPath: url.path) {
                throw ExportError.fileNotWritable(url)
            }
        }
    }

    private func validateDiskSpace(for image: NSImage, format: ExportFormat) async throws {
        // Get volume attributes using URL resource values
        // Use root directory to get overall disk space
        let rootURL = URL(fileURLWithPath: "/")

        guard let resourceValues = try? rootURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let availableSpace = resourceValues.volumeAvailableCapacityForImportantUsage else {
            // Can't determine space, attempt anyway
            return
        }

        // Estimate output file size
        let estimatedSize = estimateFileSize(for: image, format: format)
        let safetyMargin: Int64 = 5_000_000  // 5MB margin

        guard availableSpace >= estimatedSize + safetyMargin else {
            throw ExportError.insufficientDiskSpace(
                required: estimatedSize,
                available: availableSpace
            )
        }
    }

    private func estimateFileSize(for image: NSImage, format: ExportFormat) -> Int64 {
        let dimensions = image.size.width * image.size.height
        let components: CGFloat = format == .png ? 4 : 3  // RGBA vs RGB

        // Quality factor for JPEG
        let quality: CGFloat
        if format == .jpeg {
            quality = ExportOptions().jpegQuality
        } else {
            quality = 1.0
        }

        // Rough estimate: width * height * components * quality
        let uncompressed = dimensions * components
        let estimated = format == .png ? uncompressed : uncompressed * quality * 0.15

        return Int64(estimated)
    }

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
            exportProgress = 0.1

            if let url = options.outputPath {
                // Validate output location
                try await validateOutputLocation(url)

                // Validate disk space
                try await validateDiskSpace(for: image, format: options.format)
            }

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
        // Basic validation: ensure directory exists
        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        // Export based on format
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