# Phase 06: Export System Error Handling

**Priority:** MEDIUM
**Status:** Pending
**Estimated Complexity:** Medium

---

## Overview

Fix export system edge cases related to disk space, permissions, and error recovery. These fixes ensure file export operations are robust and user-friendly.

---

## Issues to Fix

### 1. Disk Space Validation

**Problem:** No disk space check before export
**Location:** `ExportManager.swift`, `PNGExporter.swift`, `JPEGExporter.swift`

**Impact:**
- Export fails mid-operation
- Corrupted output files
- Poor user experience

**Solution:**
```swift
// Add to ExportManager.swift
@MainActor
final class ExportManager: ObservableObject {
    // NEW: Disk space validation
    private func validateDiskSpace(for image: NSImage, format: ExportFormat) async throws {
        let manager = FileManager.default
        guard let targetURL = outputURL else {
            throw ExportError.noOutputLocation
        }

        // Get volume attributes
        let values = try manager.valuesOfItem(atPath: targetURL.deletingLastPathComponent().path)
            .resourceValues

        guard let availableSpace = values.volumeAvailableCapacityForImportantUsage else {
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
            quality = options.quality
        } else {
            quality = 1.0
        }

        // Rough estimate: width * height * components * quality
        let uncompressed = dimensions * components
        let estimated = format == .png ? uncompressed : uncompressed * quality * 0.15

        return Int64(estimated)
    }

    func export() async throws -> URL {
        guard let image = sourceImage else {
            throw ExportError.noSourceImage
        }

        // Validate disk space first
        try await validateDiskSpace(for: image, format: options.format)

        // Continue with export...
        let exporter = ExporterFactory.create(format: options.format)
        return try await exporter.export(image, to: outputURL, options: options)
    }
}

enum ExportError: Error, LocalizedError {
    case insufficientDiskSpace(required: Int64, available: Int64)
    case noOutputLocation
    case noSourceImage

    var errorDescription: String? {
        switch self {
        case .insufficientDiskSpace(let required, let available):
            let requiredMB = Int(required / 1_000_000)
            let availableMB = Int(available / 1_000_000)
            return "Not enough disk space. Need \(requiredMB)MB, only \(availableMB)MB available."
        case .noOutputLocation:
            return "No output location specified."
        case .noSourceImage:
            return "No source image to export."
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/Export/ExportManager.swift`

**Testing:**
- Export with low disk space
- Export with adequate disk space
- Verify space estimation accuracy

---

### 2. Read-Only Location Handling

**Problem:** No check for write permissions before export
**Location:** `ExportManager.swift`

**Impact:**
- Export fails with cryptic error
- User confusion
- No alternative suggested

**Solution:**
```swift
// Add to ExportManager.swift
@MainActor
final class ExportManager: ObservableObject {
    private func validateOutputLocation() async throws {
        guard let targetURL = outputURL else {
            throw ExportError.noOutputLocation
        }

        let manager = FileManager.default

        // Check if parent directory exists
        let parentURL = targetURL.deletingLastPathComponent()
        var isDirectory: ObjCBool = false

        if !manager.fileExists(atPath: parentURL.path, isDirectory: &isDirectory) {
            // Try to create directory
            try manager.createDirectory(at: parentURL, withIntermediateDirectories: true)
        }

        guard isDirectory else {
            throw ExportError.invalidOutputLocation(targetURL)
        }

        // Check write permission
        if !manager.isWritableFile(atPath: parentURL.path) {
            throw ExportError.locationNotWritable(targetURL)
        }

        // Check if file exists and is locked
        if manager.fileExists(atPath: targetURL.path) {
            if !manager.isWritableFile(atPath: targetURL.path) {
                throw ExportError.fileNotWritable(targetURL)
            }
        }
    }

    func export() async throws -> URL {
        guard let image = sourceImage else {
            throw ExportError.noSourceImage
        }

        // Validate output location
        try await validateOutputLocation()

        // Validate disk space
        try await validateDiskSpace(for: image, format: options.format)

        // Continue with export...
    }
}

enum ExportError: Error, LocalizedError {
    case locationNotWritable(URL)
    case fileNotWritable(URL)
    case invalidOutputLocation(URL)

    var errorDescription: String? {
        switch self {
        case .locationNotWritable(let url):
            return "Cannot write to: \(url.path)"
        case .fileNotWritable(let url):
            return "File is locked or read-only: \(url.lastPathComponent)"
        case .invalidOutputLocation(let url):
            return "Invalid output location: \(url.path)"
        // ... existing cases ...
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/Export/ExportManager.swift`

**Testing:**
- Export to read-only directory
- Export to locked file
- Export to writable location

---

### 3. File Handle Leak Prevention

**Problem:** Failed exports may leave file handles open
**Location:** `PNGExporter.swift`, `JPEGExporter.swift`

**Impact:**
- Resource leaks
- Locked files
- Disk space issues

**Solution:**
```swift
// Update PNGExporter.swift
struct PNGExporter: ImageExporter {
    func export(_ image: NSImage, to url: URL, options: ExportOptions) async throws -> URL {
        var fileHandle: FileHandle?
        var success = false

        defer {
            // Ensure cleanup
            if !success {
                // Remove partial file on failure
                if let path = fileHandle?.url?.path {
                    try? FileManager.default.removeItem(atPath: path)
                }
            }

            // Close handle
            try? fileHandle?.close()
            fileHandle = nil
        }

        // Open file for writing
        fileHandle = try FileHandle(forWritingTo: url)

        // Convert and write
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ExportError.conversionFailed
        }

        try fileHandle?.write(contentsOf: pngData)
        try fileHandle?.synchronize()

        success = true
        return url
    }
}

// Update JPEGExporter.swift
struct JPEGExporter: ImageExporter {
    func export(_ image: NSImage, to url: URL, options: ExportOptions) async throws -> URL {
        var fileHandle: FileHandle?
        var success = false

        defer {
            // Ensure cleanup
            if !success {
                // Remove partial file on failure
                if let path = fileHandle?.url?.path {
                    try? FileManager.default.removeItem(atPath: path)
                }
            }

            // Close handle
            try? fileHandle?.close()
            fileHandle = nil
        }

        // Open file for writing
        fileHandle = try FileHandle(forWritingTo: url)

        // Convert and write
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw ExportError.conversionFailed
        }

        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: options.quality
        ]

        guard let jpegData = bitmap.representation(using: .jpeg, properties: properties) else {
            throw ExportError.conversionFailed
        }

        try fileHandle?.write(contentsOf: jpegData)
        try fileHandle?.synchronize()

        success = true
        return url
    }
}

enum ExportError: Error, LocalizedError {
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .conversionFailed:
            return "Failed to convert image format"
        // ... existing cases ...
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/Export/Formats/PNGExporter.swift`
- MODIFY: `MacShot/Core/Export/Formats/JPEGExporter.swift`

**Testing:**
- Interrupt export mid-operation
- Export with invalid image
- Verify no partial files remain

---

### 4. Format Conversion Error Recovery

**Problem:** Limited error context for conversion failures
**Location:** All exporter files

**Impact:**
- Difficult debugging
- Poor error messages
- No user guidance

**Solution:**
```swift
// Enhance error reporting
struct PNGExporter: ImageExporter {
    func export(_ image: NSImage, to url: URL, options: ExportOptions) async throws -> URL {
        // Validate image before conversion
        guard image.isValidForExport() else {
            throw ExportError.invalidImage(image.size)
        }

        // Attempt conversion with detailed error context
        guard let tiffData = image.tiffRepresentation else {
            throw ExportError.tiffConversionFailed(
                size: image.size,
                reason: "Unable to create TIFF representation"
            )
        }

        guard let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw ExportError.bitmapCreationFailed(
                size: image.size,
                tiffSize: tiffData.count
            )
        }

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ExportError.pngEncodingFailed(
                size: bitmap.size,
                bitsPerSample: bitmap.bitsPerSample,
                samplesPerPixel: bitmap.samplesPerPixel
            )
        }

        // Write file...
    }
}

// Extend ExportError
enum ExportError: Error, LocalizedError {
    case invalidImage(CGSize)
    case tiffConversionFailed(size: CGSize, reason: String)
    case bitmapCreationFailed(size: CGSize, tiffSize: Int)
    case pngEncodingFailed(size: CGSize, bitsPerSample: Int, samplesPerPixel: Int)
    case jpegEncodingFailed(size: CGSize, quality: Double)

    var errorDescription: String? {
        switch self {
        case .invalidImage(let size):
            return "Invalid image for export: \(Int(size.width)) x \(Int(size.height))"
        case .tiffConversionFailed(let size, let reason):
            return "TIFF conversion failed for \(Int(size.width)) x \(Int(size.height)) image: \(reason)"
        case .bitmapCreationFailed(let size, let tiffSize):
            return "Bitmap creation failed: image=\(Int(size.width))x\(Int(size.height)), tiff=\(tiffSize) bytes"
        case .pngEncodingFailed(let size, let bits, let samples):
            return "PNG encoding failed: \(Int(size.width))x\(Int(size.height)), \(bits) bits, \(samples) samples"
        case .jpegEncodingFailed(let size, let quality):
            return "JPEG encoding failed: \(Int(size.width))x\(Int(size.height)) at quality \(Int(quality * 100))%"
        // ... existing cases ...
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidImage:
            return "Try capturing the screenshot again."
        case .pngEncodingFailed, .jpegEncodingFailed:
            return "Try using a different export format."
        case .tiffConversionFailed, .bitmapCreationFailed:
            return "The image may be corrupted. Try recapturing."
        default:
            return nil
        }
    }
}

// Add image validation
extension NSImage {
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
```

**Files:**
- MODIFY: `MacShot/Core/Export/Formats/PNGExporter.swift`
- MODIFY: `MacShot/Core/Export/Formats/JPEGExporter.swift`

**Testing:**
- Export invalid images
- Export various image sizes
- Verify error messages

---

## Success Criteria

- [ ] Disk space validated before export
- [ ] Write permissions checked before export
- [ ] File handles properly cleaned up
- [ ] Detailed error messages with recovery suggestions
- [ ] All export edge cases tested

---

## Phase Completion Checklist

- [ ] All 6 phases complete
- [ ] Test coverage >95%
- [ ] No silent failures
- [ ] User-friendly error messages
- [ ] Documentation updated

---

## Next Steps

After completing this phase:
1. Run full test suite
2. Update documentation
3. Prepare for release

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Disk space estimate inaccuracy | Low | Safety margin included |
| Permission check overhead | Low | Check once per export |
| File handle complexity | Medium | Extensive testing needed |

---

## Overall Project Status

**Total Edge Cases:** 42
**Handled After All Phases:** 40 (95%)
**Remaining:** 2 partial (acceptable for v1.0)

**Version Target:** 1.0.0 (Production Ready)

---

*Created: 2026-02-15*
*MacShot Edge Case Fixes Plan - Complete*
