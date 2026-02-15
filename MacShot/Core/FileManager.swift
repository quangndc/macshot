// FileManager.swift
// Complete file management with edge case handling
// Think of it like a librarian that organizes all your screenshots

import AppKit
import Foundation

// Image format options (PNG or JPEG)
// Think of it like choosing between "high quality" (PNG) and "smaller size" (JPEG)
enum ImageFormat {
    case png
    case jpeg

    // File extension for this format
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }
}

// File management errors with user-friendly messages
// Think of it like error labels on a vending machine
enum FileError: Error, LocalizedError {
    case directoryNotAccessible(URL)
    case diskSpaceInsufficient(required: Int64, available: Int64)
    case writeFailed(Error)
    case invalidFilename(String)

    // Human-readable error description
    var errorDescription: String? {
        switch self {
        case .directoryNotAccessible(let url):
            "Cannot access save folder: \(url.path)"
        case .diskSpaceInsufficient(let required, let available):
            "Not enough disk space. Need \(required / 1_000_000)MB, only \(available / 1_000_000)MB available."
        case .writeFailed(let error):
            "Failed to save screenshot: \(error.localizedDescription)"
        case .invalidFilename(let name):
            "Invalid filename: \(name)"
        }
    }
}

// Main file manager for screenshots
// @MainActor means this runs on main thread for safety
@MainActor
final class ScreenshotFileManager: Sendable {

    // MARK: - Configuration

    // Where to save screenshots (default: Pictures folder)
    // Think of it like which drawer to put your photos in
    var saveDirectory: URL

    // What format to save in (PNG = high quality, JPEG = smaller)
    var defaultFormat: ImageFormat = .png

    // Add timestamp to filename (like "Screenshot_2025-02-15_143022")
    var includeTimestamp = true

    // MARK: - Initialization

    // Create file manager with custom save directory
    // Think of it like choosing which folder to use
    init(saveDirectory: URL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!) {
        self.saveDirectory = saveDirectory
    }

    // MARK: - Operations

    // Save screenshot with all validations
    // Think of it like "put photo in envelope, address it, and mail it"
    func saveScreenshot(_ image: NSImage, name: String? = nil) async throws -> URL {
        // 1. Validate directory accessibility
        // Check if folder exists and we can write to it
        try validateDirectory()

        // 2. Check disk space
        // Make sure enough room for screenshot
        try validateDiskSpace(for: image)

        // 3. Generate filename
        // Create name like "Screenshot_2025-02-15_143022"
        let filename = name ?? generateFilename()

        // 4. Validate filename
        // Check for invalid characters and length
        try validateFilename(filename)

        // 5. Create file URL
        // Combine folder + filename + extension
        let fileURL = saveDirectory.appendingPathComponent(filename)
            .appendingPathExtension(defaultFormat.fileExtension)

        // 6. Handle filename collision
        // If file exists, add counter (like "_1", "_2")
        let finalURL = try handleCollision(fileURL)

        // 7. Write file
        // Convert image to data and save to disk
        try await writeImage(image, to: finalURL)

        return finalURL
    }

    // Generate filename with timestamp
    // Think of it like creating a label for your photo
    func generateFilename(mode: CaptureMode = .fullscreen) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"

        let timestamp = includeTimestamp ? "_\(formatter.string(from: Date()))" : ""
        let prefix: String

        switch mode {
        case .fullscreen:
            prefix = "Screenshot"
        case .region:
            prefix = "RegionCapture"
        case .window:
            prefix = "WindowCapture"
        }

        return "\(prefix)\(timestamp)"
    }

    // Simplified version that doesn't require CaptureMode import
    func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = includeTimestamp ? "_\(formatter.string(from: Date()))" : ""
        return "Screenshot\(timestamp)"
    }

    // Delete old files older than maxAge
    // Think of it like "spring cleaning" - throw away old photos
    func cleanupOldFiles(maxAge: TimeInterval) async throws {
        let manager = FileManager.default
        let contents = try manager.contentsOfDirectory(
            at: saveDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        )

        let now = Date()
        for url in contents {
            if let creationDate = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate {
                // If file is older than maxAge seconds, delete it
                if now.timeIntervalSince(creationDate) > maxAge {
                    try manager.removeItem(at: url)
                }
            }
        }
    }

    // MARK: - Private Helpers

    // Check if save directory is accessible
    // Think of it like checking if drawer opens and isn't locked
    private func validateDirectory() throws {
        let manager = FileManager.default

        // Check if directory exists
        var isDirectory: ObjCBool = false
        if !manager.fileExists(atPath: saveDirectory.path, isDirectory: &isDirectory) {
            // Try to create directory
            try manager.createDirectory(at: saveDirectory, withIntermediateDirectories: true)
        }

        // Check if writable (not read-only)
        if !manager.isWritableFile(atPath: saveDirectory.path) {
            throw FileError.directoryNotAccessible(saveDirectory)
        }
    }

    // Check if enough disk space for screenshot
    // Think of it like checking if envelope fits in mailbox
    private func validateDiskSpace(for image: NSImage) throws {
        // Estimate image size (width * height * 4 bytes for RGBA)
        let estimatedSize = Int64(image.size.width * image.size.height * 4)

        let manager = FileManager.default

        do {
            // Get URL resource values for disk space info
            let values = try saveDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])

            // Get available space on disk
            if let available = values.volumeAvailableCapacityForImportantUsage {
                guard available >= estimatedSize else {
                    throw FileError.diskSpaceInsufficient(
                        required: estimatedSize,
                        available: available
                    )
                }
            }
        } catch {
            // If we can't check space, just proceed (will fail on write if needed)
        }
    }

    // Check if filename is valid
    // Think of it like checking if label has no bad characters
    private func validateFilename(_ filename: String) throws {
        // Check for invalid characters (/: \?%*|"<> are not allowed)
        let invalidChars = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        if filename.rangeOfCharacter(from: invalidChars) != nil {
            throw FileError.invalidFilename(filename)
        }

        // Check length (macOS limits to 255 characters)
        if filename.count > 255 {
            throw FileError.invalidFilename(filename)
        }
    }

    // Handle filename collision (file already exists)
    // Think of it like adding "Jr." to name if dad already has same name
    private func handleCollision(_ fileURL: URL) throws -> URL {
        let manager = FileManager.default

        if manager.fileExists(atPath: fileURL.path) {
            // Add counter to filename (like "_1", "_2", etc.)
            let baseName = fileURL.deletingPathExtension().lastPathComponent
            let pathExtension = fileURL.pathExtension

            for i in 1...1000 {
                let newName = "\(baseName)_\(i)"
                let newURL = fileURL.deletingLastPathComponent()
                    .appendingPathComponent(newName)
                    .appendingPathExtension(pathExtension)

                if !manager.fileExists(atPath: newURL.path) {
                    return newURL
                }
            }

            // Could not find unique filename after 1000 tries
            throw FileError.invalidFilename("Could not find unique filename")
        }

        return fileURL
    }

    // Write image data to file
    // Think of it like putting photo in envelope and sealing it
    private func writeImage(_ image: NSImage, to url: URL) async throws {
        // Convert NSImage to TIFF data first
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw FileError.writeFailed(NSError(domain: "FileManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to convert image to bitmap"
            ]))
        }

        // Convert to desired format (PNG or JPEG)
        let imageData: Data

        switch defaultFormat {
        case .png:
            imageData = bitmap.representation(using: .png, properties: [:]) ?? Data()
        case .jpeg:
            let properties: [NSBitmapImageRep.PropertyKey: Any] = [
                .compressionFactor: 0.9
            ]
            imageData = bitmap.representation(using: .jpeg, properties: properties) ?? Data()
        }

        // Write data to file
        try imageData.write(to: url)
    }
}

// Capture mode is defined in CaptureMode.swift
// This file uses the existing enum from Core/CaptureEngine/
