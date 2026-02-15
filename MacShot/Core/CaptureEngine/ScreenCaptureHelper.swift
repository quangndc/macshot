// ScreenCaptureHelper.swift - ScreenCaptureKit wrapper for macOS 15+
// Part of Phase 02 - Capture Engine

import AppKit
import CoreGraphics

#if os(macOS)
import ScreenCaptureKit
#endif

/// Capture configuration for cursor and quality settings
struct CaptureConfiguration {
    let includeCursor: Bool
    let ignoreWindowShadows: Bool
    let enableHighQualityCapture: Bool

    static let `default` = CaptureConfiguration(
        includeCursor: true,
        ignoreWindowShadows: true,
        enableHighQualityCapture: true
    )
}

/// Helper for using ScreenCaptureKit on macOS 15+
enum ScreenCaptureHelper {
    #if os(macOS)
    /// Simple stream delegate for ScreenCaptureKit
    private final class StreamDelegate: NSObject, SCStreamDelegate {
        func stream(_ stream: SCStream, didStopWithError error: Error) {
            // Handle stream errors
        }
    }

    /// Test capture permission by attempting to capture a single pixel
    @available(macOS 15.0, *)
    static func capturePixel(_ size: CGSize) async throws -> Void {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else {
            throw CaptureError.displayNotFound
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])

        // Use SCScreenshotManager for simpler capture
        let config = SCStreamConfiguration()
        config.sourceRect = CGRect(origin: .zero, size: size)
        config.width = 1
        config.height = 1
        config.scalesToFit = false

        // Try to capture to verify permissions
        _ = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    /// Capture a specific window using ScreenCaptureKit
    @available(macOS 15.0, *)
    static func captureWindow(windowID: CGWindowID, bounds: CGRect, configuration: CaptureConfiguration = .default) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        guard let window = content.windows.first(where: { $0.windowID == windowID }) else {
            throw CaptureError.windowNotFound
        }

        // Use SCScreenshotManager for simpler capture
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()

        config.sourceRect = bounds
        config.width = Int(bounds.width)
        config.height = Int(bounds.height)
        config.scalesToFit = false
        // Note: capturesCursor property not available in SCStreamConfiguration for SCScreenshotManager
        // Cursor inclusion is controlled at the system level

        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    /// Capture fullscreen using ScreenCaptureKit
    @available(macOS 15.0, *)
    static func captureFullscreen(displayID: CGDirectDisplayID, configuration: CaptureConfiguration = .default) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw CaptureError.displayNotFound
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()

        config.width = Int(display.width)
        config.height = Int(display.height)
        config.scalesToFit = false
        // Note: capturesCursor property not available in SCStreamConfiguration for SCScreenshotManager
        // Cursor inclusion is controlled at the system level

        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    /// Capture screen region using ScreenCaptureKit
    @available(macOS 15.0, *)
    static func captureRegion(rect: CGRect, configuration: CaptureConfiguration = .default) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

        guard let display = content.displays.first else {
            throw CaptureError.displayNotFound
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()

        config.sourceRect = rect
        config.width = Int(rect.width)
        config.height = Int(rect.height)
        config.scalesToFit = false
        // Note: capturesCursor property not available in SCStreamConfiguration for SCScreenshotManager
        // Cursor inclusion is controlled at the system level

        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }
    #endif
}
