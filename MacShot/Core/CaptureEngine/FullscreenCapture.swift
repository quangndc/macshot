// FullscreenCapture.swift - Fullscreen screenshot capture
// Part of Phase 02 - Capture Engine

import AppKit
import CoreGraphics

/// Handles fullscreen screenshot capture
enum FullscreenCapture {
    /// Capture the main display
    @available(macOS 15.0, *)
    static func capture() async throws -> CaptureResult {
        guard let screen = NSScreen.main else {
            throw CaptureError.noScreenAvailable
        }

        let frame = screen.frame
        let scale = screen.backingScaleFactor
        let displayID = CGMainDisplayID()

        // Use ScreenCaptureKit for macOS 15+
        let cgImage = try await ScreenCaptureHelper.captureFullscreen(displayID: displayID)
        let image = NSImage(cgImage: cgImage, size: frame.size)

        let metadata = CaptureMetadata(
            displayID: displayID,
            bounds: frame,
            scaleFactor: Double(scale)
        )

        return CaptureResult(
            image: image,
            mode: .fullscreen,
            metadata: metadata
        )
    }
}

/// Capture-related errors
enum CaptureError: Error, LocalizedError {
    case noScreenAvailable
    case captureFailed
    case regionSelectionCancelled
    case windowNotFound

    var errorDescription: String? {
        switch self {
        case .noScreenAvailable: return "No screen available for capture"
        case .captureFailed: return "Failed to capture screenshot"
        case .regionSelectionCancelled: return "Region selection was cancelled"
        case .windowNotFound: return "Window not found or no longer available"
        }
    }
}
