// RegionCapture.swift - Region selection and screenshot capture
// Part of Phase 02 - Capture Engine

import AppKit
import CoreGraphics

/// Handles region-based screenshot capture with UI overlay
enum RegionCapture {
    /// Show region selection UI and capture selected area
    @available(macOS 15.0, *)
    static func captureWithSelection() async throws -> CaptureResult {
        let rect = try await showRegionSelectionOverlay()
        return try await captureAsync(rect: rect)
    }

    /// Show region selection overlay and return selected rect
    @available(macOS 15.0, *)
    private static func showRegionSelectionOverlay() async throws -> CGRect {
        try await withUnsafeThrowingContinuation { continuation in
            var resumed = false

            DispatchQueue.main.async {
                let overlay = RegionSelectionOverlay { rect in
                    if !resumed {
                        resumed = true
                        continuation.resume(returning: rect)
                    }
                }

                // Handle cancellation
                NotificationCenter.default.addObserver(
                    forName: NSWindow.willCloseNotification,
                    object: overlay,
                    queue: .main
                ) { _ in
                    if !resumed {
                        resumed = true
                        continuation.resume(throwing: CaptureError.regionSelectionCancelled)
                    }
                }

                overlay.makeKeyAndOrderFront(nil)
            }
        }
    }

    /// Async capture for ScreenCaptureKit compatibility
    @available(macOS 15.0, *)
    static func captureAsync(rect: CGRect) async throws -> CaptureResult {
        guard let screen = NSScreen.main else {
            throw CaptureError.noScreenAvailable
        }

        let cgImage = try await ScreenCaptureHelper.captureRegion(rect: rect)
        let image = NSImage(cgImage: cgImage, size: rect.size)

        let metadata = CaptureMetadata(
            displayID: CGMainDisplayID(),
            bounds: rect,
            scaleFactor: Double(screen.backingScaleFactor)
        )

        return CaptureResult(
            image: image,
            mode: .region(rect: rect),
            metadata: metadata
        )
    }
}
