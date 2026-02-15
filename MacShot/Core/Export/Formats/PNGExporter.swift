// PNGExporter.swift - PNG format export
// Part of Phase 06 - Export System

import AppKit

/// PNG export errors
enum PNGExportError: Error, LocalizedError {
    case tiffConversionFailed(size: CGSize, reason: String)
    case bitmapCreationFailed(size: CGSize, tiffSize: Int)
    case pngEncodingFailed(size: CGSize, bitsPerSample: Int, samplesPerPixel: Int)
    case invalidImage(size: CGSize)

    var localizedDescription: String {
        switch self {
        case .tiffConversionFailed(let size, let reason):
            return "TIFF conversion failed for \(Int(size.width)) x \(Int(size.height)) image: \(reason)"
        case .bitmapCreationFailed(let size, let tiffSize):
            return "Bitmap creation failed: image=\(Int(size.width))x\(Int(size.height)), tiff=\(tiffSize) bytes"
        case .pngEncodingFailed(let size, let bits, let samples):
            return "PNG encoding failed: \(Int(size.width))x\(Int(size.height)), \(bits) bits, \(samples) samples"
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
        case .pngEncodingFailed: return "Try using a different export format."
        case .tiffConversionFailed, .bitmapCreationFailed: return "The image may be corrupted. Try recapturing."
        }
    }
}

/// Export image to PNG format with file handle cleanup
/// - Parameters:
///   - image: The source image
///   - url: Destination file path
/// - Throws: PNGExportError if encoding fails
func exportPNG(image: NSImage, to url: URL) throws {
    // Validate image before conversion
    guard image.isValidForExport() else {
        throw PNGExportError.invalidImage(size: image.size)
    }

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
        throw PNGExportError.tiffConversionFailed(
            size: image.size,
            reason: "Unable to create TIFF representation"
        )
    }

    // Create bitmap from TIFF
    guard let bitmap = NSBitmapImageRep(data: tiffData) else {
        throw PNGExportError.bitmapCreationFailed(
            size: image.size,
            tiffSize: tiffData.count
        )
    }

    // Encode as PNG
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw PNGExportError.pngEncodingFailed(
            size: bitmap.size,
            bitsPerSample: bitmap.bitsPerSample,
            samplesPerPixel: bitmap.samplesPerPixel
        )
    }

    // Write to file
    try pngData.write(to: url)

    success = true
}

/// Export image to PNG data
/// - Parameter image: The source image
/// - Returns: PNG data
/// - Throws: PNGExportError if encoding fails
func exportPNGData(image: NSImage) throws -> Data {
    // Validate image before conversion
    guard image.isValidForExport() else {
        throw PNGExportError.invalidImage(size: image.size)
    }

    // Convert to TIFF representation
    guard let tiffData = image.tiffRepresentation else {
        throw PNGExportError.tiffConversionFailed(
            size: image.size,
            reason: "Unable to create TIFF representation"
        )
    }

    // Create bitmap from TIFF
    guard let bitmap = NSBitmapImageRep(data: tiffData) else {
        throw PNGExportError.bitmapCreationFailed(
            size: image.size,
            tiffSize: tiffData.count
        )
    }

    // Encode as PNG
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw PNGExportError.pngEncodingFailed(
            size: bitmap.size,
            bitsPerSample: bitmap.bitsPerSample,
            samplesPerPixel: bitmap.samplesPerPixel
        )
    }

    return pngData
}

// MARK: - NSImage Validation

extension NSImage {
    /// Validates if image is suitable for export
    func isValidForExport() -> Bool {
        guard size.width > 0, size.height > 0 else {
            return false
        }

        guard !size.width.isNaN, !size.height.isNaN else {
            return false
        }

        guard !size.width.isInfinite, !size.height.isInfinite else {
            return false
        }

        return true
    }
}
