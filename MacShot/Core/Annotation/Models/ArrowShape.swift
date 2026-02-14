// ArrowShape.swift - Arrow annotation with shaft and arrowhead
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import CoreGraphics

/// Arrow annotation with stroke styling and arrowhead at end point
struct ArrowShape: Shape {
    // MARK: - Shape Protocol

    let id = UUID()
    var startPoint: CGPoint
    var endPoint: CGPoint
    var style: ShapeStyle
    var isSelected = false

    /// Arrow head size relative to stroke width
    var headScale: CGFloat = 3.0

    // MARK: - Computed Properties

    var bounds: CGRect {
        // Include arrowhead in bounds
        let headLength = style.strokeWidth * headScale * 2
        let minX = min(startPoint.x, endPoint.x) - headLength
        let minY = min(startPoint.y, endPoint.y) - headLength
        let width = abs(endPoint.x - startPoint.x) + headLength * 2
        let height = abs(endPoint.y - startPoint.y) + headLength * 2
        return CGRect(x: minX, y: minY, width: width, height: height)
    }

    // MARK: - Shape Protocol Implementation

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Arrow shaft
        path.move(to: startPoint)
        path.addLine(to: endPoint)

        // Arrow head (two angled lines)
        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let headLength = style.strokeWidth * headScale

        // Left wing of arrowhead
        let leftWing = CGPoint(
            x: endPoint.x - headLength * cos(angle - .pi / 6),
            y: endPoint.y - headLength * sin(angle - .pi / 6)
        )
        path.move(to: endPoint)
        path.addLine(to: leftWing)

        // Right wing of arrowhead
        let rightWing = CGPoint(
            x: endPoint.x - headLength * cos(angle + .pi / 6),
            y: endPoint.y - headLength * sin(angle + .pi / 6)
        )
        path.move(to: endPoint)
        path.addLine(to: rightWing)

        return path
    }

    func draw(in context: GraphicsContext, rect: CGRect) {
        var resolvedContext = context

        if style.opacity < 1.0 {
            resolvedContext.opacity = style.opacity
        }

        let arrowPath = path(in: rect)
        resolvedContext.stroke(
            arrowPath,
            with: .color(style.strokeColor),
            lineWidth: style.strokeWidth
        )

        if isSelected {
            drawSelectionHandles(in: resolvedContext)
        }
    }

    // MARK: - Selection

    private func drawSelectionHandles(in context: GraphicsContext) {
        let handleSize: CGFloat = 8
        let handleStyle = ShapeStyle(
            strokeColor: .blue,
            fillColor: .white,
            strokeWidth: 1.5,
            opacity: 1.0
        )

        let handles = [startPoint, endPoint]

        for handle in handles {
            let handleRect = CGRect(
                x: handle.x - handleSize / 2,
                y: handle.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
            let handlePath = Path(ellipseIn: handleRect)
            context.fill(handlePath, with: .color(handleStyle.fillColor!))
            context.stroke(handlePath, with: .color(handleStyle.strokeColor), lineWidth: handleStyle.strokeWidth)
        }
    }

    // MARK: - Hit Test

    func hitTest(point: CGPoint, tolerance: CGFloat) -> Bool {
        // Distance from point to main shaft
        func distanceToSegment(p: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
            let (dx, dy) = (b.x - a.x, b.y - a.y)
            guard dx != 0 || dy != 0 else { return hypot(p.x - a.x, p.y - a.y) }
            let t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / (dx * dx + dy * dy)
            let closest = t < 0 ? a : t > 1 ? b : CGPoint(x: a.x + t * dx, y: a.y + t * dy)
            return hypot(p.x - closest.x, p.y - closest.y)
        }

        return distanceToSegment(p: point, a: startPoint, b: endPoint) <= max(style.strokeWidth, tolerance)
    }
}
