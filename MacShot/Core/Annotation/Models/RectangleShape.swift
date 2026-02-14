// RectangleShape.swift - Rectangular annotation shape
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import CoreGraphics

/// Rectangle annotation shape with stroke/fill styling
struct RectangleShape: Shape {
    // MARK: - Shape Protocol

    let id = UUID()
    var rect: CGRect
    var style: ShapeStyle
    var isSelected = false

    // MARK: - Computed Properties

    var bounds: CGRect { rect }

    // MARK: - Shape Protocol Implementation

    func path(in rect: CGRect) -> Path {
        Path { path in path.addRect(self.rect) }
    }

    func draw(in context: GraphicsContext, rect: CGRect) {
        var resolvedContext = context

        // Apply opacity if not fully opaque
        if style.opacity < 1.0 {
            resolvedContext.opacity = style.opacity
        }

        let shapePath = path(in: rect)

        // Fill if color provided
        if let fillColor = style.fillColor {
            resolvedContext.fill(shapePath, with: .color(fillColor))
        }

        // Stroke outline
        resolvedContext.stroke(
            shapePath,
            with: .color(style.strokeColor),
            lineWidth: style.strokeWidth
        )

        // Draw selection handles if selected
        if isSelected {
            drawSelectionHandles(in: resolvedContext, rect: rect)
        }
    }

    // MARK: - Selection Handles

    private func drawSelectionHandles(in context: GraphicsContext, rect: CGRect) {
        let handleSize: CGFloat = 8
        let handleStyle = ShapeStyle(
            strokeColor: .blue,
            fillColor: .white,
            strokeWidth: 1.5,
            opacity: 1.0
        )

        // Corner handles: top-left, top-right, bottom-right, bottom-left
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]

        for corner in corners {
            let handleRect = CGRect(
                x: corner.x - handleSize / 2,
                y: corner.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
            let handlePath = Path { path in path.addRect(handleRect) }
            context.fill(handlePath, with: .color(handleStyle.fillColor!))
            context.stroke(handlePath, with: .color(handleStyle.strokeColor), lineWidth: handleStyle.strokeWidth)
        }
    }
}
