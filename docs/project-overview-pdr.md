# MacShot Project Overview & Product Development Requirements (PDR)

## Project Summary

MacShot is a lightweight, native macOS screenshot application built with SwiftUI and Swift 6.0. Designed for macOS 15.0+, it provides fast, efficient screenshot capture with global hotkey support and smart file management.

## Product Vision

To create the most efficient and user-friendly screenshot tool for macOS, leveraging native Swift performance and modern SwiftUI interfaces to provide seamless screenshot capture with minimal system impact.

## Core Features

### Primary Features
- **Global Hotkey Capture**: Trigger screenshots from any application using configurable keyboard shortcuts
- **Menu Bar Integration**: Unobtrusive menu bar interface for quick access
- **Multiple Capture Modes**:
  - Fullscreen capture
  - Region selection capture
  - Window-specific capture
- **Smart File Management**: Automatic timestamp-based naming with customizable save locations
- **Performance Optimized**: Native Swift implementation for optimal performance

### Technical Features
- Swift 6.0 concurrency support
- macOS 15.0+ API utilization
- CoreGraphics integration for screen capture
- NSImage handling with Retina display support

## Product Development Requirements (PDR)

### Functional Requirements

#### FR-01: Capture Engine
- Must support fullscreen capture of all displays
- Must support region selection with visual overlay
- Must support window-specific capture by window ID
- Must handle Retina display scaling correctly
- Must include cursor in screenshots (configurable)

#### FR-02: Global Hotkey System
- Must register global hotkeys via modern CGEventTap API (v0.9.2)
- Must support custom key combinations
- Must capture hotkey events from any application
- Must handle hotkey conflicts gracefully
- **NEW**: Must provide accessibility permission management
- **NEW**: Must use Swift-C interop for efficient event processing
- **NEW**: Must support proper resource cleanup and memory management

#### FR-03: File Management
- Must save screenshots in user-specified directory
- Must generate timestamp-based filenames
- Must support PNG, JPG formats
- Must handle file permissions correctly
- **NEW**: Must provide directory validation and creation
- **NEW**: Must implement file collision detection and resolution
- **NEW**: Must include retry mechanisms for transient failures
- **NEW**: Must provide proper resource cleanup and temporary file management

#### FR-04: User Interface
- Must provide menu bar icon with dropdown menu
- Must show capture status in menu bar
- Must provide settings for configuration
- Must use SwiftUI for modern interface

#### FR-05: Settings System (Phase 08)
- Must provide centralized user preferences management
- Must support hotkey configuration with real-time recording
- Must persist all settings using UserDefaults
- Must provide tabbed settings interface
- Must support settings version migration
- Must integrate with HotkeyManager, LaunchController, ExportManager

#### FR-06: Integration Features
- Must respect macOS Screen Recording permission
- Must handle Accessibility permission for hotkeys
- Must integrate with macOS system services

### Non-Functional Requirements

#### NFR-01: Performance
- Launch time must be under 1 second
- Capture operation must be responsive (< 500ms)
- Memory usage must remain stable during operation
- CPU usage must be minimal when idle

#### NFR-02: Reliability
- Must not crash under normal operation
- Must handle edge cases gracefully
- Must provide meaningful error messages
- Must support 24/7 operation in menu bar

#### NFR-03: Security
- Must not collect any user data
- Must handle file permissions securely
- Must not execute arbitrary code
- Must use secure storage for configurations

#### NFR-04: Compatibility
- Must run on macOS 15.0+
- Must support Intel and Apple Silicon architectures
- Must work with different display configurations
- Must handle different screen resolutions

## Technical Specifications

### Architecture Overview
```
MacShot/
├── Core/                    # Core capture functionality
│   ├── CaptureEngine.swift  # Main coordinator
│   ├── FileManager.swift    # File operations
│   └── CaptureEngine/       # Capture implementations
│       ├── CaptureMode.swift      # Capture modes
│       ├── CaptureResult.swift    # Result types
│       ├── CaptureEngineCoordinator.swift
│       ├── FullscreenCapture.swift
│       ├── RegionCapture.swift
│       ├── WindowCapture.swift
│       └── ScreenCaptureHelper.swift
├── Features/                # Feature modules
│   ├── Capture/
│   │   └── RegionSelectionOverlay.swift
│   ├── Editor/              # Annotation editor
│   │   ├── EditorView.swift
│   │   ├── EditorToolbar.swift
│   │   ├── EditorWindow.swift
│   │   └── EditorViewModel.swift
│   └── Settings/            # Settings UI (Phase 08)
│       ├── SettingsView.swift
│       ├── GeneralSettings.swift
│       ├── HotkeysSettings.swift
│       ├── ExportSettings.swift
│       └── EditorSettings.swift
├── UI/                      # SwiftUI interfaces
│   └── MenuBarView.swift    # Menu bar interface
├── System/                  # System integration
│   ├── HotkeyManager.swift  # Global hotkey handling
│   └── Settings/            # Settings persistence (Phase 08)
│       ├── AppSettings.swift
│       ├── SettingsStore.swift
│       └── Migrations/
│           └── SettingsMigration.swift
└── Resources/               # Assets and resources
```

### Dependencies
- **AppKit**: macOS UI framework
- **CoreGraphics**: Low-level graphics operations
- **Carbon**: Global hotkey handling
- **SwiftConcurrency**: Async/await support
- **SwiftUI**: Reactive UI framework
- **Foundation**: Core framework services
- **UserDefaults**: Settings persistence

### Platform Requirements
- **macOS 15.0+**
- **Swift 6.0**
- **Xcode 15.0+** (for development)

## Development Phases

### Phase 1: Project Setup (Completed)
- ✅ Xcode project configuration
- ✅ Package.swift setup
- ✅ Basic app structure
- ✅ Initial entitlements

### Phase 2: Capture Engine (Completed)
- ✅ Core capture functionality
- ✅ Multiple capture modes
- ✅ Screen capture helpers
- ✅ Unit tests

### Phase 3: File Management (Completed)
- ✅ Save location configuration (ExportManager)
- ✅ Filename generation
- ✅ Format options (PNG, JPEG)
- ✅ Export quality settings
- ✅ Image cropping functionality

### Phase 4: Hotkey System (Completed - v0.9.2)
- ✅ Global hotkey registration via CGEventTap (v0.9.2)
- ✅ Hotkey configuration UI (Phase 08)
- ✅ Event handling with Swift-C interop (v0.9.2)
- ✅ HotkeyRecorder component
- ✅ Hotkey persistence (Phase 08)
- ✅ Accessibility permission management (v0.9.2)
- ✅ Resource cleanup and memory management (v0.9.2)

### Phase 5: User Interface (Completed)
- ✅ Menu bar implementation (MenuBarView)
- ✅ Settings interface (Phase 08)
- ✅ Editor UI complete
- ✅ Annotation tools
- ✅ Export functionality

### Phase 7: System Integration (Completed)
- ✅ LaunchController (login items)
- ✅ NotificationManager
- ✅ MenuBarManager
- ✅ System integration utilities

### Phase 8: Settings System (Completed)
- ✅ AppSettings @Observable model
- ✅ SettingsStore @propertyWrapper
- ✅ Tabbed settings interface (4 tabs)
- ✅ Individual settings views
- ✅ HotkeyRecorder component
- ✅ SettingsMigration system

### Phase 9: Testing & QA (Completed)
- ✅ Comprehensive test suite
- ✅ Performance benchmarks
- ✅ Edge case fixes and improvements (v0.9.1 - v0.9.2)
- ✅ CI/CD integration
- ✅ Enhanced async testing with semaphores (v0.9.1)
- ✅ Fixed memory leak and type cast issues (v0.9.1)

### Phase 10: Documentation (Completed)
- ✅ Technical documentation update (v0.9.1 - v0.9.2)
- ✅ User guide finalization
- ✅ App Store preparation documentation
- ✅ Code signing and notarization guidelines
- ✅ Edge case fixes documentation complete

## Success Metrics

### Performance Metrics
- Launch time: < 1 second
- Capture latency: < 500ms
- Memory usage: < 50MB idle
- CPU usage: < 2% idle

### Quality Metrics
- Crash rate: < 0.1%
- Memory leak count: 0
- Test coverage: 100% (101/101 tests passing)
- Code quality score: > 85/100

### User Experience
- App store rating: > 4.5 stars
- Positive reviews: > 80%
- Feature request response time: < 72 hours
- Bug fix turnaround: < 48 hours

## Regulatory Compliance

### Privacy Requirements
- **Privacy Policy**: Must include privacy policy for App Store submission
- **Data Collection**: No user data collected
- **Permissions**: Minimal required permissions clearly documented
- **Security**: Regular security audits

### App Store Requirements
- **App Store Connect**: Required for distribution
- **App Review**: Must pass Apple review process
- **Notarization**: Required code signing
- **Documentation**: Complete technical documentation

## Risk Assessment

### Technical Risks
- **API Changes**: macOS API updates may require adjustments
- **Performance**: Screen capture performance on different hardware
- **Memory**: Memory management with large image files

### Product Risks
- **Market Competition**: Screenshot tools market is crowded
- **User Adoption**: User migration from existing tools
- **Feature Creep**: Avoid over-engineering

### Mitigation Strategies
- **Testing**: Comprehensive testing on different macOS versions
- **Monitoring**: Performance monitoring and optimization
- **User Feedback**: Early user testing and feedback collection

## Maintenance Plan

### Version Management
- **Semantic Versioning**: MAJOR.MINOR.PATCH
- **Changelog**: Detailed changelog for each release
- **Beta Testing**: Public beta program for feedback

### Support Strategy
- **Documentation**: Complete technical documentation
- **User Support**: In-app help and documentation
- **Community**: GitHub issues and discussions
- **Security**: Regular security updates

## Appendices

### A. References
- [Apple Developer Documentation](https://developer.apple.com)
- [Swift Programming Language Guide](https://docs.swift.org)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)

### B. Templates
- Issue template: templates/issue.md
- Pull request template: templates/pull-request.md
- Code review checklist: templates/code-review.md

### C. Resources
- Design assets: Resources/
- Configuration files: Config/
- Documentation: docs/

### Technical Patterns Established (Phase 08-09)
- **@Observable**: Reactive SwiftUI state management for settings
- **@propertyWrapper**: Type-safe UserDefaults access with AppStorageDefault
- **MainActor**: Thread-safe UI updates and settings access
- **Codable**: Settings serialization for persistence
- **Equatable**: Settings change tracking for reactive updates
- **Version Migration**: Settings upgrade system for backward compatibility
- **Semaphore-based Async Testing**: Proper async/await testing patterns (v0.9.1)
- **CGEventTap**: Modern hotkey system replacing Carbon API (v0.9.2)
- **Enhanced Error Handling**: Comprehensive edge case handling and recovery patterns (v0.9.1)
- **Resource Management**: Proper cleanup and memory management for hotkeys and files

### Recent Enhancements (v1.0.0 - v1.0.1)
- **Edge Case Handling**: Comprehensive file management improvements
- **Hotkey System**: Modern CGEventTap implementation with Swift-C interop
- **Error Recovery**: Robust error handling and recovery mechanisms
- **Testing**: 100% test coverage (101/101 tests passing)
- **Swift 6 Concurrency**: Fixed @MainActor annotations in test classes
- **Memory Management**: Enhanced cleanup in HotkeyManager.unregister()

---
*Last Updated: 2026-02-16*
*Version: 1.3.1*
*Current Project Version: 1.0.1*
*All Major Features Complete - 100% Test Coverage Achieved*