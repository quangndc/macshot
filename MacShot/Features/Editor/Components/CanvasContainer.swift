// CanvasContainer.swift - Wrapper for AnnotationCanvas with scrolling
// Part of Phase 05 - Editor UI

import SwiftUI

/// Container view for the annotation canvas with scroll support
struct CanvasContainer: View {
    // MARK: - Properties

    let result: CaptureResult
    @Bindable var viewModel: EditorViewModel

    // MARK: - State

    @State private var zoomScale: CGFloat = 1.0
    @State private var dragOffset: CGPoint = .zero

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                AnnotationCanvas(
                    backgroundImage: result.image,
                    toolManager: viewModel.toolManagerAccessor
                )
                .frame(
                    width: CGFloat(result.image.size.width),
                    height: CGFloat(result.image.size.height)
                )
                .scaleEffect(zoomScale)
                .offset(x: dragOffset.x, y: dragOffset.y)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .onAppear {
                // Center canvas initially
                centerCanvas(in: geometry.size)
            }
        }
    }

    // MARK: - Helpers

    private func centerCanvas(in containerSize: CGSize) {
        let imageSize = CGSize(
            width: CGFloat(result.image.size.width),
            height: CGFloat(result.image.size.height)
        )

        // Calculate offset to center image
        let offsetX = max(0, (containerSize.width - imageSize.width) / 2)
        let offsetY = max(0, (containerSize.height - imageSize.height) / 2)

        dragOffset = CGPoint(x: offsetX, y: offsetY)
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

    CanvasContainer(result: viewModel.captureResult, viewModel: viewModel)
        .frame(width: 800, height: 600)
}
