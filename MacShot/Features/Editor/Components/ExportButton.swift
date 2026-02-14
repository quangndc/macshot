// ExportButton.swift - Export/save action button
// Part of Phase 06 - Export System

import SwiftUI
import AppKit

/// Button component for exporting the edited screenshot
struct ExportButton: View {
    // MARK: - Properties

    @Bindable var viewModel: EditorViewModel

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            // Quick clipboard copy
            Button {
                viewModel.copyToClipboard()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("Copy to Clipboard (Cmd+C)")

            // Export button
            Button {
                viewModel.showExportPanel = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 12))
                    Text("Export")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Export Options (Cmd+S)")
        }
        .sheet(isPresented: $viewModel.showExportPanel) {
            ExportPanel(
                viewModel: viewModel,
                cropper: viewModel.imageCropper,
                exportManager: ExportManager()
            )
        }
        .keyboardShortcut("s", modifiers: .command)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var viewModel = EditorViewModel(
        result: CaptureResult(
            image: NSImage(size: NSSize(width: 800, height: 600)),
            mode: .fullscreen,
            metadata: CaptureMetadata(
                displayID: 0,
                bounds: CGRect(x: 0, y: 0, width: 800, height: 600)
            )
        )
    )

    ExportButton(viewModel: viewModel)
        .padding()
        .background(.ultraThinMaterial)
}
