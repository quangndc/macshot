// EditorView.swift - Main editor UI layout
// Part of Phase 05 - Editor UI

import SwiftUI
import AppKit

/// Root SwiftUI view for the MacShot editor interface
struct EditorView: View {
    // MARK: - Properties

    /// The capture result being edited
    let result: CaptureResult

    /// Reference to the native window for fullscreen control
    weak var window: NSWindow?

    // MARK: - State

    @State private var viewModel: EditorViewModel

    // MARK: - Initialization

    /// Create editor view with capture result
    /// - Parameters:
    ///   - result: The screenshot capture result to edit
    ///   - window: The native window (optional, for fullscreen toggle)
    init(result: CaptureResult, window: NSWindow? = nil) {
        self.result = result
        self.window = window
        self._viewModel = State(initialValue: EditorViewModel(result: result))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar at top
            if viewModel.showToolbar {
                EditorToolbar(
                    viewModel: viewModel,
                    onToggleFullscreen: { window?.toggleFullScreen(nil) }
                )
                .frame(height: 44)
                .background(.ultraThinMaterial)
            }

            // Main content area
            HStack(spacing: 0) {
                // Canvas area
                CanvasContainer(result: result, viewModel: viewModel)

                // Properties panel on right
                if viewModel.showProperties {
                    Divider()
                    PropertiesPanel(viewModel: viewModel)
                        .frame(width: 220)
                        .background(.ultraThinMaterial)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Preview

#Preview {
    let result = CaptureResult(
        image: NSImage(size: NSSize(width: 800, height: 600)),
        mode: .fullscreen,
        metadata: CaptureMetadata(
            displayID: 0,
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600)
        )
    )

    EditorView(result: result)
}
