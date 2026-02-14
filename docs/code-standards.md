# MacShot Code Standards & Guidelines

## Overview

This document establishes coding standards and guidelines for the MacShot project. All developers must adhere to these standards to ensure code quality, maintainability, and consistency across the codebase.

## Swift Coding Standards

### Language Version and Compatibility

- **Swift Version**: Swift 6.0
- **Minimum macOS**: 15.0
- **Xcode Version**: 15.0+
- **Platform**: macOS only

### File Structure and Organization

```
MacShot/
├── Core/                    # Core functionality
├── Features/                # Feature modules
├── UI/                      # SwiftUI interfaces
├── System/                  # System integration
└── Resources/               # Assets and resources
```

#### File Naming Conventions

- **Swift Files**: PascalCase for types, camelCase for functions/variables
  - `CaptureEngineCoordinator.swift`
  - `RegionSelectionOverlay.swift`
  - `HotkeyManager.swift`
- **Resource Files**: lowercase with descriptive names
  - `info.plist` → `Info.plist` (Apple convention)
  - `icon@2x.png`, `icon@3x.png`

### Naming Conventions

#### Types (Classes, Structs, Enums, Protocols)
```swift
// Use descriptive, clear names
class CaptureEngine { }
struct CaptureMetadata { }
enum CaptureMode { }
protocol HotkeyManager { }
```

#### Functions and Methods
```swift
// Use verb-based naming for actions
func captureFullscreen() async throws -> CaptureResult
func saveScreenshot(to url: URL) async throws
func registerGlobalHotkey(_ hotkey: Hotkey) throws
```

#### Variables and Properties
```swift
// Use camelCase, be descriptive
@Published var capturedImage: NSImage?
private var hotkeyRegistry: [Hotkey: CGEventRef] = [:]
let saveDirectory: URL
```

#### Constants
```swift
// Use UPPER_SNAKE_CASE for constants
let DEFAULT_SAVE_DIRECTORY = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
let MAX_FILE_SIZE: UInt64 = 50 * 1024 * 1024 // 50MB
```

### Code Structure

#### Imports Organization
```swift
// Standard library imports first
import Foundation
import AppKit
import CoreGraphics

// Third-party imports second (none in this project)
// import SomeLibrary

// Project-specific imports last
import MacShotCore
```

#### Type Definitions
```swift
// Place types in logical order
// 1. Protocol definitions
// 2. Enum definitions
// 3. Struct definitions
// 4. Class definitions
// 5. Extension definitions

protocol CaptureDelegate: AnyObject {
    func didCapture(_ result: CaptureResult)
}

enum CaptureError: Error {
    case displayNotFound
    case permissionDenied
    case invalidRegion
}
```

### Coding Style

#### Braces and Indentation
```swift
// Use braces for all control statements
if condition {
    // Do something
} else {
    // Do something else
}

// Braces on new line for types
class CaptureEngine {
    // Implementation
}

struct CaptureResult {
    // Properties
}
```

#### Spacing
```swift
// Single space around operators
let width = screenBounds.width
let scaleFactor = display.scaleFactor

// No space after opening paren, before closing paren
func capture(rect: CGRect) { }
```

#### Line Length
- Maximum: 120 characters per line
- Break long lines at logical points
- Use proper indentation for continuation

### Swift Concurrency

#### Async/Await Usage
```swift
// Use async/await for all asynchronous operations
@MainActor
func capture(mode: CaptureMode) async throws -> CaptureResult {
    isCapturing = true
    defer { isCapturing = false }

    // Capture logic here
    return result
}
```

#### Actors and MainActor
```swift
// Use @MainActor for UI updates
@MainActor
class CaptureEngine: ObservableObject {
    @Published var capturedImage: NSImage?

    // Non-isolated methods need MainActor annotation
    func updateUI() {
        // UI updates here
    }
}
```

#### Sendable Protocol
```swift
// Use Sendable for data crossing actor boundaries
struct CaptureMetadata: Sendable {
    let timestamp: Date
    let displayID: CGDirectDisplayID
    let bounds: CGRect
}
```

### Error Handling

#### Error Types
```swift
// Define custom error types
enum CaptureError: Error, LocalizedError {
    case displayNotFound
    case permissionDenied
    case invalidRegion

    var errorDescription: String? {
        switch self {
        case .displayNotFound:
            return "Display not found"
        case .permissionDenied:
            return "Screen recording permission denied"
        case .invalidRegion:
            return "Invalid capture region"
        }
    }
}
```

#### Error Handling Patterns
```swift
// Use throws for functions that can fail
func captureFullscreen() async throws -> CaptureResult {
    do {
        let result = try await capture(mode: .fullscreen)
        return result
    } catch {
        // Log error
        logError("Failed to capture fullscreen: \(error)")
        throw error
    }
}

// Handle errors in UI
do {
    let result = try await captureEngine.captureFullscreen()
    capturedImage = result.image
} let error = {
    errorMessage = error.localizedDescription
}
```

### Documentation Standards

#### File Headers
```swift
// MacShot - Screenshot capture tool for macOS
//
// Module: Core/CaptureEngine
// Purpose: Main capture engine coordinator
// Author: Developer Name
// Date: 2026-02-14
```

#### Type Documentation
```swift
/// Main capture engine that coordinates all capture operations
///
/// This class handles the coordination between different capture modes
/// and manages the overall capture workflow.
@MainActor
final class CaptureEngine: ObservableObject {
    // Implementation
}
```

#### Function Documentation
```swift
/// Capture screenshot using the specified mode
///
/// - Parameter mode: The capture mode to use (fullscreen, region, or window)
/// - Returns: CaptureResult containing the captured image and metadata
/// - Throws: CaptureError if capture fails
///
/// The function publishes updates to `capturedImage` and `isCapturing` properties
/// to keep the UI informed of the capture state.
func capture(mode: CaptureMode) async throws -> CaptureResult {
    // Implementation
}
```

#### Property Documentation
```swift
/// Latest captured image, published for UI updates
@Published var capturedImage: NSImage?

/// Whether a capture operation is currently in progress
@Published var isCapturing = false
```

### Testing Standards

#### Test Naming
```swift
// Use descriptive test names
class CaptureEngineTests: XCTestCase {
    func testCaptureFullscreenSuccess() throws { }
    func testCaptureRegionInvalidBounds() throws { }
    func testCaptureWindowNotFound() throws { }
}
```

#### Test Structure
```swift
class CaptureEngineTests: XCTestCase {
    var captureEngine: CaptureEngine!

    override func setUp() {
        super.setUp()
        captureEngine = CaptureEngine()
    }

    override func tearDown() {
        captureEngine = nil
        super.tearDown()
    }
}
```

#### Assertion Patterns
```swift
// Use XCTAssert for basic assertions
XCTAssertNotNil(result.image)
XCTAssertEqual(result.mode, .fullscreen)
XCTAssertThrowsError(try captureEngine.capture(mode: .invalid)) { error in
    XCTAssertEqual(error as? CaptureError, .invalidRegion)
}
```

### Memory Management

#### Reference Cycles
```swift
// Use weak for delegates and parent-child relationships
class CaptureViewController: NSViewController {
    weak var delegate: CaptureDelegate?

    // Use unowned for references that can't be nil
    let captureEngine = CaptureEngine()
}
```

#### Leaks Prevention
```swift
// Avoid strong references to closures
func setupCapture() {
    captureEngine.onCaptureComplete = { [weak self] result in
        self?.handleCaptureResult(result)
    }
}
```

### UI Development Guidelines

#### SwiftUI Components
```swift
// Use proper View naming
struct CaptureMenuView: View {
    @StateObject private var captureEngine = CaptureEngine()

    var body: some View {
        VStack {
            // UI components
        }
    }
}
```

#### State Management
```swift
// Use @State for local state
@State private var isCapturing = false
@State private var capturedImage: NSImage?

// Use @StateObject for view models
@StateObject private var captureEngine = CaptureEngine()

// Use @ObservedObject for external objects
@ObservedObject var hotkeyManager: HotkeyManager
```

#### Modularity
```swift
// Keep views focused on UI logic
struct RegionSelectionOverlay: View {
    @Binding var selectedRegion: CGRect?

    var body: some View {
        OverlayViewContent()
            .onTapGesture { location in
                selectedRegion = CGRect(origin: location, size: .zero)
            }
    }
}
```

### Security Considerations

#### Input Validation
```swift
// Validate all inputs
func saveScreenshot(to url: URL) throws {
    guard url.isFileURL else {
        throw CaptureError.invalidURL
    }

    // Additional validation
}
```

#### Permission Handling
```
// Check permissions before using sensitive APIs
func checkScreenRecordingPermission() -> Bool {
    let screenRecordingStatus = CGPreflightScreenCaptureSafetyLevel()
    return screenRecordingStatus == .kCGAccessFullAccess
}
```

### Performance Optimization

#### Image Handling
```swift
// Use NSImage efficiently
let capturedImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
```

#### Memory Management
```swift
// Clear large objects when no longer needed
func clearCapture() {
    capturedImage = nil
    // Release other resources
}
```

### Code Review Checklist

#### Code Quality
- [ ] Follows naming conventions
- [ ] Proper error handling
- [ ] Clear and concise comments
- [ ] No code smells
- [ ] Appropriate use of Swift features

#### Performance
- [ ] No unnecessary allocations
- [ ] Proper memory management
- [ ] Efficient algorithms
- [ ] UI responsiveness maintained

#### Security
- [ ] Input validation
- [ ] Permission checking
- [ ] No hardcoded secrets
- [ ] Proper error messages (no sensitive info)

#### Testing
- [ ] Unit tests present
- [ ] Edge cases covered
- [ ] Integration tests
- [ ] UI tests for critical flows

### Build and Deployment

#### Build Configuration
- **Debug**: Full debugging enabled
- **Release**: Optimizations enabled, debugging stripped
- **Distribution**: Notarized, code signing enabled

#### Deployment Targets
- **macOS 15.0+**
- **Intel and Apple Silicon**

### References

- [The Swift Programming Language](https://docs.swift.org)
- [Apple Developer Documentation](https://developer.apple.com)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)

---
*Last Updated: 2026-02-14*
*Version: 1.0.0*