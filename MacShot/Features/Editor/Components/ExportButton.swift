// ExportButton.swift - Export/save action button
// Part of Phase 05 - Editor UI

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Button component for exporting the edited screenshot
struct ExportButton: View {
    // MARK: - Properties

    @Bindable var viewModel: EditorViewModel

    // MARK: - State

    @State private var isShowingSavePanel = false

    // MARK: - Body

    var body: some View {
        Button {
            isShowingSavePanel = true
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
        .help("Export Image (Cmd+S)")
        .fileExporter(
            isPresented: $isShowingSavePanel,
            document: ExportDocument(result: viewModel.captureResult),
            contentType: .png,
            defaultFilename: generateFilename()
        ) { result in
            if case .success = result {
                print("Image exported successfully")
            }
        }
    }

    // MARK: - Helpers

    private func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return "MacShot_\(formatter.string(from: viewModel.captureResult.metadata.timestamp))"
    }
}

// MARK: - Export Document

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.png] }

    let result: CaptureResult

    init(result: CaptureResult) {
        self.result = result
    }

    init(configuration: ReadConfiguration) throws {
        fatalError("Loading not supported")
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let tiffData = result.image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "MacShot", code: 1)
        }

        return .init(regularFileWithContents: pngData)
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
