---
title: "Phase 08 - Testing & Polish"
description: "Unit tests, UI tests, bug fixes, and release preparation"
status: pending
priority: P2
effort: 6h
branch: main
tags: [testing, polish, bug-fix]
created: 2026-02-14
---

## Overview

**Priority**: P2 (Quality assurance)
**Status**: Not Started
**Description**: Comprehensive testing, bug fixes, UX polish, and release preparation.

## Key Insights

- **XCTest** - Unit and UI testing framework
- **XCUITest** - UI automation testing
- **Instruments** - Performance profiling
- **App Store** - Distribution requirements

## Requirements

### Functional
- Unit tests for core logic
- UI tests for critical paths
- Performance benchmarks
- Accessibility audit
- Bug fixes
- Documentation

### Non-Functional
- > 60% code coverage
- < 100ms capture latency
- < 500ms export time
- 60fps rendering
- No crashes in normal use

## Architecture

```
Tests/
├── MacShotTests/
│   ├── CaptureEngineTests.swift
│   ├── AnnotationEngineTests.swift
│   ├── ExportManagerTests.swift
│   └── SettingsStoreTests.swift
└── MacShotUITests/
    ├── CaptureFlowUITests.swift
    ├── AnnotationFlowUITests.swift
    └── ExportFlowUITests.swift
```

## Related Code Files

### Create
- `MacShotTests/CaptureEngineTests.swift`
- `MacShotTests/AnnotationEngineTests.swift`
- `MacShotTests/ExportManagerTests.swift`
- `MacShotTests/SettingsStoreTests.swift`
- `MacShotUITests/CaptureFlowUITests.swift`
- `MacShotUITests/AnnotationFlowUITests.swift`
- `MacShotUITests/ExportFlowUITests.swift`
- `TESTING.md` - Testing guide
- `CHANGELOG.md` - Version history
- `docs/USER_GUIDE.md` - User documentation

### Modify
- All source files - Bug fixes

## Implementation Steps

### 1. Unit Tests (2h)

```swift
// CaptureEngineTests.swift
import XCTest
@testable import MacShot

final class CaptureEngineTests: XCTestCase {
    var engine: CaptureEngine!

    override func setUp() {
        super.setUp()
        engine = CaptureEngine()
    }

    func testFullscreenCapture() async throws {
        let result = try await engine.capture(mode: .fullscreen)
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.mode, .fullscreen)
    }

    func testRegionCapture() async throws {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let result = try await engine.capture(mode: .region(rect: rect))
        XCTAssertNotNil(result.image)
    }
}

// AnnotationEngineTests.swift
final class AnnotationEngineTests: XCTestCase {
    var engine: AnnotationEngine!

    func testAddShape() {
        let shape = RectangleShape(rect: .zero, style: .default)
        engine.addShape(shape)
        XCTAssertEqual(engine.shapes.count, 1)
    }

    func testUndo() {
        let shape = RectangleShape(rect: .zero, style: .default)
        engine.addShape(shape)
        engine.undo()
        XCTAssertEqual(engine.shapes.count, 0)
    }
}

// ExportManagerTests.swift
final class ExportManagerTests: XCTestCase {
    var manager: ExportManager!

    func testPNGExport() throws {
        let image = NSImage(size: NSSize(width: 100, height: 100))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.png")

        try XCTAssertNoThrow(
            manager.export(image: image, options: .init(format: .png, outputPath: url), cropper: ImageCropper())
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
}
```

### 2. UI Tests (1.5h)

```swift
// CaptureFlowUITests.swift
final class CaptureFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }

    func testFullscreenCapture() {
        app.menuBars.buttons["MacShot"].click()
        app.menuItems["Capture Fullscreen"].click()

        // Verify editor opens
        XCTAssertTrue(app.windows["MacShot Editor"].exists)
    }

    func testAnnotationFlow() {
        // Capture first
        testFullscreenCapture()

        // Select rectangle tool
        app.toolbars.buttons["Rectangle"].click()

        // Draw on canvas
        let canvas = app.images.firstMatch
        canvas.click()

        // Verify shape added
        XCTAssertTrue(app.images["RectangleShape"].exists)
    }
}
```

### 3. Performance Tests (1h)

```swift
// PerformanceTests.swift
final class PerformanceTests: XCTestCase {
    func testCaptureLatency() {
        let engine = CaptureEngine()
        measure {
            _ = try? await engine.capture(mode: .fullscreen)
        }
    }

    func testExportTime() {
        let manager = ExportManager()
        let image = NSImage(size: NSSize(width: 3840, height: 2160)) // 4K
        measure {
            _ = try? manager.export(image: image, options: .init(format: .png), cropper: ImageCropper())
        }
    }
}
```

### 4. Bug Fix Checklist (1h)

- [ ] Fix multi-display coordinate issues
- [ ] Fix Retina display scaling artifacts
- [ ] Fix export crash on large images
- [ ] Fix hotkey conflicts
- [ ] Fix undo/redo stack overflow
- [ ] Fix crop rectangle edge cases
- [ ] Fix window flicker on capture
- [ ] Fix memory leaks
- [ ] Fix accessibility labels
- [ ] Fix dark mode contrast issues

### 5. Documentation (0.5h)

```markdown
<!-- USER_GUIDE.md -->
# MacShot User Guide

## Capturing Screenshots

### Fullscreen
Press **Cmd+Shift+5** or select from menu bar.

### Region
Press **Cmd+Shift+6** then drag to select area.

### Window
Press **Cmd+Shift+7** then click target window.

## Annotating

- **Rectangle**: Draw rectangles
- **Ellipse**: Draw circles/ellipses
- **Arrow**: Draw directional arrows
- **Text**: Add text labels
- **Number**: Add numbered markers

## Exporting

1. Click **Export** in toolbar
2. Choose format (PNG/JPEG)
3. Adjust quality if JPEG
4. Save or copy to clipboard
```

## Todo List

- [ ] Write unit tests for CaptureEngine
- [ ] Write unit tests for AnnotationEngine
- [ ] Write unit tests for ExportManager
- [ ] Write unit tests for SettingsStore
- [ ] Write UI tests for capture flow
- [ ] Write UI tests for annotation flow
- [ ] Write UI tests for export flow
- [ ] Write performance tests
- [ ] Run all tests and fix failures
- [ ] Profile with Instruments
- [ ] Fix identified bugs
- [ ] Add accessibility labels
- [ ] Verify dark/light mode
- [ ] Write user guide
- [ ] Create CHANGELOG.md
- [ ] Prepare App Store metadata

## Success Criteria

- [ ] All unit tests pass
- [ ] All UI tests pass
- [ ] Code coverage > 60%
- [ ] Capture < 100ms
- [ ] Export < 500ms
- [ ] No memory leaks
- [ ] Accessibility compliant
- [ ] Documentation complete

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Test flakiness | Medium | Retry logic, proper waits |
| Performance regression | Medium | Baseline benchmarks |
| App Store rejection | High | Follow guidelines, test on real hardware |

## Security Considerations

- No hardcoded credentials
- Proper entitlements
- Privacy policy for screen capture

## Next Steps

**COMPLETE** - Ready for release when:
- All tests passing
- Bugs fixed
- Documentation complete
- App Store assets ready
