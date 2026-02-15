# Phase 02: Capture Engine Robustness

**Priority:** HIGH
**Status:** Pending
**Estimated Complexity:** High

---

## Overview

Fix capture engine edge cases related to display management, permissions, and region validation. These fixes ensure the core screenshot functionality works reliably in all scenarios.

---

## Issues to Fix

### 1. Permission Checking Before Capture

**Problem:** No permission validation before capture operations
**Location:** All capture files in `Core/CaptureEngine/`

**Impact:**
- Crashes when permissions denied
- Poor user experience
- No graceful fallback

**Solution:**
```swift
// Add to ScreenCaptureHelper.swift
@MainActor
enum ScreenRecordingPermission {
    case authorized
    case denied
    case notDetermined

    static var current: ScreenRecordingPermission {
        // macOS doesn't provide a direct API to check screen recording permission
        // The only way to know is by attempting capture
        return .notDetermined
    }
}

// Add to CaptureEngineCoordinator.swift
@MainActor
final class CaptureEngine: ObservableObject {
    // Existing code...

    private func checkPermissions() async throws {
        // Attempt a small test capture to verify permissions
        let testResult: Result<Void, Error> = await Task {
            let testSize = CGSize(width: 1, height: 1)
            // Try to capture a single pixel
            return try await ScreenCaptureHelper.capturePixel(testSize)
        }.value

        switch testResult {
        case .success:
            break // Permission granted
        case .failure(let error):
            throw CaptureError.permissionDenied
        }
    }

    func capture(mode: CaptureMode) async throws -> CaptureResult {
        // Check permissions first
        try await checkPermissions()

        // Guard against concurrent captures
        guard !isCapturing else {
            throw CaptureError.captureInProgress
        }

        isCapturing = true
        defer { isCapturing = false }

        // Continue with capture...
    }
}

// Add to ScreenCaptureHelper.swift
static func capturePixel(_ size: CGSize) async throws -> Void {
    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    guard let display = content.displays.first else {
        throw CaptureError.displayNotFound
    }

    let filter = SCStreamConfiguration()
    filter.sourceRect = CGRect(origin: .zero, size: size)
    filter.width = 1
    filter.height = 1

    // Create and start a temporary stream
    let config = SCStreamConfiguration()
    config.capturesAudio = false

    let stream = SCStream(configuration: config, delegate: nil)
    try await stream.addStreamContentFilter(filter)
    try await stream.startCapture()
    try await stream.stopCapture()
}
```

**Files:**
- MODIFY: `MacShot/Core/CaptureEngine/CaptureEngineCoordinator.swift`
- MODIFY: `MacShot/Core/CaptureEngine/ScreenCaptureHelper.swift`

**Testing:**
- Capture with no permissions
- Capture after permission granted
- Capture after permission revoked

---

### 2. Display Disconnection Handling

**Problem:** No handling for display disconnection during capture
**Location:** `FullscreenCapture.swift`, `RegionCapture.swift`

**Impact:**
- Crashes when display unplugged mid-capture
- No fallback to secondary displays

**Solution:**
```swift
// Add to FullscreenCapture.swift
@MainActor
final class FullscreenCapture {
    static func capture() async throws -> CaptureResult {
        // Get all available displays
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            throw CaptureError.displayNotFound
        }

        // Prefer main display, fallback to any available
        let targetScreen = NSScreen.main ?? screens.first!

        // Register for display changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Handle display configuration changes
            self?.handleDisplayChange()
        }

        // Continue with capture using targetScreen
        // ... existing capture code ...
    }

    private func handleDisplayChange() {
        // Cancel in-progress captures
        // Warn user about display changes
    }
}

// Add display monitoring to CaptureEngineCoordinator.swift
@MainActor
final class CaptureEngine: ObservableObject {
    private var displayChangeObserver: NSObjectProtocol?

    init() {
        super.init()
        setupDisplayMonitoring()
    }

    private func setupDisplayMonitoring() {
        displayChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.cancelInProgressCapture()
            }
        }
    }

    private func cancelInProgressCapture() {
        guard isCapturing else { return }
        // Cancel capture and notify user
        isCapturing = false
        // Show notification: "Display configuration changed, capture cancelled"
    }

    deinit {
        if let observer = displayChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/CaptureEngine/FullscreenCapture.swift`
- MODIFY: `MacShot/Core/CaptureEngine/RegionCapture.swift`
- MODIFY: `MacShot/Core/CaptureEngine/CaptureEngineCoordinator.swift`

**Testing:**
- Unplug display during capture
- Change display resolution during capture
- Multi-display to single-display transition

---

### 3. Multiple Display Support

**Problem:** Only supports main display via `NSScreen.main` or `CGMainDisplayID()`
**Location:** All capture files

**Impact:**
- Cannot capture secondary displays
- Incorrect capture in multi-display setups

**Solution:**
```swift
// Add to CaptureMode.swift
enum CaptureMode: Equatable {
    case fullscreen
    case fullscreen(displayID: CGDirectDisplayID)  // NEW: Specific display
    case region(rect: CGRect)
    case window(windowID: CGWindowID)
}

// Add to FullscreenCapture.swift
@MainActor
final class FullscreenCapture {
    static func capture(displayID: CGDirectDisplayID? = nil) async throws -> CaptureResult {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            throw CaptureError.displayNotFound
        }

        let targetScreen: NSScreen
        if let displayID = displayID {
            // Find screen by display ID
            guard let screen = screens.first(where: { screen in
                // Match displayID to screen
                screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? Int == Int(displayID)
            }) else {
                throw CaptureError.displayNotFound
            }
            targetScreen = screen
        } else {
            // Fallback to main or first available
            targetScreen = NSScreen.main ?? screens.first!
        }

        // Continue with capture using targetScreen
        // ... existing capture code ...
    }
}

// Add display selection to CaptureEngineCoordinator.swift
@MainActor
final class CaptureEngine: ObservableObject {
    func captureFullscreen(displayID: CGDirectDisplayID? = nil) async throws -> CaptureResult {
        try await checkPermissions()
        guard !isCapturing else { throw CaptureError.captureInProgress }

        isCapturing = true
        defer { isCapturing = false }

        return try await FullscreenCapture.capture(displayID: displayID)
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/CaptureEngine/CaptureMode.swift`
- MODIFY: `MacShot/Core/CaptureEngine/FullscreenCapture.swift`
- MODIFY: `MacShot/Core/CaptureEngine/CaptureEngineCoordinator.swift`

**Testing:**
- Capture each display individually
- Capture with display disconnected
- Display ID validation

---

### 4. Invalid Region Bounds Validation

**Problem:** No explicit validation for region coordinates
**Location:** `RegionCapture.swift`

**Impact:**
- Could accept invalid coordinates
- Crashes or undefined behavior

**Solution:**
```swift
// Add to RegionCapture.swift
extension CGRect {
    func isValidForScreen(_ screen: NSScreen? = nil) -> Bool {
        // Must have positive dimensions
        guard width > 0 && height > 0 else { return false }

        // Must not be infinite or NaN
        guard isInfinite == false && isNaN == false else { return false }

        // Check against screen bounds if provided
        if let screen = screen {
            let screenBounds = screen.frame
            // Can extend beyond screen (negative, etc.) but must be valid rect
            return !isEmpty
        }

        return !isEmpty
    }
}

@MainActor
final class RegionCapture {
    static func captureAsync(rect: CGRect) async throws -> CaptureResult {
        // Validate region bounds
        guard rect.isValidForScreen() else {
            throw CaptureError.invalidRegion(rect)
        }

        // Additional validation
        guard rect.width >= 10 && rect.height >= 10 else {
            throw CaptureError.regionTooSmall(minSize: CGSize(width: 10, height: 10))
        }

        // Continue with capture...
    }
}

// Add to CaptureError enum
enum CaptureError: Error, LocalizedError {
    case invalidRegion(CGRect)
    case regionTooSmall(minSize: CGSize)

    var errorDescription: String? {
        switch self {
        case .invalidRegion(let rect):
            "Invalid capture region: \(rect)"
        case .regionTooSmall(let size):
            "Region too small. Minimum size: \(size.width) x \(size.height)"
        // ... existing cases ...
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/CaptureEngine/RegionCapture.swift`
- MODIFY: `MacShot/Features/Capture/RegionSelectionOverlay.swift` (validation during selection)

**Testing:**
- Negative coordinates
- Zero width/height
- Infinite/NaN values
- Very small regions

---

### 5. Display Configuration Changes

**Problem:** No detection of display layout changes during region selection
**Location:** `RegionSelectionOverlay.swift`

**Impact:**
- Incorrect selection bounds if displays rearranged
- User could select invalid region

**Solution:**
```swift
// Add to RegionSelectionOverlay.swift
struct RegionSelectionOverlay: View {
    @State private var currentDisplayConfiguration: String = UUID().uuidString
    @State private var isValidConfiguration = true

    var body: some View {
        // ... existing UI ...

        .onReceive(NotificationCenter.default.publisher(
            for: NSApplication.didChangeScreenParametersNotification
        )) { _ in
            // Invalidate current selection
            currentDisplayConfiguration = UUID().uuidString
            isValidConfiguration = false

            // Notify user
            showDisplayChangedWarning()
        }
    }

    private func showDisplayChangedWarning() {
        // Show alert or notification
        // Optionally cancel selection or re-validate bounds
    }
}
```

**Files:**
- MODIFY: `MacShot/Features/Capture/RegionSelectionOverlay.swift`

**Testing:**
- Change resolution during selection
- Add/remove display during selection
- Reconfigure displays during selection

---

### 6. Window Race Conditions

**Problem:** Window could disappear between bounds query and capture
**Location:** `WindowCapture.swift`

**Impact:**
- Capture fails with stale window ID
- Poor user experience

**Solution:**
```swift
// Add to WindowCapture.swift
@MainActor
final class WindowCapture {
    static func capture(windowID: CGWindowID) async throws -> CaptureResult {
        // Atomic check: verify window still exists AND is captureable
        guard let windowInfo = CGWindowListCopyWindowInfo(
            .optionIncludingWindow,
            windowID
        ) as? [[String: AnyObject]],
              let info = windowInfo.first,
              let bounds = getBounds(from: info),
              let layer = info[kCGWindowLayer as String] as? Int,
              let alpha = info[kCGWindowAlpha as String] as? Double,
              alpha > 0,  // Visible
              layer >= 0     // On-screen
        else {
            throw CaptureError.windowNotFound
        }

        // Additional checks
        guard isWindowOnScreen(bounds) else {
            throw CaptureError.windowOffScreen
        }

        // Proceed with capture immediately
        // ... existing capture code ...
    }

    private func isWindowOnScreen(_ bounds: CGRect) -> Bool {
        // Check if window bounds intersect any screen
        NSScreen.screens.contains { screen in
            screen.frame.intersects(bounds)
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/CaptureEngine/WindowCapture.swift`

**Testing:**
- Close window immediately after trigger
- Minimize window during capture
- Move window off-screen

---

### 7. Cursor Inclusion Implementation

**Problem:** `includeCursor` property exists but not used
**Location:** `CaptureEngineCoordinator.swift`

**Impact:**
- User setting ignored
- Cannot control cursor capture

**Solution:**
```swift
// Add to ScreenCaptureHelper.swift
struct CaptureConfiguration {
    let includeCursor: Bool
    let ignoreWindowShadows: Bool
    let enableHighQualityCapture: Bool
}

static func captureDisplay(_ displayID: CGDirectDisplayID, configuration: CaptureConfiguration = .default) async throws -> CaptureResult {
    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

    guard let filter = SCContentFilter(display: content.displays.first(where: { $0.displayID == displayID })) else {
        throw CaptureError.displayNotFound
    }

    let config = SCStreamConfiguration()
    config.capturesAudio = false

    // Configure cursor capture
    config.capturesCursor = configuration.includeCursor

    let stream = SCStream(configuration: config, delegate: nil)
    try await stream.addStreamContentFilter(filter)
    try await stream.startCapture()

    // ... rest of capture logic ...
}

// Update CaptureEngineCoordinator.swift
@MainActor
final class CaptureEngine: ObservableObject {
    var includeCursor = true  // Already exists, now use it

    func captureFullscreen() async throws -> CaptureResult {
        let config = ScreenCaptureHelper.CaptureConfiguration(
            includeCursor: includeCursor,
            ignoreWindowShadows: true,
            enableHighQualityCapture: true
        )

        return try await FullscreenCapture.capture(configuration: config)
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/CaptureEngine/CaptureEngineCoordinator.swift`
- MODIFY: `MacShot/Core/CaptureEngine/ScreenCaptureHelper.swift`
- MODIFY: `MacShot/Core/CaptureEngine/FullscreenCapture.swift`

**Testing:**
- Capture with cursor on
- Capture with cursor off
- Cursor on secondary display

---

## Success Criteria

- [ ] Permission check before all capture operations
- [ ] Display disconnection properly handled
- [ ] All displays can be captured (not just main)
- [ ] Region bounds validated before capture
- [ ] Display configuration changes detected
- [ ] Window capture atomic and safe
- [ ] Cursor inclusion functional
- [ ] All capture edge cases tested

---

## Next Steps

After completing this phase:
1. Move to [Phase 03: Settings System Validation](./phase-03-settings-fixes.md)
2. Update capture engine tests
3. Verify multi-display scenarios

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Permission check false positives | Medium | Test with various permission states |
| Display monitoring performance | Low | Debounce display change notifications |
| Region validation rejects valid cases | Medium | Comprehensive bounds testing |
