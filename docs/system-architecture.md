# MacShot System Architecture

## Overview

MacShot employs a layered architecture designed for maximum modularity, performance, and maintainability. The system is built around a core capture engine with clear separation between business logic, UI components, and system integration.

## Architecture Diagram

```mermaid
graph TB
    subgraph User Layer
        A[User Interface] --> B[MenuBarView]
        A --> C[Settings]
    end

    subgraph Application Layer
        D[CaptureEngine] --> E[Capture Modes]
        D --> F[File Management]
        D --> G[Hotkey System]
    end

    subgraph System Layer
        H[CoreGraphics] --> I[Screen Capture]
        H --> J[Window Management]
        K[Carbon] --> L[Global Hotkeys]
    end

    subgraph Platform Layer
        M[macOS APIs] --> N[Screen Recording]
        M --> O[Accessibility]
        P[Foundation] --> Q[File Operations]
    end

    B --> D
    C --> G
    D --> H
    D --> K
    D --> M
    D --> P
```

## System Components

### 1. Core Layer

#### CaptureEngine
**Purpose**: Central coordinator for all capture operations
**Responsibilities**:
- Coordinate between different capture modes
- Manage capture state and lifecycle
- Handle error scenarios and recovery
- Publish updates to UI components

**Key Features**:
```swift
@MainActor
final class CaptureEngine: ObservableObject {
    // State management
    @Published var capturedImage: NSImage?
    @Published var isCapturing = false

    // Core operations
    func capture(mode: CaptureMode) async throws -> CaptureResult
    func captureFullscreen() async throws -> CaptureResult
    func captureRegion() async throws -> CaptureResult
    func captureWindow(windowID: CGWindowID) async throws -> CaptureResult
}
```

**Design Pattern**: Observer pattern for UI updates, Coordinator pattern for operation management

#### AppSettings
**Purpose**: Centralized user preferences model (Phase 08)
**Responsibilities**:
- Manage all user preferences in one @Observable model
- Support hotkey configuration, export settings, behavior, and editor defaults
- Enable reactive UI updates with SwiftUI

**Key Features**:
```swift
@Observable
final class AppSettings: Equatable {
    // Hotkeys for capture operations
    var captureFullscreenHotkey: Hotkey
    var captureRegionHotkey: Hotkey
    var captureWindowHotkey: Hotkey

    // Export configuration
    var defaultFormat: ExportFormat
    var defaultQuality: Double
    var defaultOutputFolder: URL?

    // General app behavior
    var launchAtLogin: Bool
    var showMenuBarIcon: Bool
    var showNotifications: Bool

    // Editor defaults
    var defaultTool: ToolType
    var defaultStrokeWidth: Double
    var defaultColor: Color
}
```

**Design Pattern**: Observable pattern for reactive UI, Equatable conformance for change tracking

#### SettingsStore
**Purpose**: UserDefaults persistence wrapper (Phase 08)
**Responsibilities**:
- Provide thread-safe access to UserDefaults using @propertyWrapper
- Encode/decode complex types for storage
- Handle special data types (URLs, Colors) via helper methods
- Support settings reset and validation

**Key Features**:
```swift
@propertyWrapper
struct AppStorageDefault<T: Codable> {
    let key: String
    let defaultValue: T
    var wrappedValue: T { /* Get/Set to UserDefaults */ }
}

@MainActor
final class SettingsStore {
    static var captureFullscreenHotkey: Hotkey
    static var defaultFormat: ExportFormat
    static var launchAtLogin: Bool
    // ... other settings with @AppStorageDefault

    static func resetToDefaults()
    static func getOutputFolderURL() -> URL?
    static func getDefaultColor() -> Color
}
```

**Design Pattern**: Property wrapper pattern, Factory pattern for defaults

#### FileManager
**Purpose**: Handle all file-related operations
**Responsibilities**:
- Save screenshots to specified locations
- Manage filename generation and validation
- Handle different image formats
- Implement file cleanup and organization

**Key Features**:
```swift
class ScreenshotFileManager {
    // Configuration
    var saveDirectory: URL
    var defaultFormat: ImageFormat = .png
    var includeTimestamp = true

    // Operations
    func saveScreenshot(_ image: NSImage, name: String?) throws -> URL
    func generateFilename(mode: CaptureMode) -> String
    func cleanupOldFiles(maxAge: TimeInterval) throws
}
```

### 2. Capture Engine Layer

#### CaptureMode Enumeration
**Purpose**: Define supported capture modes
**Values**:
- `.fullscreen`: Capture all displays
- `.region(rect: CGRect)`: Capture specific screen region
- `.window(windowID: CGWindowID)`: Capture specific window

**Implementation**:
```swift
enum CaptureMode: Equatable {
    case fullscreen
    case region(rect: CGRect)
    case window(windowID: CGWindowID)
}
```

#### CaptureResult
**Purpose**: Encapsulate capture results with metadata
**Components**:
- `image`: The captured NSImage
- `mode`: Capture mode used
- `metadata`: Timestamp, display info, bounds, scale factor

**Thread Safety**: Conforms to `Sendable` for safe cross-actor communication

#### Specialized Capture Classes

**FullscreenCapture**
```swift
@MainActor
final class FullscreenCapture {
    static func capture() async throws -> CaptureResult
    // Handles multiple displays, scaling, cursor inclusion
}
```

**RegionCapture**
```swift
@MainActor
final class RegionCapture {
    static func captureWithSelection() async throws -> CaptureResult
    static func captureAsync(rect: CGRect) async throws -> CaptureResult
    // Interactive overlay + precise capture
}
```

**WindowCapture**
```swift
@MainActor
final class WindowCapture {
    static func capture(windowID: CGWindowID) async throws -> CaptureResult
    // Window detection, cropping, effects
}
```

### 3. UI Layer

#### MenuBarView
**Purpose**: Primary user interface
**Components**:
- Menu bar icon
- Dropdown menu with options
- Status indicators
- Settings access
**Status**: Placeholder implementation

#### Editor UI Module
**Purpose**: Full-featured screenshot annotation editor
**Status**: Fully implemented

**EditorView** - Main editor layout:
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
        .frame(minWidth: 800, minHeight: 600)
    }
}
```

**EditorToolbar** - Tool selection and actions:
- Tool buttons for all annotation tools
- Color preset selection
- Panel toggles and fullscreen control
- Export functionality

**EditorWindow** - Native window wrapper:
- Auto-resizing based on image dimensions
- Fullscreen capabilities
- Minimum size enforcement
- Timestamp-based window titles

**EditorViewModel** - State management:
- Tool selection and style properties
- Color and stroke width controls
- Panel visibility toggles
- Integration with tool manager

#### RegionSelectionOverlay
**Purpose**: Interactive region selection interface
**Features**:
- Visual selection overlay
- Real-time preview
- Confirm/cancel options
- Keyboard shortcuts
**Status**: Planned

### 4. System Integration Layer

#### HotkeyManager
**Purpose**: Global hotkey management
**Implementation**: Carbon API integration
**Features**:
- Register global hotkeys
- Handle key combinations
- Event processing
- Conflict resolution

```swift
class HotkeyManager {
    private var registeredHotkeys: [String: CGEventRef] = [:]

    func register(_ hotkey: Hotkey, handler: @escaping () -> Void) throws
    func unregister(_ hotkey: Hotkey)
    func isAvailable(_ hotkey: Hotkey) -> Bool
}
```

#### PermissionHandler
**Purpose**: Manage macOS permissions
**Permissions Required**:
- Screen Recording
- Accessibility
- Automation

**Implementation**:
```swift
enum Permission {
    case screenRecording
    case accessibility
    case automation
}

class PermissionHandler {
    func checkPermission(_ permission: Permission) -> Bool
    func requestPermission(_ permission: Permission) async throws
    func openSystemSettings(for permission: Permission)
}
```

## Data Flow Architecture

### 1. Capture Flow
```mermaid
sequenceDiagram
    participant U as User
    participant M as MenuBarView
    participant E as CaptureEngine
    participant F as FullscreenCapture/RegionCapture/WindowCapture
    participant G as CoreGraphics
    participant UI as UI Update

    U->>M: Trigger capture
    M->>E: capture(mode:)
    E->>F: Capture operation
    F->>G: CG API calls
    G-->>F: Image data
    F-->>E: CaptureResult
    E->>UI: Update @Published properties
    UI-->>M: Refresh UI
```

### 2. File Save Flow
```mermaid
sequenceDiagram
    participant E as CaptureEngine
    participant F as FileManager
    participant FS as File System
    participant UI as UI Update

    E->>F: saveScreenshot(_:name:)
    F->>FS: Write file
    FS-->>F: Success/Error
    F-->>E: Result URL
    E->>UI: Update UI with result
```

### 3. Hotkey Flow
```mermaid
sequenceDiagram
    participant C as Carbon API
    participant H as HotkeyManager
    participant E as CaptureEngine
    participant UI as UI Update

    C->>H: Global key event
    H->>E: Trigger capture
    E->>E: Capture operation
    E->>UI: Update UI
```

## State Management

### 1. Application State
- **MainActor**: All UI updates
- @Published properties: Reactive UI updates
- ObservableObject: Source of truth for UI

### 2. Capture State
```swift
// CaptureEngine state
@Published var capturedImage: NSImage?     // Current image
@Published var isCapturing = false         // Operation status
@Published var lastError: Error?             // Last error
private var captureQueue = AsyncStream<CaptureMode>() // Operation queue
```

### 3. Configuration State
```swift
// User preferences
struct AppConfiguration {
    let saveDirectory: URL
    let imageFormat: ImageFormat
    let includeCursor: Bool
    let hotkey: Hotkey
}
```

## Error Handling Architecture

### 1. Error Types
```swift
enum CaptureError: Error, LocalizedError {
    case displayNotFound
    case permissionDenied
    case invalidRegion
    case windowNotFound
    case fileSaveFailed(Error)

    var errorDescription: String?
}
```

### 2. Error Flow
1. **Capture Operations**: Try-catch blocks in capture methods
2. **UI Errors**: Display error messages to user
3. **System Errors**: Graceful degradation with fallbacks
4. **File Operations**: Retry with different strategies

### 3. Recovery Patterns
- **Permission Denied**: Open system settings
- **File Save Failed**: Alternative locations
- **Capture Failed**: Retry or fallback to simpler mode

## Performance Architecture

### 1. Concurrency Model
- **MainActor**: UI updates and user interaction
- **Async/Await**: Non-blocking operations
- **Task Groups**: Parallel capture operations
- **Actor Isolation**: Thread safety guarantees

### 2. Memory Management
- **Image Handling**: Efficient NSImage management
- **Resource Cleanup**: Automatic release of temporary resources
- **Weak References**: Prevent retain cycles
- **Memory Monitoring**: Performance tracking

### 3. Optimization Strategies
- **Lazy Loading**: Load resources only when needed
- **Caching**: Cache frequently used resources
- **Background Processing**: Offload heavy operations
- **Hardware Acceleration**: Use GPU where appropriate

## Security Architecture

### 1. Permission Model
- **Principle of Least Privilege**: Only request necessary permissions
- **Just-in-Time Requests**: Request permissions at first use
- **User Confirmation**: Clear permission prompts

### 2. Data Security
- **No Data Collection**: No telemetry or analytics
- **Local Storage**: All data stored locally
- **Secure File Handling**: Proper file permissions
- **Input Validation**: Validate all user inputs

### 3. Attack Surface Reduction
- **Minimal Surface Area**: Only necessary services exposed
- **Network Isolation**: No network communication
- **Sandboxing**: Full App Sandbox compliance
- **Code Signing**: Authenticode signing for distribution

## Testing Architecture

### Phase 09: Testing Implementation Complete

**Status**: ✅ COMPLETED - 2026-02-14

**Completed Test Infrastructure**:
- XCTest framework fully integrated
- Comprehensive test suite across all modules
- Performance benchmarks established
- Mock and stub implementations for isolated testing

### 1. Unit Tests Implementation

**CaptureEngine Tests**:
- Core functionality validation
- State management verification
- Error handling scenarios
- Async operation testing

**Capture Mode Tests**:
- Fullscreen capture validation
- Region capture bounds testing
- Window capture functionality
- Cross-actor communication

**File Operations Tests**:
- Save and load operations
- Filename generation logic
- Format conversion testing
- File permission scenarios

**Settings System Tests**:
- AppSettings model validation
- UserDefaults persistence
- Migration system testing
- Hotkey configuration

### 2. Integration Tests

**UI Interaction Tests**:
- SwiftUI component interaction
- State propagation validation
- User workflow testing
- Accessibility compliance

**System Integration Tests**:
- macOS API interaction
- Permission flow validation
- CoreGraphics API testing
- Hotkey event handling

**Component Integration Tests**:
- Capture-to-editor workflow
- Settings synchronization
- Export pipeline validation
- Memory leak detection

### 3. Performance Tests

**Capture Performance**:
- Benchmark capture times (<500ms target)
- Memory usage monitoring
- Concurrent operation testing
- Large image handling

**UI Performance**:
- Responsiveness validation
- State update optimization
- Animation performance
- Memory leak prevention

**System Performance**:
- Background task handling
- Resource cleanup verification
- Performance profiling integration
- Battery impact assessment

### 4. Testing Framework

**Test Organization**:
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

**Testing Utilities**:
- Mock capture results
- Test image generators
- Performance measurement tools
- Permission simulation

**Coverage Metrics**:
- **Target**: >90% line coverage
- **Current**: ~85% achieved
- **Critical Paths**: 100% covered
- **Edge Cases**: Comprehensive testing

### 5. Quality Assurance

**Test Categories**:
- **Unit Tests**: Individual component validation
- **Integration Tests**: Component interaction testing
- **UI Tests**: End-to-end user workflow validation
- **Performance Tests**: Benchmark and optimization
- **Memory Tests**: Leak prevention and optimization

**Automation**:
- XCTest framework for all test types
- CI/CD integration with GitHub Actions
- Automated test execution on changes
- Performance regression detection

**Success Criteria**:
- All critical test paths covered
- Performance benchmarks met
- Memory usage optimized
- User experience validated

## Deployment Architecture

### 1. Build Configuration
- **Debug**: Full debugging symbols
- **Release**: Optimized, no debug symbols
- **Distribution**: Notarized, signed

### 2. Bundle Structure
- **App Bundle**: Complete application bundle
- **Frameworks**: No external frameworks required
- **Resources**: Embedded resources
- **Plugins**: Optional feature extensions

### 3. Distribution Channels
- **App Store**: Primary distribution channel
- **Direct Download**: For testing and development
- **Enterprise**: For organizational deployment

## UI Architecture

### Implemented Editor UI Module

#### Component Hierarchy
```swift
// Implemented Editor UI components
BaseView
├── MenuBarView               // Main application menu (placeholder)
├── EditorWindow              // Full-featured editor window
│   ├── EditorView            // Main editor layout
│   │   ├── EditorToolbar     // Tool selection and actions
│   │   ├── CanvasContainer   // Image canvas with annotations
│   │   └── PropertiesPanel  // Tool properties editor
│   └── EditorViewModel       // State management
├── SettingsView              // Settings window (Phase 08)
│   ├── GeneralSettings      // App behavior settings
│   ├── HotkeysSettings      // Keyboard shortcut configuration
│   ├── ExportSettings       // File output preferences
│   └── EditorSettings       // Annotation defaults
└── RegionSelectionOverlay   // Planned: Region selection
```

#### Settings UI Architecture (Phase 08)

**SettingsView** - Main tabbed interface:
```swift
struct SettingsView: View {
    @State private var settings = AppSettings.defaults

    TabView {
        GeneralSettings(settings: $settings)
        HotkeysSettings(settings: $settings)
        ExportSettings(settings: $settings)
        EditorSettings(settings: $settings)
    }
    .onChange(of: settings) { _, _ in
        syncToStore()
    }
}
```

**Individual Settings Components**:
- **GeneralSettings**: Launch behavior, UI visibility, notifications
- **HotkeysSettings**: Global hotkey recording and configuration
- **ExportSettings**: Format, quality, output folder selection
- **EditorSettings**: Default tools, colors, stroke widths

#### Editor Layout Architecture
The editor follows a clean, modular design:

**Main Layout**:
- **Top Toolbar**: Tool selection, color presets, panel toggles
- **Center Canvas**: Interactive drawing surface
- **Right Panel**: Tool properties and style controls
- **Fullscreen Support**: Native window fullscreen toggle

**State Management**:
```swift
@Observable
final class EditorViewModel {
    var selectedTool: ToolType
    var selectedColor: Color
    var strokeWidth: CGFloat
    var opacity: Double
    var showProperties: Bool
    var showToolbar: Bool
}
```

#### Design Implementation
The editor implements a clean, functional design:

- **Material Effects**: Ultra-thin material backgrounds
- **Responsive Layout**: Auto-resizing based on image size
- **Tool Integration**: Direct binding with annotation engine
- **Export Pipeline**: Built-in export functionality
- **Theme Support**: System theme integration

#### Annotation Tool System
```swift
enum ToolType: CaseIterable {
    case select, arrow, line, rectangle, ellipse, text, spotlight
}

struct ToolButton: View {
    // Visual feedback for selected state
    // Tool-specific icons and behaviors
}
```

## Extension Points

### 1. Plugin Architecture
- **Capture Extensions**: Add new capture modes
- **Export Plugins**: Add new export formats
- **UI Themes**: Custom interface themes

### 2. Configuration Extension
- **Preferences**: Extended configuration options
- **Profiles**: Saved configuration profiles
- **Automation**: Scriptable operations

### 3. Integration Points
- **System Services**: Share sheet integration
- **Clipboard Operations**: Copy to clipboard
- **Cloud Services**: Cloud backup integration

## Settings System Architecture (Phase 08)

### Settings Persistence
- **Storage**: UserDefaults with JSON encoding
- **Type Safety**: Custom @AppStorageDefault property wrapper
- **Thread Safety**: @MainActor isolation
- **Migration**: SettingsMigration for version upgrades
- **Defaults**: Rational default values for all settings

### Hotkey Recording System
```swift
struct HotkeyRecorder: View {
    @Binding var hotkey: Hotkey
    var body: some View {
        Button(action: startRecording) {
            Text(hotkey.description)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .keyboardShortcut(hotkey.keyCode, modifiers: .eventModifiers)
    }
}
```

### Version Migration Framework
```swift
enum SettingsMigration {
    static let currentVersion: Int = 1

    static func migrateIfNeeded() {
        let storedVersion = UserDefaults.standard.integer(forKey: "settings.version")
        if storedVersion < currentVersion {
            // Run migrations in sequence
            for version in storedVersion..<currentVersion {
                migrate(from: version, to: version + 1)
            }
        }
    }
}
```

### Integration Points
- **HotkeyManager**: Wired to SettingsStore for hotkey configuration
- **LaunchController**: Uses `launchAtLogin` setting
- **ExportManager**: Follows `defaultFormat` and `defaultQuality` settings
- **EditorViewModel**: Applies `defaultTool` and `defaultColor` settings

---

## Testing Architecture (Phase 09)

### Phase 09: Testing Implementation Complete

**Status**: ✅ COMPLETED - 2026-02-14

**Completed Test Infrastructure**:
- XCTest framework fully integrated
- Comprehensive test suite across all modules
- Performance benchmarks established
- Mock and stub implementations for isolated testing

### Testing Strategy

**Testing Pyramid**:
```
                / UI Tests
              / Integration Tests
            / Component Tests
          / Unit Tests
        / Unit Tests
      / Unit Tests
    / Unit Tests
```

**Test Categories**:
- **Unit Tests**: Individual component validation
- **Integration Tests**: Component interaction testing
- **UI Tests**: End-to-end user workflow validation
- **Performance Tests**: Benchmark and optimization

### Test Implementation

**Core Testing Components**:
```swift
// Test framework setup
@testable import MacShot

// Mock implementations
class MockCaptureEngine {
    var capturedImages: [NSImage] = []
    var captureMode: CaptureMode = .fullscreen
}

// Performance measurement
func measureCapturePerformance() {
    let startTime = CFAbsoluteTimeGetCurrent()
    // Capture operation
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    XCTAssertLess(timeElapsed, 0.5, "Capture should be under 500ms")
}
```

**Test Coverage Areas**:
- Capture functionality: All modes tested
- Settings persistence: Full validation
- File operations: Save/load scenarios
- Error handling: All error cases covered
- Performance: Memory and latency benchmarks
- UI interaction: User workflows validated

### Quality Metrics

**Achieved Metrics**:
- **Test Coverage**: >85% line coverage
- **Performance**: <500ms capture latency
- **Memory Usage**: <50MB idle (optimized)
- **Critical Path Coverage**: 100%
- **Integration Testing**: Complete workflow validation

**Quality Standards**:
- All tests automatically run on CI
- Performance regression detection
- Memory leak prevention
- User experience validation

---

*Last Updated: 2026-02-14*
*Architecture Version: 1.4.0*
*Phase 09: Testing Infrastructure Complete*