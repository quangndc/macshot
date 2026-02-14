// EllipseShape.swift - Elliptical/circular annotation shape
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import CoreGraphics

/// Ellipse annotation shape with stroke/fill styling
struct EllipseShape: Shape {
    // MARK: - Shape Protocol

    let id = UUID()
    var rect: CGRect
    var style: ShapeStyle
    var isSelected = false

    // MARK: - Computed Properties

    var bounds: CGRect { rect }

    // MARK: - Shape Protocol Implementation

    func path(in rect: CGRect) -> Path {
        Path { path in path.addEllipse(in: self.rect) }
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

        // Cardinal point handles: top, right, bottom, left
        let handles = [
            CGPoint(x: rect.midX, y: rect.minY),           // top
            CGPoint(x: rect.maxX, y: rect.midY),           // right
            CGPoint(x: rect.midX, y: rect.maxY),           // bottom
            CGPoint(x: rect.minX, y: rect.midY)            // left
        ]

        for handle in handles {
            let handleRect = CGRect(
                x: handle.x - handleSize / 2,
                y: handle.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
            let handlePath = Path { path in path.addEllipse(in: handleRect) }
            context.fill(handlePath, with: .color(handleStyle.fillColor!))
            context.stroke(handlePath, with: .color(handleStyle.strokeColor), lineWidth: handleStyle.strokeWidth)
        }
    }
}
