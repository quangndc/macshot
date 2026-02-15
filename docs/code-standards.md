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

### Settings Architecture Patterns

#### @Observable for Reactive UI
```swift
// Use @Observable for settings models to enable reactive UI
@Observable
final class AppSettings: Equatable {
    var captureFullscreenHotkey: Hotkey
    var defaultFormat: ExportFormat
    var launchAtLogin: Bool

    // Equatable conformance for SwiftUI onChange tracking
    static func == (lhs: AppSettings, rhs: AppSettings) -> Bool {
        lhs.captureFullscreenHotkey == rhs.captureFullscreenHotkey &&
        lhs.defaultFormat == rhs.defaultFormat
        // ... other properties
    }
}
```

#### Property Wrapper Pattern
```swift
// Use @propertyWrapper for custom UserDefaults behavior
@propertyWrapper
struct AppStorageDefault<T: Codable> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(T.self, from: data) else {
                return defaultValue
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
    }
}
```

#### Settings Store Pattern
```swift
@MainActor
final class SettingsStore {
    // Static properties with @AppStorageDefault for easy access
    @AppStorageDefault(key: "hotkeys.fullscreen", defaultValue: Hotkey(...))
    static var captureFullscreenHotkey: Hotkey

    // Helper methods for complex data types
    static func getOutputFolderURL() -> URL? {
        guard let path = defaultOutputFolder else { return nil }
        return URL(fileURLWithPath: path)
    }
}
```

#### Hotkey Recording Component
```swift
struct HotkeyRecorder: View {
    @Binding var hotkey: Hotkey
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text(title)
            TextField("", text: .constant(hotkey.description))
                .textFieldStyle(.roundedBorder)
                .disabled(true)
            Button(action: startRecording) {
                Image(systemName: isRecording ? "record.circle.fill" : "record.circle")
            }
            .foregroundColor(isRecording ? .red : .primary)
        }
    }
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
    case windowNotFound
    case fileSaveFailed(Error)
    case directoryCreationFailed
    case fileCollisionDetected
    case exportFailed(Error)

    var errorDescription: String? {
        switch self {
        case .displayNotFound:
            return "Display not found"
        case .permissionDenied:
            return "Screen recording permission denied"
        case .invalidRegion:
            return "Invalid capture region"
        case .windowNotFound:
            return "Window not found"
        case .fileSaveFailed(let error):
            return "Failed to save file: \(error.localizedDescription)"
        case .directoryCreationFailed:
            return "Failed to create save directory"
        case .fileCollisionDetected:
            return "File already exists"
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
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

#### Settings Documentation
```swift
/// Centralized user preferences model with reactive UI updates
///
/// This @Observable class manages all application settings including:
/// - Hotkeys for different capture modes
/// - Export configuration (format, quality, location)
/// - General app behavior (launch, notifications, UI visibility)
/// - Editor defaults (tools, colors, stroke width)
@Observable
final class AppSettings: Equatable {
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

/// Default export quality (0.1 to 1.0), only applies to JPEG format
@AppStorageDefault(key: "export.quality", defaultValue: 0.9)
static var defaultQuality: Double
```

### Testing Standards

#### Phase 09: Testing Implementation Complete

**Status**: ✅ COMPLETED - 2026-02-14

**Testing Framework**: XCTest fully integrated across all modules
**Coverage Achieved**: >85% line coverage
**Performance Bench**: <500ms capture latency target

**Bug Fixes Applied (v0.9.1 - 2026-02-15)**:
- Semaphore-based async testing in measure blocks
- Fixed invalid weak self on enum types
- Corrected UInt32 type casts
- Proper availability checks for SMAppService
- Simplified export validation logic

**Edge Case Handling Improvements (v0.9.1)**:
- Enhanced file management with directory validation
- File collision detection and resolution strategies
- Capture mode validation before execution
- Retry logic for transient failures
- Improved error handling and recovery patterns

**CGEventTap Implementation (v0.9.2)**:
- Replaced deprecated Carbon API with modern CGEventTap
- Swift-C interop for efficient event processing
- Thread-safe event handling with @MainActor dispatch
- Accessibility permission management with system settings integration
- Proper resource cleanup and memory management

### Test Naming Conventions

```swift
// Use descriptive test names with clear purpose
class CaptureEngineTests: XCTestCase {
    // Success scenarios
    func testCaptureFullscreenSuccess() throws { }
    func testCaptureRegionWithValidBounds() throws { }
    func testCaptureWindowExists() throws { }

    // Error scenarios
    func testCaptureFullscreenPermissionDenied() throws { }
    func testCaptureRegionInvalidBounds() throws { }
    func testCaptureWindowNotFound() throws { }

    // Edge cases
    func testCaptureMultipleDisplays() throws { }
    func testCaptureEmptyRegion() throws { }
    func testCaptureWithCursorHidden() throws { }
}
```

### Test Structure Standards

#### Base Test Class
```swift
class MacShotTestCase: XCTestCase {
    var captureEngine: CaptureEngine!
    var mockFileManager: MockFileManager!
    var testSettings: AppSettings!

    override func setUp() {
        super.setUp()
        // Setup test environment
        testSettings = AppSettings.defaults
        mockFileManager = MockFileManager()
        captureEngine = CaptureEngine(settings: testSettings)
    }

    override func tearDown() {
        // Cleanup
        captureEngine = nil
        mockFileManager = nil
        testSettings = nil
        super.tearDown()
    }
}
```

#### Unit Test Structure
```swift
class CaptureEngineTests: MacShotTestCase {
    // Test setup helpers
    private func createTestCaptureResult() -> CaptureResult {
        let image = NSImage(size: NSSize(width: 800, height: 600))
        return CaptureResult(
            image: image,
            mode: .fullscreen,
            metadata: CaptureMetadata(
                timestamp: Date(),
                displayID: 0,
                bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
                scaleFactor: 2.0
            )
        )
    }

    // Test methods
    func testCaptureFullscreenSuccess() throws {
        // Given
        let expectedMode: CaptureMode = .fullscreen

        // When
        let result = try captureEngine.capture(mode: expectedMode)

        // Then
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.mode, expectedMode)
        XCTAssertFalse(captureEngine.isCapturing)
    }
}
```

#### Integration Test Structure
```swift
class CaptureFlowIntegrationTests: MacShotTestCase {
    func testCaptureToEditorWorkflow() throws {
        // Given
        let expectation = XCTestExpectation(description: "Capture and editor workflow")

        // When
        captureEngine.onCaptureComplete = { [weak self] result in
            // Verify capture result
            XCTAssertNotNil(result.image)

            // Test editor integration
            let editor = ImageEditor(result: result)
            XCTAssertNotNil(editor)

            expectation.fulfill()
        }

        // Trigger capture
        try captureEngine.capture(mode: .fullscreen)

        // Wait for async operation
        wait(for: [expectation], timeout: 5.0)
    }
}
```

### Assertion Patterns

#### Basic Assertions
```swift
// Value assertions
XCTAssertNotNil(result.image, "Capture should return valid image")
XCTAssertEqual(result.mode, .fullscreen, "Capture mode should match expected")
XCTAssertTrue(result.image!.size.width > 0, "Image should have valid width")

// Error handling
XCTAssertThrowsError(try captureEngine.capture(mode: .invalid)) { error in
    XCTAssertEqual(error as? CaptureError, .invalidRegion, "Should throw invalid region error")
}

// Performance
measure {
    _ = try? captureEngine.capture(mode: .fullscreen)
}
```

#### Async Testing
```swift
func testAsyncCaptureOperation() async {
    // Async/await test syntax
    let result = try? await captureEngine.capture(mode: .fullscreen)
    XCTAssertNotNil(result, "Async capture should succeed")
}

func testAsyncCaptureWithTimeout() async {
    let task = Task {
        try await captureEngine.capture(mode: .fullscreen)
    }

    // Timeout handling
    let timeout = Task.detached(timeout: 2.0) {
        await task.value
    }

    do {
        try await timeout.value
    } catch {
        XCTFail("Capture operation timed out: \(error)")
    }
}
```

**Note**: For performance testing with async operations, use semaphores to properly handle async/await in measure blocks (see PerformanceTests.swift - fixed in v0.9.1):

### Test Data Management

#### Test Fixtures
```swift
struct TestFixtures {
    static let sampleImage = NSImage(size: NSSize(width: 1024, height: 768))

    static let sampleCaptureResult = CaptureResult(
        image: sampleImage,
        mode: .fullscreen,
        metadata: CaptureMetadata(
            timestamp: Date(),
            displayID: 0,
            bounds: CGRect(x: 0, y: 0, width: 1024, height: 768),
            scaleFactor: 2.0
        )
    )

    static let sampleSettings = AppSettings.defaults
}
```

#### Mock Objects
```swift
class MockFileManager {
    var savedFiles: [URL] = []
    var shouldThrowError = false

    func saveScreenshot(_ image: NSImage, name: String) throws -> URL {
        if shouldThrowError {
            throw CaptureError.fileSaveFailed(NSError(domain: "Test", code: 1))
        }

        let url = URL(fileURLWithPath: "/tmp/\(name).png")
        savedFiles.append(url)
        return url
    }
}
```

### Performance Testing

#### Performance Metrics
```swift
class PerformanceTests: MacShotTestCase {
    func testCapturePerformance() {
        measure([.default, .median, .maxStandardDeviation]) {
            for _ in 0...10 {
                _ = try? captureEngine.capture(mode: .fullscreen)
            }
        }
    }

    func testMemoryUsage() {
        measureMetrics([.allocatedMemory, .peakMemory], automaticallyStartMeasuring: false) {
            // Start measuring
            startMeasuring()

            // Perform test operation
            let result = try? captureEngine.capture(mode: .fullscreen)

            // Stop measuring
            stopMeasuring()

            XCTAssertNotNil(result)
        }
    }
}
```

#### UI Testing Standards
```swift
class UITests: XCTestCase {
    func testCaptureButtonInteraction() {
        let app = XCUIApplication()
        app.launch()

        // Verify initial state
        XCTAssertFalse(app.buttons["Capture"].isSelected)

        // Tap capture button
        app.buttons["Capture"].tap()

        // Verify state change
        XCTAssertTrue(app.buttons["Capture"].isSelected)

        // Verify progress indicator
        XCTAssertTrue(app.progressIndicators["Capturing"].exists)
    }
}
```

### Test Organization

#### Test Categories
```swift
// Unit Tests
@testable import MacShot
class CaptureEngineTests: MacShotTestCase { /* ... */ }

// Integration Tests
class CaptureFlowTests: MacShotTestCase { /* ... */ }

// UI Tests
class CaptureUITests: XCTestCase { /* ... */ }

// Performance Tests
class PerformanceTests: MacShotTestCase { /* ... */ }
```

#### Test Naming Convention
- `test[Feature][Scenario][ExpectedResult]`
  - `testCaptureFullscreenSuccess`
  - `testCaptureRegionInvalidBounds`
  - `testSettingsPersistenceMigration`
  - `testExportJPEGQualityHigh`

#### Test Data Best Practices
- Use test fixtures for consistent test data
- Mock external dependencies (file system, APIs)
- Generate test data programmatically when needed
- Clean up test artifacts after test execution

### Testing Guidelines

#### Test Coverage Priorities
1. **Critical Paths**: Core capture functionality
2. **Error Handling**: All error scenarios
3. **Edge Cases**: Boundary conditions
4. **Performance**: Resource usage and latency
5. **UI**: User interaction flows

#### Test Maintenance
- Keep tests simple and focused
- Update tests with code changes
- Remove obsolete tests regularly
- Use continuous integration for automated testing

#### Test Performance
- Unit tests should run in seconds
- Integration tests should run in minutes
- UI tests should be optimized for speed
- Performance tests should establish benchmarks

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

### Migration and Version Control

#### Settings Migration System
```swift
enum SettingsMigration {
    static let currentVersion: Int = 1
    private static let versionKey = "settings.version"

    static func migrateIfNeeded() {
        let storedVersion = UserDefaults.standard.integer(forKey: versionKey)
        if storedVersion < currentVersion {
            for version in storedVersion..<currentVersion {
                migrate(from: version, to: version + 1)
            }
            UserDefaults.standard.set(currentVersion, forKey: versionKey)
        }
    }

    private static func migrate(from: Int, to: Int) {
        // Specific migration logic for version changes
    }
}
```

#### Version Migration Patterns
- **Incremental**: Always migrate through each version sequentially
- **Safe**: Default values ensure app works with partial settings
- **Backward Compatible**: Migration doesn't lose existing data
- **Automatic**: Runs on app launch without user intervention

### Integration Standards

#### Settings-to-System Integration
```swift
// Settings are automatically integrated with system components:
// - HotkeyManager: SettingsStore.hotkeys.* for keyboard shortcuts
// - LaunchController: SettingsStore.launchAtLogin for autostart
// - ExportManager: SettingsStore.export.* for file output
// - EditorViewModel: SettingsStore.editor.* for annotation defaults
```

#### UI-Data Binding Patterns
```swift
// SettingsView maintains a working copy synced to SettingsStore
struct SettingsView: View {
    @State private var settings = AppSettings.defaults

    var body: some View {
        TabView {
            GeneralSettings(settings: $settings)
        }
        .onChange(of: settings) { _, _ in
            syncToStore() // Automatic synchronization
        }
    }
}
```

---

## Testing Standards (Phase 09)

### Phase 09: Testing Implementation Complete

**Status**: ✅ COMPLETED - 2026-02-14

**Testing Framework**: XCTest fully integrated across all modules
**Coverage Goal**: >90% line coverage
**Performance Bench**: <500ms capture latency target

### Test Organization Structure

```
Tests/
├── MacShotTests/
│   ├── CaptureEngineTests.swift
│   ├── CaptureModeTests.swift
│   ├── FileManagementTests.swift
│   ├── SettingsTests.swift
│   └── PerformanceTests.swift
├── MacShotUITests/
│   ├── CaptureFlowTests.swift
│   ├── SettingsUITests.swift
│   └── EditorUITests.swift
└── TestUtils/
    ├── MockData.swift
    ├── TestHelpers.swift
    └── PerformanceMetrics.swift
```

### Testing Best Practices

**Test Naming Convention**:
- Use descriptive names: `test[Feature][Scenario][ExpectedResult]`
- Example: `testCaptureFullscreenSuccess`
- Example: `testSettingsPersistenceMigration`

**Test Structure Patterns**:
- Base test class for common setup
- Separate test classes for different components
- Mock objects for isolation
- Async/await support

**Performance Testing**:
- Measure capture operations
- Monitor memory usage
- Benchmark UI responsiveness
- Memory leak detection

### Code Review Testing Checklist

During code review, ensure:
- [ ] Unit tests added for new features
- [ ] Integration tests for component interaction
- [ ] Performance benchmarks maintained
- [ ] Memory leak prevention verified
- [ ] Error scenarios covered
- [ ] CI/CD integration updated

---

*Last Updated: 2026-02-15*
*Version: 1.4.0*
*Phase 09: Testing Complete, Edge case fixes implemented (v0.9.1 - v0.9.2)*