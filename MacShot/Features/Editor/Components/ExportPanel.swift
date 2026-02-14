// ExportPanel.swift - Export options UI panel
// Part of Phase 06 - Export System

import SwiftUI
import AppKit

/// Export options panel with format, quality, and destination controls
struct ExportPanel: View {
    @Bindable var viewModel: EditorViewModel
    @Bindable var cropper: ImageCropper
    @ObservedObject var exportManager: ExportManager

    @State private var options = ExportOptions()
    @State private var isExporting = false
    @State private var showSuccessMessage = false
    @State private var showErrorMessage = false
    @State private var errorMessageText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Options")
                .font(.headline)
                .padding(.bottom, 4)

            Divider()

            formatPicker

            if options.format == .jpeg {
                qualitySlider
            }

            aspectRatioPicker

            clipboardToggle

            Divider()

            actionButtons
        }
        .padding(16)
        .frame(width: 280)
        .background(.ultraThinMaterial)
        .alert("Export Complete", isPresented: $showSuccessMessage) {
            Button("OK") {}
        } message: {
            Text("Image exported successfully")
        }
        .alert("Export Failed", isPresented: $showErrorMessage) {
            Button("OK") {}
        } message: {
            Text(errorMessageText)
        }
    }

    private var formatPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Format")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("", selection: $options.format) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var qualitySlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quality")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(options.jpegQuality * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $options.jpegQuality, in: 0.1...1.0)
                .controlSize(.small)
        }
    }

    private var aspectRatioPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aspect Ratio")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("", selection: Binding(
                get: { cropper.aspectRatio },
                set: { cropper.setAspectRatio($0) }
            )) {
                Text("None").tag(nil as AspectRatio?)
                ForEach(AspectRatio.allCases, id: \.self) { ratio in
                    Text(ratio.label).tag(ratio as AspectRatio?)
                }
            }
        }
    }

    private var clipboardToggle: some View {
        HStack {
            Toggle("Copy to Clipboard", isOn: $options.copyToClipboard)
            Spacer()
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Cancel", role: .cancel) {}
            .keyboardShortcut(.cancelAction)

            Button {
                performExport()
            } label: {
                if isExporting {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Exporting...")
                    }
                } else {
                    Text("Export")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting)
        }
    }

    private func performExport() {
        isExporting = true

        Task {
            do {
                let url = exportManager.quickSaveToDesktop(viewModel.captureResult.image)
                options.outputPath = url

                try await exportManager.export(
                    image: viewModel.captureResult.image,
                    options: options,
                    cropper: cropper
                )

                await MainActor.run {
                    isExporting = false
                    showSuccessMessage = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    errorMessageText = error.localizedDescription
                    showErrorMessage = true
                }
            }
        }
    }
}
