// FullscreenCapture.swift - Fullscreen screenshot capture
// Part of Phase 02 - Capture Engine

import AppKit
import CoreGraphics

/// Handles fullscreen screenshot capture
enum FullscreenCapture {
    /// Capture a specific display (defaults to main)
    @available(macOS 15.0, *)
    static func capture(displayID: CGDirectDisplayID? = nil, configuration: CaptureConfiguration = .default) async throws -> CaptureResult {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            throw CaptureError.displayNotFound
        }

        // Prefer main display, fallback to any available
        let targetScreen: NSScreen
        let targetDisplayID: CGDirectDisplayID

        if let displayID = displayID {
            // Find screen by display ID
            if let screen = screens.first(where: { screen in
                let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? Int
                return screenNumber == Int(displayID)
            }) {
                targetScreen = screen
                targetDisplayID = displayID
            } else {
                throw CaptureError.displayNotFound
            }
        } else {
            // Fallback to main or first available
            targetScreen = NSScreen.main ?? screens.first!
            targetDisplayID = CGMainDisplayID()
        }

        let frame = targetScreen.frame
        let scale = targetScreen.backingScaleFactor

        // Use ScreenCaptureKit for macOS 15+
        let cgImage = try await ScreenCaptureHelper.captureFullscreen(displayID: targetDisplayID, configuration: configuration)
        let image = NSImage(cgImage: cgImage, size: frame.size)

        let metadata = CaptureMetadata(
            displayID: targetDisplayID,
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
    case permissionDenied
    case captureInProgress
    case displayNotFound
    case invalidRegion(CGRect)
    case regionTooSmall(minSize: CGSize)
    case windowOffScreen

    var errorDescription: String? {
        switch self {
        case .noScreenAvailable: return "No screen available for capture"
        case .captureFailed: return "Failed to capture screenshot"
        case .regionSelectionCancelled: return "Region selection was cancelled"
        case .windowNotFound: return "Window not found or no longer available"
        case .permissionDenied: return "Screen recording permission denied. Please grant permission in System Settings > Privacy & Security > Screen Recording"
        case .captureInProgress: return "A capture operation is already in progress"
        case .displayNotFound: return "Display not found"
        case .invalidRegion(let rect): return "Invalid capture region: \(rect)"
        case .regionTooSmall(let size): return "Region too small. Minimum size: \(size.width) x \(size.height)"
        case .windowOffScreen: return "Window is off-screen"
        }
    }
}
