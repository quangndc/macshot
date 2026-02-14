// PropertiesPanel.swift - Right panel with style controls
// Part of Phase 05 - Editor UI

import SwiftUI

/// Properties panel for adjusting tool styles
struct PropertiesPanel: View {
    // MARK: - Properties

    @Bindable var viewModel: EditorViewModel

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Properties")
                .font(.headline)
                .padding(.horizontal)

            Divider()

            // Stroke color
            VStack(alignment: .leading, spacing: 4) {
                Text("Stroke")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ColorPicker("", selection: $viewModel.selectedColor)
                    .labelsHidden()
            }
            .padding(.horizontal)

            // Fill color
            VStack(alignment: .leading, spacing: 4) {
                Text("Fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    ColorPicker("", selection: Binding(
                        get: { viewModel.selectedFill ?? .clear },
                        set: { viewModel.selectedFill = $0 == .clear ? nil : $0 }
                    ))
                    .labelsHidden()

                    Button {
                        viewModel.selectedFill = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove Fill")
                }
            }
            .padding(.horizontal)

            Divider()

            // Stroke width
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Stroke Width")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(viewModel.strokeWidth))px")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: $viewModel.strokeWidth,
                    in: 0.5...20,
                    step: 0.5
                )
            }
            .padding(.horizontal)

            // Opacity
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Opacity")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(viewModel.opacity * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: $viewModel.opacity,
                    in: 0.1...1.0,
                    step: 0.05
                )
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    PropertiesPanel(viewModel: viewModel)
        .frame(width: 220)
        .background(.ultraThinMaterial)
}
