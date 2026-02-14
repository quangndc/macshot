// LineShape.swift - Straight line annotation
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import CoreGraphics

/// Line annotation with stroke styling
struct LineShape: Shape {
    // MARK: - Shape Protocol

    let id = UUID()
    var startPoint: CGPoint
    var endPoint: CGPoint
    var style: ShapeStyle
    var isSelected = false

    // MARK: - Computed Properties

    var bounds: CGRect {
        CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
    }

    // MARK: - Shape Protocol Implementation

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        return path
    }

    func draw(in context: GraphicsContext, rect: CGRect) {
        var resolvedContext = context

        if style.opacity < 1.0 {
            resolvedContext.opacity = style.opacity
        }

        let linePath = path(in: rect)
        resolvedContext.stroke(
            linePath,
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

    // MARK: - Hit Test (Override for line thickness)

    func hitTest(point: CGPoint, tolerance: CGFloat) -> Bool {
        // Distance from point to line segment
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
