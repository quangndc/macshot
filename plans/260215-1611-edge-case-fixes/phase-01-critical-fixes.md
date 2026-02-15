# Phase 01: Critical Infrastructure Fixes

**Priority:** CRITICAL
**Status:** Pending
**Estimated Complexity:** Medium

---

## Overview

Fix critical infrastructure issues that affect the entire application stability. These are foundational problems that must be resolved before addressing feature-specific edge cases.

---

## Issues to Fix

### 1. Duplicate File Cleanup

**Problem:** Two `HotkeyManager.swift` files exist with different implementations
**Location:** `MacShot/System/HotkeyManager.swift.swift`

**Impact:**
- Build confusion
- Potential for wrong file being used
- Code maintenance issues

**Solution:**
```swift
// DELETE: MacShot/System/HotkeyManager.swift.swift
// KEEP: MacShot/System/HotkeyManager.swift (CGEventTap implementation)
```

**Files:**
- DELETE: `MacShot/System/HotkeyManager.swift.swift`

**Testing:**
- Build verification
- Hotkey registration test
- Event tap functionality test

---

### 2. FileManager Stub Implementation

**Problem:** `FileManager.swift` is a stub with TODO comments
**Location:** `MacShot/Core/FileManager.swift`

**Impact:**
- File save operations not functional
- No filename generation
- No file cleanup

**Solution:**
```swift
import AppKit
import Foundation

@MainActor
final class ScreenshotFileManager: Sendable {
    // MARK: - Configuration
    var saveDirectory: URL
    var defaultFormat: ImageFormat = .png
    var includeTimestamp = true

    // MARK: - Errors
    enum FileError: Error, LocalizedError {
        case directoryNotAccessible(URL)
        case diskSpaceInsufficient(required: Int64, available: Int64)
        case writeFailed(Error)
        case invalidFilename(String)

        var errorDescription: String? {
            switch self {
            case .directoryNotAccessible(let url):
                "Cannot access directory: \(url.path)"
            case .diskSpaceInsufficient(let required, let available):
                "Need \(required) bytes, only \(available) available"
            case .writeFailed(let error):
                "Failed to write file: \(error.localizedDescription)"
            case .invalidFilename(let name):
                "Invalid filename: \(name)"
            }
        }
    }

    // MARK: - Initialization
    init(saveDirectory: URL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!) {
        self.saveDirectory = saveDirectory
    }

    // MARK: - Operations
    func saveScreenshot(_ image: NSImage, name: String? = nil) async throws -> URL {
        // 1. Validate directory accessibility
        try validateDirectory()

        // 2. Check disk space
        try validateDiskSpace(for: image)

        // 3. Generate filename
        let filename = name ?? generateFilename()

        // 4. Validate filename
        try validateFilename(filename)

        // 5. Create file URL
        let fileURL = saveDirectory.appendingPathComponent(filename)
            .appendingPathExtension(defaultFormat.fileExtension)

        // 6. Handle filename collision
        let finalURL = try handleCollision(fileURL)

        // 7. Write file
        try await writeImage(image, to: finalURL)

        return finalURL
    }

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

    func cleanupOldFiles(maxAge: TimeInterval) async throws {
        let manager = FileManager.default
        let contents = try manager.contentsOfDirectory(at: saveDirectory, includingPropertiesForKeys: [.creationDateKey])

        let now = Date()
        for url in contents {
            if let creationDate = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate {
                if now.timeIntervalSince(creationDate) > maxAge {
                    try manager.removeItem(at: url)
                }
            }
        }
    }

    // MARK: - Private Helpers
    private func validateDirectory() throws {
        let manager = FileManager.default

        // Check if directory exists
        var isDirectory: ObjCBool = false
        if !manager.fileExists(atPath: saveDirectory.path, isDirectory: &isDirectory) {
            // Try to create directory
            try manager.createDirectory(at: saveDirectory, withIntermediateDirectories: true)
        }

        // Check if accessible
        if !manager.isWritableFile(atPath: saveDirectory.path) {
            throw FileError.directoryNotAccessible(saveDirectory)
        }
    }

    private func validateDiskSpace(for image: NSImage) throws {
        // Estimate image size (width * height * 4 bytes for RGBA)
        let estimatedSize = Int64(image.size.width * image.size.height * 4)

        let manager = FileManager.default
        let values = try manager.valuesOfItem(atPath: saveDirectory.path).resourceValues

        if let available = values.volumeAvailableCapacityForImportantUsage {
            guard available >= estimatedSize else {
                throw FileError.diskSpaceInsufficient(required: estimatedSize, available: available)
            }
        }
    }

    private func validateFilename(_ filename: String) throws {
        // Check for invalid characters
        let invalidChars = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        if filename.rangeOfCharacter(from: invalidChars) != nil {
            throw FileError.invalidFilename(filename)
        }

        // Check length
        if filename.count > 255 {
            throw FileError.invalidFilename(filename)
        }
    }

    private func handleCollision(_ fileURL: URL) throws -> URL {
        let manager = FileManager.default

        if manager.fileExists(atPath: fileURL.path) {
            // Add counter to filename
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

            throw FileError.invalidFilename("Could not find unique filename")
        }

        return fileURL
    }

    private func writeImage(_ image: NSImage, to url: URL) async throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw FileError.writeFailed(NSError(domain: "FileManager", code: -1))
        }

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

        try imageData.write(to: url)
    }
}

// MARK: - Supporting Types
enum ImageFormat {
    case png
    case jpeg

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/FileManager.swift`

**Testing:**
- Save to various directory states (exists, not exists, read-only)
- Disk space exhaustion scenarios
- Filename collision handling
- Invalid filename sanitization

---

### 3. Silent Failure Fixes

**Problem:** `try?` in hotkey callback hides capture failures from users
**Location:** `MacShot/System/HotkeyManager.swift`

**Impact:**
- User presses hotkey but nothing happens
- No feedback on failure
- Cannot diagnose issues

**Solution:**
```swift
// BEFORE (silent failure):
@MainActor
func handleHotkeyPress() {
    Task {
        try? engine.captureFullscreen()
    }
}

// AFTER (proper error handling):
@MainActor
func handleHotkeyPress() {
    Task {
        do {
            let result = try await engine.captureFullscreen()
            showSuccessNotification(result)
        } catch {
            showErrorNotification(error)
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/System/HotkeyManager.swift`
- MODIFY: `MacShot/System/NotificationManager.swift` (add error notification methods)

**Testing:**
- Permission denied scenarios
- Capture failure scenarios
- Notification display verification

---

## Success Criteria

- [ ] Duplicate file removed
- [ ] FileManager fully implemented with all edge cases handled
- [ ] No silent failures in hotkey handling
- [ ] Comprehensive error notifications implemented
- [ ] All tests passing

---

## Next Steps

After completing this phase:
1. Move to [Phase 02: Capture Engine Robustness](./phase-02-capture-fixes.md)
2. Update test coverage metrics
3. Verify no regressions in existing functionality

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| FileManager breaking existing save flow | Medium | Extensive testing before merge |
| Error notification spam | Low | Rate limiting for notifications |
| Disk space check performance | Low | Cache results, check periodically |

---

## Notes

- FileManager implementation should match existing ExportManager patterns
- Error messages should be user-friendly, not technical
- Consider adding user preferences for error notification behavior
