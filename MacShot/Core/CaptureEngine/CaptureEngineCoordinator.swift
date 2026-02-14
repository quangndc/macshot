// CaptureEngineCoordinator.swift - Main capture engine coordinator
// Part of Phase 02 - Capture Engine

import AppKit
import CoreGraphics

/// Main capture engine that coordinates all capture operations
@MainActor
final class CaptureEngine: ObservableObject {
    /// Latest captured image
    @Published var capturedImage: NSImage?

    /// Whether a capture operation is in progress
    @Published var isCapturing = false

    /// Whether to include cursor in screenshots
    var includeCursor = true

    /// Capture screenshot using the specified mode
    @available(macOS 15.0, *)
    func capture(mode: CaptureMode) async throws -> CaptureResult {
        isCapturing = true
        defer { isCapturing = false }

        let result: CaptureResult

        switch mode {
        case .fullscreen:
            result = try await FullscreenCapture.capture()

        case .region(let rect):
            if rect.isNull {
                // Show selection UI if no rect provided
                result = try await RegionCapture.captureWithSelection()
            } else {
                result = try await RegionCapture.captureAsync(rect: rect)
            }

        case .window(let windowID):
            result = try await WindowCapture.capture(windowID: windowID)
        }

        // Update published image
        capturedImage = result.image

        return result
    }

    /// Quick fullscreen capture
    @available(macOS 15.0, *)
    func captureFullscreen() async throws -> CaptureResult {
        try await capture(mode: .fullscreen)
    }

    /// Quick region capture with selection UI
    @available(macOS 15.0, *)
    func captureRegion() async throws -> CaptureResult {
        try await capture(mode: .region(rect: .null))
    }

    /// Quick window capture
    @available(macOS 15.0, *)
    func captureWindow(windowID: CGWindowID) async throws -> CaptureResult {
        try await capture(mode: .window(windowID: windowID))
    }
}
