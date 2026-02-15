// WindowCapture.swift - Window detection and screenshot capture
// Part of Phase 02 - Capture Engine

import AppKit
import CoreGraphics

/// Handles window-based screenshot capture
enum WindowCapture {
    /// Capture a specific window by its window ID
    @available(macOS 15.0, *)
    static func capture(windowID: CGWindowID, configuration: CaptureConfiguration = .default) async throws -> CaptureResult {
        // Atomic check: verify window still exists AND is captureable
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionIncludingWindow],
            windowID
        ) as? [[String: Any]],
              let windowInfo = windowList.first,
              let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any],
              let bounds = CGRect(dictionary: boundsDict) as CGRect?,
              let layer = windowInfo[kCGWindowLayer as String] as? Int,
              let alpha = windowInfo[kCGWindowAlpha as String] as? Double,
              alpha > 0,  // Visible
              layer >= 0     // On-screen
        else {
            throw CaptureError.windowNotFound
        }

        // Additional check: window on screen
        guard isWindowOnScreen(bounds) else {
            throw CaptureError.windowOffScreen
        }

        // Capture using ScreenCaptureKit
        let cgImage = try await ScreenCaptureHelper.captureWindow(windowID: windowID, bounds: bounds, configuration: configuration)
        let image = NSImage(cgImage: cgImage, size: bounds.size)

        let metadata = CaptureMetadata(
            displayID: CGMainDisplayID(),
            bounds: bounds,
            scaleFactor: Double(NSScreen.main?.backingScaleFactor ?? 2.0),
            windowID: windowID
        )

        return CaptureResult(
            image: image,
            mode: .window(windowID: windowID),
            metadata: metadata
        )
    }

    /// Check if window bounds intersect any screen
    private static func isWindowOnScreen(_ bounds: CGRect) -> Bool {
        NSScreen.screens.contains { screen in
            screen.frame.intersects(bounds)
        }
    }

    /// Get list of visible windows for selection
    static func getVisibleWindows() -> [WindowInfo] {
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        return windowList.compactMap { info in
            guard let windowID = info[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let ownerName = info[kCGWindowOwnerName as String] as? String else {
                return nil
            }

            let bounds = CGRect(dictionary: boundsDict)
            let title = info[kCGWindowName as String] as? String ?? ""

            return WindowInfo(
                windowID: windowID,
                title: title.isEmpty ? ownerName : "\(ownerName) — \(title)",
                owner: ownerName,
                bounds: bounds
            )
        }
    }
}

/// Information about a discoverable window
struct WindowInfo {
    let windowID: CGWindowID
    let title: String
    let owner: String
    let bounds: CGRect
}

/// CGRect extension for creating from dictionary
extension CGRect {
    init(dictionary: [String: Any]) {
        let x = (dictionary["X"] as? CGFloat) ?? 0
        let y = (dictionary["Y"] as? CGFloat) ?? 0
        let width = (dictionary["Width"] as? CGFloat) ?? 0
        let height = (dictionary["Height"] as? CGFloat) ?? 0
        self.init(x: x, y: y, width: width, height: height)
    }
}
