// JPEGExporter.swift - JPEG format export with quality control
// Part of Phase 06 - Export System

import AppKit

/// JPEG export errors
enum JPEGExportError: Error, LocalizedError {
    case tiffConversionFailed(size: CGSize, reason: String)
    case bitmapCreationFailed(size: CGSize, tiffSize: Int)
    case jpegEncodingFailed(size: CGSize, quality: Double)
    case invalidImage(size: CGSize)

    var localizedDescription: String {
        switch self {
        case .tiffConversionFailed(let size, let reason):
            return "TIFF conversion failed for \(Int(size.width)) x \(Int(size.height)) image: \(reason)"
        case .bitmapCreationFailed(let size, let tiffSize):
            return "Bitmap creation failed: image=\(Int(size.width))x\(Int(size.height)), tiff=\(tiffSize) bytes"
        case .jpegEncodingFailed(let size, let quality):
            return "JPEG encoding failed: \(Int(size.width))x\(Int(size.height)) at quality \(Int(quality * 100))%"
        case .invalidImage(let size):
            return "Invalid image for export: \(Int(size.width)) x \(Int(size.height))"
        }
    }

    var errorDescription: String? {
        localizedDescription
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidImage: return "Try capturing the screenshot again."
        case .jpegEncodingFailed: return "Try using a different export format or quality setting."
        case .tiffConversionFailed, .bitmapCreationFailed: return "The image may be corrupted. Try recapturing."
        }
    }
}

/// Export image to JPEG format with file handle cleanup
/// - Parameters:
///   - image: The source image
///   - quality: Compression quality (0.0 - 1.0)
///   - url: Destination file path
/// - Throws: JPEGExportError if encoding fails
func exportJPEG(image: NSImage, quality: Double, to url: URL) throws {
    // Validate image before conversion
    guard image.isValidForExport() else {
        throw JPEGExportError.invalidImage(size: image.size)
    }

    // Clamp quality to valid range
    let clampedQuality = max(0.1, min(1.0, quality))

    var success = false
    var fileHandle: FileHandle?

    defer {
        // Ensure cleanup
        if !success {
            // Remove partial file on failure
            try? FileManager.default.removeItem(atPath: url.path)
        }

        // Close handle
        try? fileHandle?.close()
        fileHandle = nil
    }

    // Convert to TIFF representation
    guard let tiffData = image.tiffRepresentation else {
        throw JPEGExportError.tiffConversionFailed(
            size: image.size,
            reason: "Unable to create TIFF representation"
        )
    }

    // Create bitmap from TIFF
    guard let bitmap = NSBitmapImageRep(data: tiffData) else {
        throw JPEGExportError.bitmapCreationFailed(
            size: image.size,
            tiffSize: tiffData.count
        )
    }

    // Encode as JPEG with quality
    guard let jpegData = bitmap.representation(
        using: .jpeg,
        properties: [.compressionFactor: clampedQuality]
    ) else {
        throw JPEGExportError.jpegEncodingFailed(
            size: image.size,
            quality: clampedQuality
        )
    }

    // Write to file
    try jpegData.write(to: url)

    success = true
}

/// Export image to JPEG data
/// - Parameters:
///   - image: The source image
///   - quality: Compression quality (0.0 - 1.0)
/// - Returns: JPEG data
/// - Throws: JPEGExportError if encoding fails
func exportJPEGData(image: NSImage, quality: Double) throws -> Data {
    // Validate image before conversion
    guard image.isValidForExport() else {
        throw JPEGExportError.invalidImage(size: image.size)
    }

    let clampedQuality = max(0.1, min(1.0, quality))

    guard let tiffData = image.tiffRepresentation else {
        throw JPEGExportError.tiffConversionFailed(
            size: image.size,
            reason: "Unable to create TIFF representation"
        )
    }

    guard let bitmap = NSBitmapImageRep(data: tiffData) else {
        throw JPEGExportError.bitmapCreationFailed(
            size: image.size,
            tiffSize: tiffData.count
        )
    }

    guard let jpegData = bitmap.representation(
        using: .jpeg,
        properties: [.compressionFactor: clampedQuality]
    ) else {
        throw JPEGExportError.jpegEncodingFailed(
            size: image.size,
            quality: clampedQuality
        )
    }

    return jpegData
}
