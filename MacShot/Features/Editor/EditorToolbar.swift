// EditorToolbar.swift - Toolbar with tool selection buttons
// Part of Phase 05 - Editor UI

import SwiftUI

/// Toolbar component with tool buttons and export action
struct EditorToolbar: View {
    // MARK: - Properties

    @Bindable var viewModel: EditorViewModel

    /// Action callback for fullscreen toggle
    let onToggleFullscreen: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            // Tool selection buttons
            ForEach(ToolType.allCases) { tool in
                ToolButton(
                    tool: tool,
                    isSelected: viewModel.selectedTool == tool,
                    action: { viewModel.selectTool(tool) }
                )
            }

            Spacer()

            // Quick color presets
            HStack(spacing: 4) {
                ForEach(ColorPreset.allCases) { preset in
                    ColorPresetButton(preset: preset) {
                        viewModel.applyPreset(preset)
                    }
                }
            }
            .padding(.horizontal, 8)

            Divider()
                .frame(height: 24)

            // Action buttons
            Button {
                viewModel.toggleProperties()
            } label: {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .help("Toggle Properties Panel")
            .buttonStyle(.plain)

            Button {
                viewModel.toggleToolbar()
            } label: {
                Image(systemName: "toolbar")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .help("Toggle Toolbar")
            .buttonStyle(.plain)

            Button {
                onToggleFullscreen()
            } label: {
                Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .help("Toggle Fullscreen")
            .buttonStyle(.plain)

            Divider()
                .frame(height: 24)

            ExportButton(viewModel: viewModel)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Color Preset Button

struct ColorPresetButton: View {
    let preset: ColorPreset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(preset.color)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help("\(preset.displayName) Preset")
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

    EditorToolbar(viewModel: viewModel) {
        print("Fullscreen toggled")
    }
    .frame(height: 44)
    .background(.ultraThinMaterial)
}
