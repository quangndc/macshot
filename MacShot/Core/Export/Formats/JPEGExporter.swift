// JPEGExporter.swift - JPEG format export with quality control
// Part of Phase 06 - Export System

import AppKit

/// JPEG export errors
enum JPEGExportError: Error {
    case tiffConversionFailed
    case bitmapCreationFailed
    case jpegEncodingFailed

    var localizedDescription: String {
        switch self {
        case .tiffConversionFailed: return "Failed to convert image to TIFF"
        case .bitmapCreationFailed: return "Failed to create bitmap representation"
        case .jpegEncodingFailed: return "Failed to encode JPEG data"
        }
    }
}

/// Export image to JPEG format
/// - Parameters:
///   - image: The source image
///   - quality: Compression quality (0.0 - 1.0)
///   - url: Destination file path
/// - Throws: JPEGExportError if encoding fails
func exportJPEG(image: NSImage, quality: Double, to url: URL) throws {
    // Clamp quality to valid range
    let clampedQuality = max(0.1, min(1.0, quality))

    // Convert to TIFF representation
    guard let tiffData = image.tiffRepresentation else {
        throw JPEGExportError.tiffConversionFailed
    }

    // Create bitmap from TIFF
    guard let bitmap = NSBitmapImageRep(data: tiffData) else {
        throw JPEGExportError.bitmapCreationFailed
    }

    // Encode as JPEG with quality
    guard let jpegData = bitmap.representation(
        using: .jpeg,
        properties: [.compressionFactor: clampedQuality]
    ) else {
        throw JPEGExportError.jpegEncodingFailed
    }

    // Write to file
    try jpegData.write(to: url)
}

/// Export image to JPEG data
/// - Parameters:
///   - image: The source image
///   - quality: Compression quality (0.0 - 1.0)
/// - Returns: JPEG data
/// - Throws: JPEGExportError if encoding fails
func exportJPEGData(image: NSImage, quality: Double) throws -> Data {
    let clampedQuality = max(0.1, min(1.0, quality))

    guard let tiffData = image.tiffRepresentation else {
        throw JPEGExportError.tiffConversionFailed
    }

    guard let bitmap = NSBitmapImageRep(data: tiffData) else {
        throw JPEGExportError.bitmapCreationFailed
    }

    guard let jpegData = bitmap.representation(
        using: .jpeg,
        properties: [.compressionFactor: clampedQuality]
    ) else {
        throw JPEGExportError.jpegEncodingFailed
    }

    return jpegData
}
