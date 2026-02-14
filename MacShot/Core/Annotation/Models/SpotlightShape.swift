// SpotlightShape.swift - Spotlight/blur effect for highlighting areas
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import CoreGraphics

/// Spotlight shape that dims everything except the highlighted circular region
struct SpotlightShape: Shape {
    // MARK: - Shape Protocol

    let id = UUID()
    var center: CGPoint
    var radius: CGFloat
    var blurRadius: CGFloat
    var dimOpacity: Double
    var isSelected = false

    // MARK: - Convenience Initializers

    init(center: CGPoint, radius: CGFloat = 80, blurRadius: CGFloat = 20, dimOpacity: Double = 0.7) {
        self.center = center
        self.radius = radius
        self.blurRadius = blurRadius
        self.dimOpacity = dimOpacity
    }

    // MARK: - Computed Properties

    var style: ShapeStyle {
        ShapeStyle(strokeColor: .black, fillColor: .black, strokeWidth: 0, opacity: dimOpacity)
    }

    var bounds: CGRect {
        CGRect(
            x: center.x - radius - blurRadius,
            y: center.y - radius - blurRadius,
            width: (radius + blurRadius) * 2,
            height: (radius + blurRadius) * 2
        )
    }

    // MARK: - Shape Protocol Implementation

    func path(in rect: CGRect) -> Path {
        // Full rect path for the dim overlay
        Path(CGRect(origin: .zero, size: rect.size))
    }

    func draw(in context: GraphicsContext, rect: CGRect) {
        var resolvedContext = context

        // Draw dim overlay using a path that has a hole
        // We use a path with subpaths: outer rect (clockwise) + inner circle (counter-clockwise)
        var dimPath = Path()

        // Outer rectangle (clockwise winding)
        dimPath.addRect(CGRect(origin: .zero, size: rect.size))

        // Inner circle (counter-clockwise winding creates hole)
        let spotlightRect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        // Add ellipse in reverse direction to create hole
        let spotlightEllipse = Ellipse().path(in: spotlightRect)
        dimPath.addPath(spotlightEllipse)

        // Draw dim overlay with hole
        resolvedContext.fill(dimPath, with: .color(.black.opacity(dimOpacity)))

        // Draw subtle border around spotlight
        let borderStyle = ShapeStyle(
            strokeColor: .white,
            fillColor: nil,
            strokeWidth: 2,
            opacity: 0.5
        )
        let borderPath = Path(ellipseIn: spotlightRect)
        resolvedContext.stroke(
            borderPath,
            with: .color(borderStyle.strokeColor),
            lineWidth: borderStyle.strokeWidth
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

        // Edge handles for resizing radius
        let edges = [
            CGPoint(x: center.x + radius, y: center.y),  // right edge
            CGPoint(x: center.x - radius, y: center.y),  // left edge
            CGPoint(x: center.x, y: center.y + radius),  // bottom edge
            CGPoint(x: center.x, y: center.y - radius)   // top edge
        ]

        for edge in edges {
            let handleRect = CGRect(
                x: edge.x - handleSize / 2,
                y: edge.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
            let handlePath = Path { path in path.addEllipse(in: handleRect) }
            context.fill(handlePath, with: .color(handleStyle.fillColor!))
            context.stroke(handlePath, with: .color(handleStyle.strokeColor), lineWidth: handleStyle.strokeWidth)
        }

        // Center handle for moving
        let centerRect = CGRect(
            x: center.x - handleSize / 2,
            y: center.y - handleSize / 2,
            width: handleSize,
            height: handleSize
        )
        let centerPath = Path { path in path.addEllipse(in: centerRect) }
        context.fill(centerPath, with: .color(handleStyle.fillColor!))
        context.stroke(centerPath, with: .color(handleStyle.strokeColor), lineWidth: handleStyle.strokeWidth)
    }

    // MARK: - Hit Test

    func hitTest(point: CGPoint, tolerance: CGFloat) -> Bool {
        // Check if point is in spotlight ring area
        let distance = hypot(point.x - center.x, point.y - center.y)
        return abs(distance - radius) <= tolerance || distance <= radius
    }
}

/// Predefined spotlight styles
extension SpotlightShape {
    /// Small spotlight
    static func small(at center: CGPoint) -> SpotlightShape {
        SpotlightShape(center: center, radius: 50, blurRadius: 15, dimOpacity: 0.7)
    }

    /// Medium spotlight
    static func medium(at center: CGPoint) -> SpotlightShape {
        SpotlightShape(center: center, radius: 80, blurRadius: 20, dimOpacity: 0.7)
    }

    /// Large spotlight
    static func large(at center: CGPoint) -> SpotlightShape {
        SpotlightShape(center: center, radius: 120, blurRadius: 25, dimOpacity: 0.7)
    }

    /// Extra dim overlay (darker)
    static func extraDim(at center: CGPoint) -> SpotlightShape {
        SpotlightShape(center: center, radius: 80, blurRadius: 20, dimOpacity: 0.85)
    }

    /// Light overlay (subtle)
    static func light(at center: CGPoint) -> SpotlightShape {
        SpotlightShape(center: center, radius: 80, blurRadius: 20, dimOpacity: 0.5)
    }
}
