// CaptureEngineCoordinator.swift - Main capture engine coordinator
// Part of Phase 02 - Capture Engine

@preconcurrency import AppKit
import CoreGraphics

/// Callback type for capture completion
typealias CaptureCompletionCallback = (CaptureResult) -> Void

/// Main capture engine that coordinates all capture operations
@MainActor
final class CaptureEngine: ObservableObject {
    /// Latest captured image
    @Published var capturedImage: NSImage?

    /// Whether a capture operation is in progress
    @Published var isCapturing = false

    /// Whether to include cursor in screenshots
    var includeCursor = true

    /// Optional callback invoked when capture completes
    var onCaptureComplete: CaptureCompletionCallback?

    /// Display change observer
    private var displayChangeObserver: NSObjectProtocol?

    /// Initialize capture engine with display monitoring
    init() {
        setupDisplayMonitoring()
    }

    /// Setup display configuration change monitoring
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

    /// Cancel in-progress capture when display changes
    private func cancelInProgressCapture() {
        guard isCapturing else { return }
        // Cancel capture and notify user
        isCapturing = false
        // Show notification: "Display configuration changed, capture cancelled"
        // TODO: Implement user notification
    }

    /// Clean up observer
    deinit {
        if let observer = displayChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Check permissions before capture operations
    private func checkPermissions() async throws {
        // Attempt a small test capture to verify permissions
        let testSize = CGSize(width: 1, height: 1)
        do {
            _ = try await ScreenCaptureHelper.capturePixel(testSize)
        } catch {
            throw CaptureError.permissionDenied
        }
    }

    /// Capture screenshot using the specified mode
    @available(macOS 15.0, *)
    func capture(mode: CaptureMode) async throws -> CaptureResult {
        // Check permissions first
        try await checkPermissions()

        // Guard against concurrent captures
        guard !isCapturing else {
            throw CaptureError.captureInProgress
        }

        isCapturing = true
        defer { isCapturing = false }

        let config = CaptureConfiguration(
            includeCursor: includeCursor,
            ignoreWindowShadows: true,
            enableHighQualityCapture: true
        )

        let result: CaptureResult

        switch mode {
        case .fullscreen:
            result = try await FullscreenCapture.capture(configuration: config)

        case .region(let rect):
            if rect.isNull {
                // Show selection UI if no rect provided
                result = try await RegionCapture.captureWithSelection(configuration: config)
            } else {
                result = try await RegionCapture.captureAsync(rect: rect, configuration: config)
            }

        case .window(let windowID):
            result = try await WindowCapture.capture(windowID: windowID, configuration: config)
        }

        // Update published image
        capturedImage = result.image

        // Notify callback if set
        onCaptureComplete?(result)

        return result
    }

    /// Quick fullscreen capture
    @available(macOS 15.0, *)
    func captureFullscreen(displayID: CGDirectDisplayID? = nil) async throws -> CaptureResult {
        try await checkPermissions()
        guard !isCapturing else { throw CaptureError.captureInProgress }

        isCapturing = true
        defer { isCapturing = false }

        let config = CaptureConfiguration(
            includeCursor: includeCursor,
            ignoreWindowShadows: true,
            enableHighQualityCapture: true
        )

        return try await FullscreenCapture.capture(displayID: displayID, configuration: config)
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
