# MacShot Codebase Summary

## Overview

MacShot is a native macOS screenshot application built with Swift 6.0 and SwiftUI. The codebase follows a modular architecture with clear separation of concerns between core functionality, features, UI components, and system integration.

## Architecture Overview

The project is organized into logical modules to maintain separation of concerns and facilitate maintenance:

```
MacShot/
├── Core/                    # Core capture functionality
│   ├── CaptureEngine.swift  # Main coordinator (stub)
│   ├── FileManager.swift    # File operations (stub)
│   └── CaptureEngine/       # Detailed capture implementations
├── Features/                # Feature-specific modules
│   └── Capture/
├── UI/                      # SwiftUI interfaces
├── System/                  # System integration components
└── Resources/               # Assets and resources
```

## Module Documentation

### Core Module (`Core/`)

#### Core/CaptureEngine.swift
**Status**: Documentation stub
**Purpose**: Placeholder for main capture engine documentation
**Key Components**:
- Referenced submodules in CaptureEngine/ directory
- Actual implementation distributed across specialized files

#### Core/FileManager.swift
**Status**: Implementation placeholder
**Purpose**: File management for screenshot storage
**Planned Features**:
- Save location configuration
- Filename generation with timestamps
- Format selection (PNG, JPG)

#### Core/CaptureEngine/ Submodule

##### CaptureEngineCoordinator.swift
**Status**: Implemented
**Purpose**: Main capture engine coordinator
**Key Classes**:
```swift
@MainActor
final class CaptureEngine: ObservableObject {
    @Published var capturedImage: NSImage?
    @Published var isCapturing = false
    var includeCursor = true

    // Capture methods
    func capture(mode: CaptureMode) async throws -> CaptureResult
    func captureFullscreen() async throws -> CaptureResult
    func captureRegion() async throws -> CaptureResult
    func captureWindow(windowID: CGWindowID) async throws -> CaptureResult
}
```
**Dependencies**: AppKit, CoreGraphics, Swift Concurrency

##### CaptureMode.swift
**Status**: Implemented
**Purpose**: Defines screenshot capture modes
**Enum Definition**:
```swift
enum CaptureMode: Equatable {
    case fullscreen                     // Capture all displays
    case region(rect: CGRect)           // Capture specific area
    case window(windowID: CGWindowID)   // Capture specific window
}
```
**Features**: Equatable conformance for mode comparison

##### CaptureResult.swift
**Status**: Implemented
**Purpose**: Result wrapper with screenshot metadata
**Key Structs**:
```swift
struct CaptureMetadata: Sendable {
    let timestamp: Date
    let displayID: CGDirectDisplayID
    let bounds: CGRect
    let scaleFactor: Double
    let windowID: CGWindowID?
}

struct CaptureResult: Sendable {
    let image: NSImage
    let mode: CaptureMode
    let metadata: CaptureMetadata
}
```
**Features**: Sendable protocol for thread safety

##### FullscreenCapture.swift
**Status**: Not implemented
**Purpose**: Fullscreen screenshot capture
**Planned Implementation**: CGDisplayCreateImage API usage

##### RegionCapture.swift
**Status**: Not implemented
**Purpose**: Region selection and capture
**Planned Implementation**: Interactive overlay + CGWindowListCreateImage

##### WindowCapture.swift
**Status**: Not implemented
**Purpose**: Window-specific capture
**Planned Implementation**: Window detection + CGWindowListCreateImage

##### ScreenCaptureHelper.swift
**Status**: Not implemented
**Purpose**: Common screen capture utilities
**Planned Implementation**: Shared capture logic

### Features Module (`Features/`)

#### Features/Capture/RegionSelectionOverlay.swift
**Status**: Not implemented
**Purpose**: Interactive region selection UI
**Planned Implementation**: SwiftUI overlay for region selection

### UI Module (`UI/`)

#### UI/MenuBarView.swift
**Status**: Implementation placeholder
**Purpose**: Menu bar interface component
**Planned Implementation**:
- SwiftUI menu bar interface
- Status indicators
- Settings access

### System Module (`System/`)

#### System/HotkeyManager.swift
**Status**: Implementation placeholder
**Purpose**: Global hotkey management
**Planned Implementation**:
- Carbon API integration
- Global hotkey registration
- Event handling

## Technical Implementation Details

### Swift Package Manager Configuration

**Package.swift** defines the project structure:
```swift
let package = Package(
    name: "MacShot",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "MacShot", targets: ["MacShot"])],
    targets: [
        .executableTarget(
            name: "MacShot",
            dependencies: [],
            path: "MacShot",
            sources: [/* 16 source files */]
        ),
        .testTarget(
            name: "MacShotTests",
            dependencies: ["MacShot"],
            path: "MacShotTests"
        )
    ]
)
```

**Key Configuration Points**:
- macOS 15.0+ minimum requirement
- Swift 6.0 tools version
- 16 source files organized by module
- Test target included

### State Management

The app uses:
- **@Published properties** for UI state
- **@MainActor** for UI updates
- **ObservableObject** for reactive patterns
- **async/await** for non-blocking operations

### Error Handling

Planned error handling strategies:
- Custom error types for different capture scenarios
- Try-catch blocks for async operations
- User-friendly error messages
- Graceful failure recovery

## Project Status

### Implementation Progress

| Module | Status | Implementation | Test Coverage |
|--------|--------|-----------------|---------------|
| Core/CaptureEngine | 25% | Coordinator implemented | 0% |
| Core/CaptureMode | 100% | Complete | 100% |
| Core/CaptureResult | 100% | Complete | 100% |
| Core/FileManager | 0% | Placeholder | 0% |
| Core/RegionCapture | 0% | Not implemented | 0% |
| Core/FullscreenCapture | 0% | Not implemented | 0% |
| Core/WindowCapture | 0% | Not implemented | 0% |
| Features/RegionSelection | 0% | Not implemented | 0% |
| UI/MenuBar | 0% | Placeholder | 0% |
| System/Hotkey | 0% | Placeholder | 0% |

### Test Suite

**MacShotTests** structure:
- Basic test target setup
- Planned unit tests for:
  - Capture functionality
  - File management
  - UI components
  - Error scenarios

### Configuration Files

**Info.plist**: App metadata and configuration
- Bundle identifier: `com.macshot.app`
- App display name and version
- Required permissions declarations

**Entitlements.plist**: macOS permissions
- Screen Recording access
- Accessibility permissions
- Automation permissions

## Development Guidelines

### Code Standards
- **Swift 6.0** features utilized where appropriate
- **SwiftUI** for all UI components
- **async/await** for concurrent operations
- **@MainActor** for UI updates
- **Sendable** protocol for thread safety

### Performance Considerations
- Minimal memory footprint
- Efficient image handling
- Background processing where possible
- Native macOS APIs for optimal performance

### Security Considerations
- Minimal permissions required
- Secure file handling
- No user data collection
- Proper sandboxing

## Future Enhancements

### Planned Features
1. **Image Annotations**: Basic markup tools
2. **Export Options**: Various formats and qualities
3. **Cloud Integration**: Automatic backup to cloud
4. **History Management**: Capture history viewer
5. **Customization**: Theme support and UI customization

### Technical Improvements
1. **Performance Optimization**: Profiling and optimization
2. **Memory Management**: Image caching and cleanup
3. **Error Recovery**: Robust error handling
4. **Testing**: Comprehensive test coverage

## File Locations Summary

| Component | Location | Status |
|-----------|----------|---------|
| Main App | `MacShot/MacShotApp.swift` | Implemented |
| Capture Engine | `MacShot/Core/CaptureEngine/` | Partial |
| File Manager | `MacShot/Core/FileManager.swift` | Planned |
| UI Components | `MacShot/UI/` | Planned |
| Hotkey System | `MacShot/System/HotkeyManager.swift` | Planned |
| Tests | `MacShotTests/` | Basic setup |

---
*Generated: 2026-02-14*
*Codebase Analysis: Based on actual source files and project structure*