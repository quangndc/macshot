// PNGExporter.swift - PNG format export
// Part of Phase 06 - Export System

import AppKit

/// PNG export errors
enum PNGExportError: Error {
    case tiffConversionFailed
    case bitmapCreationFailed
    case pngEncodingFailed

    var localizedDescription: String {
        switch self {
        case .tiffConversionFailed: return "Failed to convert image to TIFF"
        case .bitmapCreationFailed: return "Failed to create bitmap representation"
        case .pngEncodingFailed: return "Failed to encode PNG data"
        }
    }
}

/// Export image to PNG format
/// - Parameters:
///   - image: The source image
///   - url: Destination file path
/// - Throws: PNGExportError if encoding fails
func exportPNG(image: NSImage, to url: URL) throws {
    // Convert to TIFF representation
    guard let tiffData = image.tiffRepresentation else {
        throw PNGExportError.tiffConversionFailed
    }

    // Create bitmap from TIFF
    guard let bitmap = NSBitmapImageRep(data: tiffData) else {
        throw PNGExportError.bitmapCreationFailed
    }

    // Encode as PNG
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw PNGExportError.pngEncodingFailed
    }

    // Write to file
    try pngData.write(to: url)
}

/// Export image to PNG data
/// - Parameter image: The source image
/// - Returns: PNG data
/// - Throws: PNGExportError if encoding fails
func exportPNGData(image: NSImage) throws -> Data {
    guard let tiffData = image.tiffRepresentation else {
        throw PNGExportError.tiffConversionFailed
    }

    guard let bitmap = NSBitmapImageRep(data: tiffData) else {
        throw PNGExportError.bitmapCreationFailed
    }

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw PNGExportError.pngEncodingFailed
    }

    return pngData
}
