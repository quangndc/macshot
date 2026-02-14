// EditorWindow.swift - Main editor window wrapper
// Part of Phase 05 - Editor UI

import AppKit
import SwiftUI

/// Native NSWindow for the MacShot editor interface
final class EditorWindow: NSWindow {
    // MARK: - Properties

    private let captureResult: CaptureResult

    // MARK: - Initialization

    /// Create editor window with captured screenshot
    /// - Parameter captureResult: The screenshot capture result to edit
    init(captureResult: CaptureResult) {
        self.captureResult = captureResult

        // Calculate initial window size based on image
        let imageSize = captureResult.image.size
        let windowWidth = max(800, CGFloat(imageSize.width))
        let windowHeight = max(600, CGFloat(imageSize.height))

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        setupWindow()
    }

    // MARK: - Setup

    private func setupWindow() {
        // Window title with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: captureResult.metadata.timestamp)
        title = "MacShot Editor - \(timeString)"

        // Center window on screen
        center()

        // Prevent window from being destroyed when closed
        isReleasedWhenClosed = false

        // Set minimum size
        minSize = NSSize(width: 800, height: 600)

        // Set SwiftUI content
        let editorView = EditorView(result: captureResult, window: self)
        contentView = NSHostingView(rootView: editorView)

        // Make window key and visible
        makeKeyAndOrderFront(nil)
    }

    // MARK: - Window Actions

    /// Close the editor window
    func closeEditor() {
        close()
    }

    /// Toggle fullscreen mode
    func toggleFullscreen() {
        if styleMask.contains(.fullScreen) {
            toggleFullScreen(nil)
        } else {
            toggleFullScreen(nil)
        }
    }
}

