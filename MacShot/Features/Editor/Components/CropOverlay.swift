// CropOverlay.swift - Non-destructive crop overlay UI
// Part of Phase 06 - Export System

import SwiftUI
import AppKit

/// Visual overlay for image cropping with drag handles
struct CropOverlay: View {
    // MARK: - Properties

    @Bindable var cropper: ImageCropper
    var imageSize: CGSize

    // MARK: - State

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var activeHandle: CropHandle?
    @State private var dragStartPoint: CGPoint = .zero
    @State private var dragStartRect: CGRect = .zero

    // MARK: - Constants

    private let handleSize: CGFloat = 12
    private let minCropSize: CGFloat = 50

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed overlay outside crop area
                dimmedOverlay(in: geometry.size)

                // Crop rectangle border
                if let cropRect = cropper.cropRect {
                    cropBorderView(cropRect, containerSize: geometry.size)
                }

                // Drag handles
                if let cropRect = cropper.cropRect {
                    cropHandlesView(cropRect, containerSize: geometry.size)
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleDragChanged(value, containerSize: imageSize)
                }
                .onEnded { _ in
                    handleDragEnded()
                }
        )
    }

    // MARK: - Dimmed Overlay

    @ViewBuilder
    private func dimmedOverlay(in size: CGSize) -> some View {
        if let cropRect = cropper.cropRect {
            // Create a mask effect by drawing four rectangles around the crop
            ZStack {
                // Top
                Rectangle()
                    .fill(.black.opacity(0.5))
                    .frame(height: cropRect.minY)

                // Bottom
                Rectangle()
                    .fill(.black.opacity(0.5))
                    .frame(height: size.height - cropRect.maxY)
                    .offset(y: cropRect.maxY)

                // Left
                Rectangle()
                    .fill(.black.opacity(0.5))
                    .frame(width: cropRect.minX)
                    .offset(y: cropRect.minY)
                    .frame(height: cropRect.height)

                // Right
                Rectangle()
                    .fill(.black.opacity(0.5))
                    .frame(width: size.width - cropRect.maxX)
                    .offset(x: cropRect.maxX, y: cropRect.minY)
                    .frame(height: cropRect.height)
            }
        }
    }

    // MARK: - Crop Border

    @ViewBuilder
    private func cropBorderView(_ rect: CGRect, containerSize: CGSize) -> some View {
        Rectangle()
            .stroke(.white, lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
    }

    // MARK: - Crop Handles

    @ViewBuilder
    private func cropHandlesView(_ rect: CGRect, containerSize: CGSize) -> some View {
        ZStack {
            // Corner handles
            handleView(at: .topLeft, of: rect)
            handleView(at: .topRight, of: rect)
            handleView(at: .bottomLeft, of: rect)
            handleView(at: .bottomRight, of: rect)

            // Edge handles
            handleView(at: .top, of: rect)
            handleView(at: .bottom, of: rect)
            handleView(at: .left, of: rect)
            handleView(at: .right, of: rect)
        }
    }

    @ViewBuilder
    private func handleView(at handle: CropHandle, of rect: CGRect) -> some View {
        let position = handlePosition(for: handle, in: rect)

        Circle()
            .fill(.white)
            .frame(width: handleSize, height: handleSize)
            .overlay(
                Circle()
                    .stroke(.black, lineWidth: 1)
            )
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleResizeDrag(handle, value: value)
                    }
                    .onEnded { _ in
                        activeHandle = nil
                    }
            )
    }

    // MARK: - Handle Positions

    private func handlePosition(for handle: CropHandle, in rect: CGRect) -> CGPoint {
        switch handle {
        case .topLeft:
            return CGPoint(x: rect.minX, y: rect.minY)
        case .topRight:
            return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft:
            return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight:
            return CGPoint(x: rect.maxX, y: rect.maxY)
        case .top:
            return CGPoint(x: rect.midX, y: rect.minY)
        case .bottom:
            return CGPoint(x: rect.midX, y: rect.maxY)
        case .left:
            return CGPoint(x: rect.minX, y: rect.midY)
        case .right:
            return CGPoint(x: rect.maxX, y: rect.midY)
        case .center:
            return CGPoint(x: rect.midX, y: rect.midY)
        }
    }

    // MARK: - Drag Gestures

    private func handleDragChanged(_ value: DragGesture.Value, containerSize: CGSize) {
        if activeHandle == nil {
            // Start new drag
            activeHandle = .center
            dragStartPoint = value.startLocation
            dragStartRect = cropper.cropRect ?? CGRect(origin: .zero, size: containerSize)
        }

        guard activeHandle == .center else { return }

        let offset = value.translation
        var newRect = dragStartRect.offsetBy(dx: offset.width, dy: offset.height)

        // Clamp to image bounds
        newRect = clampToImageBounds(newRect, imageSize: containerSize)

        cropper.setCropRect(newRect)
    }

    private func handleResizeDrag(_ handle: CropHandle, value: DragGesture.Value) {
        if activeHandle != handle {
            activeHandle = handle
            dragStartPoint = value.startLocation
            dragStartRect = cropper.cropRect ?? .zero
        }

        let translation = value.translation
        var newRect = dragStartRect

        switch handle {
        case .topLeft:
            newRect.origin.x += translation.width
            newRect.origin.y += translation.height
            newRect.size.width -= translation.width
            newRect.size.height -= translation.height

        case .topRight:
            newRect.origin.y += translation.height
            newRect.size.width += translation.width
            newRect.size.height -= translation.height

        case .bottomLeft:
            newRect.origin.x += translation.width
            newRect.size.width -= translation.width
            newRect.size.height += translation.height

        case .bottomRight:
            newRect.size.width += translation.width
            newRect.size.height += translation.height

        case .top:
            newRect.origin.y += translation.height
            newRect.size.height -= translation.height

        case .bottom:
            newRect.size.height += translation.height

        case .left:
            newRect.origin.x += translation.width
            newRect.size.width -= translation.width

        case .right:
            newRect.size.width += translation.width

        case .center:
            break
        }

        // Ensure minimum size
        if newRect.width < minCropSize {
            newRect.size.width = minCropSize
        }
        if newRect.height < minCropSize {
            newRect.size.height = minCropSize
        }

        // Clamp to image bounds
        newRect = clampToImageBounds(newRect, imageSize: imageSize)

        // Apply aspect ratio constraint
        newRect = cropper.constrainAspect(newRect)

        cropper.setCropRect(newRect)
    }

    private func handleDragEnded() {
        activeHandle = nil
    }

    // MARK: - Helpers

    private func clampToImageBounds(_ rect: CGRect, imageSize: CGSize) -> CGRect {
        CGRect(
            x: max(0, min(rect.origin.x, imageSize.width - minCropSize)),
            y: max(0, min(rect.origin.y, imageSize.height - minCropSize)),
            width: min(rect.width, imageSize.width),
            height: min(rect.height, imageSize.height)
        )
    }
}
