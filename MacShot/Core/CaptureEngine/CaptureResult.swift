// CaptureResult.swift - Result wrapper with screenshot metadata
// Part of Phase 02 - Capture Engine

import AppKit
import CoreGraphics

/// Metadata associated with a screenshot capture
struct CaptureMetadata: Sendable {
    /// Timestamp when capture was taken
    let timestamp: Date

    /// Display ID where capture originated (main display for fullscreen/window)
    let displayID: CGDirectDisplayID

    /// Bounds of the captured area in screen coordinates
    let bounds: CGRect

    /// Backing scale factor (2.0 for Retina, 1.0 for standard)
    let scaleFactor: Double

    /// Window ID if capturing a specific window
    let windowID: CGWindowID?

    init(displayID: CGDirectDisplayID, bounds: CGRect, scaleFactor: Double = 1.0, windowID: CGWindowID? = nil) {
        self.timestamp = Date()
        self.displayID = displayID
        self.bounds = bounds
        self.scaleFactor = scaleFactor
        self.windowID = windowID
    }
}

/// Result of a screenshot capture operation
struct CaptureResult: Sendable {
    /// The captured image
    let image: NSImage

    /// Capture mode used
    let mode: CaptureMode

    /// Capture metadata
    let metadata: CaptureMetadata

    init(image: NSImage, mode: CaptureMode, metadata: CaptureMetadata) {
        self.image = image
        self.mode = mode
        self.metadata = metadata
    }
}
