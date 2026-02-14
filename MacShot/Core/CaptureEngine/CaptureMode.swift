// CaptureMode.swift - Defines screenshot capture modes
// Part of Phase 02 - Capture Engine

import AppKit
import CoreGraphics

/// Screenshot capture mode
enum CaptureMode: Equatable {
    /// Capture entire screen(s)
    case fullscreen

    /// Capture a specific screen region with rect bounds
    case region(rect: CGRect)

    /// Capture a specific window by its ID
    case window(windowID: CGWindowID)

    /// Equatable conformance for comparison
    static func == (lhs: CaptureMode, rhs: CaptureMode) -> Bool {
        switch (lhs, rhs) {
        case (.fullscreen, .fullscreen):
            return true
        case (.region(let lRect), .region(let rRect)):
            return lRect == rRect
        case (.window(let lID), .window(let rID)):
            return lID == rID
        default:
            return false
        }
    }
}
