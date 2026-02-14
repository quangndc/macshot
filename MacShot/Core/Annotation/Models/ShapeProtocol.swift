// ShapeProtocol.swift - Base protocol for all annotation shapes
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import CoreGraphics

/// Visual style properties for shapes (stroke, fill, opacity)
struct ShapeStyle: Equatable {
    /// Stroke (outline) color
    var strokeColor: Color

    /// Fill color (nil = transparent/none)
    var fillColor: Color?

    /// Stroke width in points
    var strokeWidth: CGFloat

    /// Opacity (0.0 = transparent, 1.0 = opaque)
    var opacity: Double

    /// Default red annotation style
    static let `default` = ShapeStyle(
        strokeColor: .red,
        fillColor: nil,
        strokeWidth: 3.0,
        opacity: 1.0
    )

    /// Equatable conformance for style comparison
    static func == (lhs: ShapeStyle, rhs: ShapeStyle) -> Bool {
        lhs.strokeColor == rhs.strokeColor &&
        lhs.fillColor == rhs.fillColor &&
        lhs.strokeWidth == rhs.strokeWidth &&
        lhs.opacity == rhs.opacity
    }
}

/// Base protocol for all drawable annotation shapes
/// Every shape (rectangle, arrow, text, etc.) conforms to this
protocol Shape: Identifiable {
    /// Unique identifier for selection/undo/redo tracking
    var id: UUID { get }

    /// Bounding rectangle of this shape (used for hit testing and selection)
    var bounds: CGRect { get }

    /// Selection state (true = currently selected by user)
    var isSelected: Bool { get set }

    /// Generate SwiftUI Path for rendering and hit testing
    /// - Parameter rect: Canvas coordinate space
    /// - Returns: Path representing this shape's geometry
    func path(in rect: CGRect) -> Path

    /// Draw this shape into a Canvas graphics context
    /// - Parameters:
    ///   - context: SwiftUI Canvas drawing context
    ///   - rect: Canvas coordinate space for rendering
    func draw(in context: GraphicsContext, rect: CGRect)

    /// Check if a point hits this shape (for selection)
    /// - Parameters:
    ///   - point: Touch/click location in canvas coordinates
    ///   - tolerance: Extra padding for easier selection (default: 10pt)
    /// - Returns: true if point is within selection tolerance
    func hitTest(point: CGPoint, tolerance: CGFloat) -> Bool
}

/// Default hit test implementation using bounds checking
extension Shape {
    func hitTest(point: CGPoint, tolerance: CGFloat) -> Bool {
        bounds.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
    }
}
