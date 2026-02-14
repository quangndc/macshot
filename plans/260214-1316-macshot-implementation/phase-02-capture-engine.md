---
title: "Phase 02 - Capture Engine"
description: "Screenshot capture implementation for fullscreen, region, and window modes"
status: pending
priority: P1
effort: 8h
branch: main
tags: [capture, cgwindowlist, screenshot]
created: 2026-02-14
---

## Context Links

- [Screenshot APIs Research](../../researcher-260214-1310-screenshot-apis.md) - Complete API reference
- [Multi-Display Support](../../researcher-260214-1310-screenshot-apis.md#4-multi-display-support-considerations)
- [DPI/Retina Handling](../../researcher-260214-1310-screenshot-apis.md#5-dpiretina-display-handling)

## Overview

**Priority**: P1 (Core feature)
**Status**: Not Started
**Description**: Implement screenshot capture engine supporting fullscreen, region selection, and window detection using CGWindowList APIs.

## Key Insights

From research:
- **CGWindowListCreateImage** - primary capture API
- **kCGWindowListOptionOnScreenWindows** for visible windows
- **NSScreen.backingScaleFactor** for Retina support
- **CGDisplayStream** for real-time region selection
- Multi-display support via `NSScreen.screens`

## Requirements

### Functional
- Fullscreen capture (all displays)
- Region capture with drag selection UI
- Window capture with auto-detection
- Async capture to avoid UI blocking
- Cursor inclusion toggle

### Non-Functional
- < 100ms capture latency
- Handle Retina displays correctly
- Support multiple monitors
- Memory efficient for large screenshots

## Architecture

```
Core/CaptureEngine/
├── CaptureEngine.swift           # Main capture coordinator
├── CaptureMode.swift             # Enum: .fullscreen, .region, .window
├── CaptureResult.swift           # Result wrapper with metadata
├── FullscreenCapture.swift       # Display capture
├── RegionCapture.swift           # Selection + capture
└── WindowCapture.swift           # Window detection + capture
```

### Data Flow

```
User Action → CaptureEngine → CaptureMode → API Call → NSImage → CaptureResult
                                              ↓
                                         Metadata
                                         (timestamp, display, bounds)
```

## Related Code Files

### Create
- `MacShot/Core/CaptureEngine/CaptureEngine.swift`
- `MacShot/Core/CaptureEngine/CaptureMode.swift`
- `MacShot/Core/CaptureEngine/CaptureResult.swift`
- `MacShot/Core/CaptureEngine/FullscreenCapture.swift`
- `MacShot/Core/CaptureEngine/RegionCapture.swift`
- `MacShot/Core/CaptureEngine/WindowCapture.swift`
- `MacShot/Features/Capture/RegionSelectionOverlay.swift`

### Modify
- `MacShot/MacShotApp.swift` - Wire up capture engine

## Implementation Steps

### 1. Core Capture Engine (2h)

```swift
// CaptureEngine.swift
import AppKit
import CoreGraphics

@MainActor
final class CaptureEngine: ObservableObject {
    @Published var capturedImage: NSImage?
    @Published var isCapturing = false

    func capture(mode: CaptureMode) async throws -> CaptureResult {
        isCapturing = true
        defer { isCapturing = false }

        switch mode {
        case .fullscreen: return try await captureFullscreen()
        case .region: return try await captureRegion()
        case .window: return try await captureWindow()
        }
    }
}

enum CaptureMode {
    case fullscreen
    case region(rect: CGRect)
    case window(windowID: CGWindowID)
}
```

### 2. Fullscreen Capture (1.5h)

```swift
// FullscreenCapture.swift
func captureFullscreen() async throws -> CaptureResult {
    let screen = NSScreen.main!
    let rect = screen.frame
    let scale = screen.backingScaleFactor

    let cgImage = CGWindowListCreateImage(
        rect,
        .optionOnScreenWindows,
        kCGNullWindowID,
        .nominalResolution
    )!

    let image = NSImage(cgImage: cgImage, size: rect.size)

    return CaptureResult(
        image: image,
        mode: .fullscreen,
        metadata: CaptureMetadata(displayID: CGMainDisplayID())
    )
}
```

### 3. Region Capture (2.5h)

- Create overlay window for drag selection
- Draw selection rectangle
- Capture only selected region
- Handle multi-display regions

```swift
// RegionCapture.swift
func captureRegion() async throws -> CaptureResult {
    // Show selection overlay
    // Wait for user selection
    // Capture selected rect
    let rect = await showRegionSelection()
    let cgImage = CGWindowListCreateImage(rect, .optionOnScreenWindows, kCGNullWindowID, .nominalResolution)!
    return CaptureResult(image: NSImage(cgImage: cgImage, size: rect.size), mode: .region)
}
```

### 4. Window Capture (2h)

```swift
// WindowCapture.swift
func captureWindow(windowID: CGWindowID) async throws -> CaptureResult {
    let windowInfo = CGWindowListCopyWindowInfo([.optionIncludingWindow], windowID).first as! [String: Any]
    let boundsDict = windowInfo[kCGWindowBounds as String] as! [String: Any]
    let bounds = CGRect(fromDictionary: boundsDict)

    let cgImage = CGWindowListCreateImage(
        bounds,
        .optionIncludingWindow,
        windowID,
        .nominalResolution
    )!

    return CaptureResult(
        image: NSImage(cgImage: cgImage, size: bounds.size),
        mode: .window
    )
}
```

## Todo List

- [ ] Create CaptureMode enum
- [ ] Implement CaptureEngine coordinator
- [ ] Implement fullscreen capture
- [ ] Implement region selection overlay
- [ ] Implement region capture
- [ ] Implement window detection
- [ ] Implement window capture
- [ ] Add metadata tracking (timestamp, display info)
- [ ] Add cursor inclusion option
- [ ] Test on multi-display setup
- [ ] Test on Retina display
- [ ] Verify async behavior

## Success Criteria

- [ ] Fullscreen captures all displays
- [ ] Region capture shows selection UI
- [ ] Window capture detects active window
- [ ] Captures complete in < 100ms
- [ ] Retina scaling handled correctly
- [ ] No UI blocking during capture
- [ ] Memory usage < 100MB for 4K capture

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Permission denial | High | Request permissions on first launch |
| Region selection UX | Medium | Test with users, add cancel option |
| Multi-display coords | Medium | Use NSScreen coordinate conversion |
| Large image memory | Low | Downsample if needed |

## Security Considerations

- Screen Recording permission required
- No sensitive data logged
- Images stored in memory only until export
- Clear clipboard after paste

## Next Steps

Proceed to **Phase 03 - Annotation Canvas** once:
- All three capture modes functional
- Region selection UX validated
- Multi-display tested
