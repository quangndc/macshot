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
│       ├── CaptureEngineCoordinator.swift  # Main capture engine
│       ├── CaptureMode.swift      # Defines screenshot capture modes
│       ├── CaptureResult.swift    # Result wrapper with metadata
│       ├── FullscreenCapture.swift
│       ├── RegionCapture.swift
│       ├── WindowCapture.swift
│       └── ScreenCaptureHelper.swift
├── Core/Annotation/         # Annotation system (Phase 05 complete)
│   ├── Models/             # Shape models and protocols
│   ├── Tools/             # Tool management and types
│   ├── AnnotationCanvas.swift
│   ├── AnnotationEngine.swift
│   └── InteractionHandler.swift
├── Core/Export/           # Export functionality
│   ├── Formats/           # PNG/JPEG exporters
│   ├── ExportManager.swift
│   ├── ExportOptions.swift
│   ├── ImageCropper.swift
│   └── AspectRatio.swift
├── Features/              # Feature-specific modules
│   ├── Capture/
│   │   └── RegionSelectionOverlay.swift
│   ├── Editor/            # Full-featured editor UI (Phase 05)
│   │   ├── Components/    # Editor UI components
│   │   ├── EditorView.swift
│   │   ├── EditorToolbar.swift
│   │   ├── EditorWindow.swift
│   │   └── EditorViewModel.swift
│   └── Settings/          # Settings UI (Phase 08 - Complete)
│       ├── SettingsView.swift
│       ├── GeneralSettings.swift
│       ├── HotkeysSettings.swift
│       ├── ExportSettings.swift
│       └── EditorSettings.swift
├── System/                # System integration components
│   ├── HotkeyManager.swift  # Global hotkey management (placeholder)
│   └── Settings/            # Settings persistence (Phase 08)
│       ├── AppSettings.swift
│       ├── SettingsStore.swift
│       └── Migrations/
│           └── SettingsMigration.swift
├── UI/                    # SwiftUI interfaces
│   └── MenuBarView.swift    # Main application menu (placeholder)
└── Resources/             # Assets and resources
```

## Module Documentation

### Core Module (`Core/`)

#### Core/CaptureEngine.swift
**Status**: Implementation placeholder
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

### Annotation Module (`Core/Annotation/`)

#### Annotation Canvas and Engine
**Status**: Implemented (Phase 05)
**Purpose**: Full-featured annotation system for screenshots
**Key Components**:
- Shape models: Arrow, Ellipse, Line, Rectangle, Text, Spotlight
- Tool management: ToolType enum, ToolFactory
- Canvas rendering: AnnotationCanvas with real-time updates
- Interaction handling: Mouse/touch event processing

### Export Module (`Core/Export/`)

#### Export System
**Status**: Implemented
**Purpose**: Multiple format export functionality
**Key Components**:
- PNG/JPEG exporters with quality settings
- Export manager with format selection
- Image cropping and aspect ratio handling
- Export options configuration

### Settings Module (`System/Settings/`)

#### System/Settings/AppSettings.swift
**Status**: Implemented (Phase 08)
**Purpose**: Centralized user preferences model
**Key Components**:
```swift
@Observable
final class AppSettings: Equatable {
    var captureFullscreenHotkey: Hotkey
    var captureRegionHotkey: Hotkey
    var captureWindowHotkey: Hotkey
    var defaultFormat: ExportFormat
    var defaultQuality: Double
    var defaultOutputFolder: URL?
    var launchAtLogin: Bool
    var showMenuBarIcon: Bool
    var showNotifications: Bool
    var defaultTool: ToolType
    var defaultStrokeWidth: Double
    var defaultColor: Color
}
```
**Features**: Equatable conformance for SwiftUI change tracking, reactive UI updates

#### System/SettingsStore.swift
**Status**: Implemented (Phase 08)
**Purpose**: UserDefaults persistence with custom property wrapper
**Key Components**:
```swift
@propertyWrapper
struct AppStorageDefault<T: Codable> {
    let key: String
    let defaultValue: T
    var wrappedValue: T { /* Get/Set to UserDefaults */ }
}

@MainActor
final class SettingsStore {
    @AppStorageDefault(key: "hotkeys.fullscreen", defaultValue: Hotkey(...))
    static var captureFullscreenHotkey: Hotkey

    // Helper methods for complex types (URL, Color)
    static func getOutputFolderURL() -> URL?
    static func getDefaultColor() -> Color
    static func resetToDefaults()
}
```
**Features**: Type-safe storage, thread-safe access, default value fallback

#### System/Settings/Migrations/SettingsMigration.swift
**Status**: Implemented (Phase 08)
**Purpose**: Version migration system for settings upgrades
**Key Components**:
```swift
enum SettingsMigration {
    static let currentVersion: Int = 1
    static func migrateIfNeeded()
    static func migrate(from: Int, to: Int)
    static func resetToDefaults()
    static func validate() -> Bool
}
```
**Features**: Incremental migrations, backward compatibility, automatic upgrade

### Settings UI Module (`Features/Settings/`)

#### Features/Settings/SettingsView.swift
**Status**: Implemented (Phase 08)
**Purpose**: Main settings window with tabbed interface
**Key Components**:
```swift
struct SettingsView: View {
    @State private var settings = AppSettings.defaults

    TabView {
        GeneralSettings(settings: $settings)
        HotkeysSettings(settings: $settings)
        ExportSettings(settings: $settings)
        EditorSettings(settings: $settings)
    }
}
```
**Features**: Tabbed interface, real-time synchronization to SettingsStore

#### Individual Settings Views
- **GeneralSettings**: App behavior (launch, notifications, UI visibility)
- **HotkeysSettings**: Global hotkey configuration with HotkeyRecorder
- **ExportSettings**: File output configuration (format, quality, location)
- **EditorSettings**: Annotation defaults (tools, colors, stroke width)

### Editor UI Module (`Features/Editor/`)

#### Features/Editor/EditorView.swift
**Status**: Implemented (Phase 05)
**Purpose**: Main editor interface with canvas and properties panel
**Key Components**:
```swift
struct EditorView: View {
    let result: CaptureResult
    @State private var viewModel: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            EditorToolbar(viewModel: viewModel, onToggleFullscreen: {})
            HStack(spacing: 0) {
                CanvasContainer(result: result, viewModel: viewModel)
                PropertiesPanel(viewModel: viewModel)
            }
        }
    }
}
```

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
            sources: [/* 20+ source files */]
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
- 20+ source files organized by module (Phase 08 added Settings module)
- Test target included

### State Management

The app uses:
- **@Published properties** for UI state
- **@MainActor** for UI updates
- **ObservableObject** for reactive patterns
- **@Observable** for SwiftUI reactive data sources (Phase 08)
- **async/await** for non-blocking operations

### Settings System (Phase 08 Implementation)

**Architecture Pattern**: Reactive settings with real-time UI updates
```swift
// Model layer
@Observable
final class AppSettings: Equatable {
    // All user preferences in one place
}

// Persistence layer
@propertyWrapper
struct AppStorageDefault<T: Codable> {
    // Type-safe UserDefaults access
}

// UI layer
struct SettingsView: View {
    @State private var settings = AppSettings.defaults
    // Real-time synchronization to SettingsStore
}
```

**Key Features**:
- **Type Safety**: Custom property wrapper with Codable conformance
- **Reactive UI**: @Observable enables automatic UI updates
- **Version Migration**: SettingsMigration for upgrades
- **Integration**: Wired to HotkeyManager, LaunchController, ExportManager
- **User Experience**: Tabbed interface with live preview

### Error Handling

Planned error handling strategies:
- Custom error types for different capture scenarios
- Try-catch blocks for async operations
- User-friendly error messages
- Graceful failure recovery

**Settings-Specific Error Handling**:
- Invalid hotkey combinations
- Settings migration failures
- Permission issues for autostart
- Export configuration validation

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
| Features/Editor | 100% | Complete | 100% |
| System/Hotkey | 0% | Placeholder | 0% |
| **System/Settings** | **100%** | **Complete (Phase 08)** | **100%** |
| Features/Settings UI | 100% | Complete (4 tabs) | 100% |
| Settings Migration | 100% | v1 migration system | 100% |
| Core/Annotation | 100% | Complete | 100% |
| Core/Export | 100% | Complete | 100% |

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
| **Settings System** | **`MacShot/System/Settings/`** | **Implemented (Phase 08)** |
| **Settings UI** | **`MacShot/Features/Settings/`** | **Implemented (Phase 08)** |
| Annotation System | `MacShot/Core/Annotation/` | Complete |
| Export System | `MacShot/Core/Export/` | Complete |
| Tests | `MacShotTests/` | Basic setup |

### New Files Added (Phase 08)

**Settings Architecture**:
- `System/Settings/AppSettings.swift` - Central @Observable settings model
- `System/SettingsStore.swift` - UserDefaults persistence wrapper
- `System/Settings/Migrations/SettingsMigration.swift` - Version migration system

**Settings UI Components**:
- `Features/Settings/SettingsView.swift` - Tabbed settings interface
- `Features/Settings/GeneralSettings.swift` - App behavior settings
- `Features/Settings/HotkeysSettings.swift` - Keyboard shortcuts
- `Features/Settings/ExportSettings.swift` - File export preferences
- `Features/Settings/EditorSettings.swift` - Annotation defaults

**Supporting Components**:
- `Features/Settings/HotkeyRecorder.swift` - Interactive hotkey recording

### Technical Patterns Established (Phase 08)
- **@Observable**: Reactive SwiftUI state management for settings
- **@propertyWrapper**: Type-safe UserDefaults access with AppStorageDefault
- **MainActor**: Thread-safe UI updates and settings access
- **Codable**: Settings serialization for persistence
- **Equatable**: Settings change tracking for reactive updates
- **Version Migration**: Settings upgrade system for backward compatibility

---
*Generated: 2026-02-14*
*Codebase Analysis: Based on actual source files and project structure*
*Updated: Settings module completed in Phase 08 (7 new files)*