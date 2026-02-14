# Swift/SwiftUI Screenshot Capture APIs Research for macOS 15+

## 1. CGDisplayStream and CGScreen APIs for Screen Capture

### CGDisplayStream (High-performance screen capture)
- **CGDisplayStreamCreate()**: Creates a display stream for real-time screen capture
- **kCGCaptureAsHDR**: New in macOS 15 for HDR content capture
- **kCGMinimumRect**: Captures only specified regions for performance
- **kCGCaptureAsHDR**: HDR support for compatible displays
- **kCGCaptureInScreenSpace**: Handles coordinate space correctly

```swift
let displayStream = CGDisplayStreamCreate(
    displayID: CGMainDisplayID(),
    outputWidth: 1920,
    outputHeight: 1080,
    pixelFormat: kCV32ARGB,
    properties: [
        kCGDisplayStreamShowCursor: false,
        kCGDisplayStreamStart Immediately: true
    ],
    handler: { status, time, frame, updateRef in
        // Handle frame updates
    }
)
```

### CGScreen APIs
- **CGWindowListCopyWindowInfo**: Get window information
- **CGWindowListCreateImage**: Create image from window/region
- **CGRect**: Coordinate system for screen regions

## 2. CGWindowList APIs for Window Capture

### Key Window Capture Functions
- **CGWindowListCreate**: Create image from windows
- **CGWindowListCopyWindowInfo**: Get window list and properties
- **kCGWindowListOptionOnScreenWindows**: Only visible windows
- **kCGWindowListOptionIncludingWindow**: Specific window by ID

```swift
// Get window list
let windowList = CGWindowListCopyWindowInfo(
    [.optionOnScreenWindowOnly, .optionIncludingWindow],
    CGWindowID(0)
)

// Capture specific window
let windowImage = CGWindowListCreateImage(
    CGRect.zero,
    .optionIncludingWindow,
    windowID,
    .nominalResolution
)
```

## 3. SwiftUI and AppKit Best Practices

### SwiftUI Approach
- Use **NSViewRepresentable** for native macOS integrations
- **NSImage** for image handling
- **NSWorkspace** for window management
- Combine with publishers for real-time updates

### AppKit Traditional
- **NSScreen** for display information
- **NSImage** and **NSBitmapImageRep** for image operations
- **NSView.drawRect()** for custom capture
- **CGContext** for advanced image manipulation

```swift
// SwiftUI Integration
struct ScreenCaptureView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // Setup capture logic
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Update logic
    }
}
```

## 4. Multi-Display Support Considerations

### Display Enumeration
- **NSScreen.screens**: Array of all available screens
- **CGDisplayCopyAllDisplays**: Core Graphics alternative
- **CGDirectDisplayID**: Unique identifier for each display

### Capture Strategies
- **Individual streams**: Separate capture per display
- **Unified canvas**: Combine displays into single image
- **Display-aware**: Handle different DPI and orientations

```swift
// Multi-display support
for screen in NSScreen.screens {
    let displayID = screen.displayID ?? CGMainDisplayID()
    // Setup capture for each display
}
```

## 5. DPI/Retina Display Handling

### Resolution Considerations
- **NSScreen.backingScaleFactor**: Scale factor for Retina displays
- **CGRect**: Points vs pixels coordinate system
- **NSImage**: Handles scale factor automatically
- **CGContext**: Set scale for high DPI images

```swift
// Handle Retina scaling
let scale = NSScreen.main?.backingScaleFactor ?? 1.0
let scaledRect = CGRect(
    x: rect.origin.x * scale,
    y: rect.origin.y * scale,
    width: rect.width * scale,
    height: rect.height * scale
)
```

## 6. Code Examples for Capture Modes

### Fullscreen Capture
```swift
func captureFullscreen() -> NSImage? {
    guard let screen = NSScreen.main else { return nil }
    let imageRect = screen.frame

    let image = CGWindowListCreateImage(
        imageRect,
        .optionOnScreenWindows,
        kCGNullWindowID,
        .nominalResolution
    )

    return NSImage(cgImage: image!, size: imageRect.size)
}
```

### Region Capture
```swift
func captureRegion(_ rect: CGRect) -> NSImage? {
    let displayID = CGMainDisplayID()

    let stream = CGDisplayStreamCreate(
        displayID: displayID,
        outputWidth: Int(rect.width),
        outputHeight: Int(rect.height),
        pixelFormat: kCV32ARGB,
        properties: [kCGDisplayStreamRect: rect],
        handler: { _, _, frameRef, _ in
            // Process frame
        }
    )

    // Return captured region image
}
```

### Window Capture
```swift
func captureWindow(windowID: CGWindowID) -> NSImage? {
    let windowInfo = CGWindowListCopyWindowInfo(
        [.optionIncludingWindow],
        windowID
    ).first as? [String: Any]

    guard let bounds = windowInfo?["kCGWindowBounds"] as? String,
          let windowRect = parseBoundsString(bounds) else { return nil }

    let image = CGWindowListCreateImage(
        windowRect,
        .optionIncludingWindow,
        windowID,
        .nominalResolution
    )

    return NSImage(cgImage: image!, size: windowRect.size)
}
```

## Key Documentation Sources

- [Apple Developer - Screen Capture APIs](https://developer.apple.com/documentation/coregraphics/1561698-screen_capture)
- [Apple Developer - CGDisplayStream](https://developer.apple.com/documentation/coregraphics/cgdisplaystream)
- [Apple Developer - CGWindowList](https://developer.apple.com/documentation/coregraphics/cgwindowlist)
- [Apple Developer - NSScreen](https://developer.apple.com/documentation/appkit/nsscreen)
- [WWDC 2023 - Modern Screen Capture Techniques](https://developer.apple.com/videos/play/wwdc2023/10135/)

## Performance Considerations

- Use **CGDisplayStream** for real-time capture (60fps+)
- Implement **region-specific capture** for performance optimization
- Handle **HDR content** properly on supported displays
- Consider **asynchronous capture** to avoid UI blocking
- Use **background queues** for image processing

## Unresolved Questions

1. How to handle privacy permissions for screen capture in macOS 15?
2. What are the memory management implications for high-resolution HDR capture?
3. How to implement hardware-accelerated encoding for screen streams?
4. What are the security implications of capturing system content?