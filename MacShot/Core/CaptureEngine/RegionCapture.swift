// RegionCapture.swift - Region selection and screenshot capture
// Part of Phase 02 - Capture Engine

import AppKit
import CoreGraphics

/// CGRect extension for validation
extension CGRect {
    /// Validate rect for screen capture
    func isValidForScreen(_ screen: NSScreen? = nil) -> Bool {
        // Must have positive dimensions
        guard width > 0 && height > 0 else { return false }

        // Must not be infinite or NaN
        guard !isEmpty && width.isFinite && height.isFinite else { return false }

        // Check against screen bounds if provided
        if let screen = screen {
            let screenBounds = screen.frame
            // Can extend beyond screen (negative, etc.) but must be valid rect
            return !isEmpty
        }

        return !isEmpty
    }
}

/// Handles region-based screenshot capture with UI overlay
enum RegionCapture {
    /// Show region selection UI and capture selected area
    @available(macOS 15.0, *)
    static func captureWithSelection(configuration: CaptureConfiguration = .default) async throws -> CaptureResult {
        let rect = try await showRegionSelectionOverlay()
        return try await captureAsync(rect: rect, configuration: configuration)
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
    static func captureAsync(rect: CGRect, configuration: CaptureConfiguration = .default) async throws -> CaptureResult {
        // Validate region bounds
        guard rect.isValidForScreen() else {
            throw CaptureError.invalidRegion(rect)
        }

        // Additional validation for minimum size
        guard rect.width >= 10 && rect.height >= 10 else {
            throw CaptureError.regionTooSmall(minSize: CGSize(width: 10, height: 10))
        }

        guard let screen = NSScreen.main else {
            throw CaptureError.noScreenAvailable
        }

        let cgImage = try await ScreenCaptureHelper.captureRegion(rect: rect, configuration: configuration)
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
