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

    /// Validate shape properties (coordinates, dimensions, content)
    /// - Returns: true if shape is valid for rendering/export
    func isValid() -> Bool

    /// Normalize shape properties (clamp extreme values, sanitize content)
    /// - Returns: normalized version of this shape
    func normalize() -> Self

    /// Enforce minimum size constraints on shape
    /// - Returns: shape with minimum dimensions applied
    func enforceMinimumSize() -> Self

    /// Create a copy with a new frame/rect
    /// - Parameter newFrame: The new bounding rectangle
    /// - Returns: shape with updated frame
    func withFrame(_ newFrame: CGRect) -> Self
}

/// Default hit test implementation using bounds checking
extension Shape {
    func hitTest(point: CGPoint, tolerance: CGFloat) -> Bool {
        bounds.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
    }

    // MARK: - Default Validation Implementations

    /// Default validation checks for invalid CGRect states
    func isValid() -> Bool {
        let frame = bounds

        // Check frame validity
        guard !frame.isEmpty else { return false }
        guard !frame.isInfinite else { return false }
        guard !frame.isNull else { return false }

        // Check for NaN values
        guard !frame.origin.x.isNaN,
              !frame.origin.y.isNaN,
              !frame.size.width.isNaN,
              !frame.size.height.isNaN else {
            return false
        }

        // Check for infinity
        guard !frame.origin.x.isInfinite,
              !frame.origin.y.isInfinite,
              !frame.size.width.isInfinite,
              !frame.size.height.isInfinite else {
            return false
        }

        // Reasonable bounds (within ±100,000 pixels)
        let boundsLimit: CGFloat = 100_000
        guard abs(frame.origin.x) < boundsLimit,
              abs(frame.origin.y) < boundsLimit,
              frame.size.width < boundsLimit,
              frame.size.height < boundsLimit else {
            return false
        }

        return true
    }

    /// Default normalization clamps coordinate values
    func normalize() -> Self {
        self
    }

    /// Default minimum size enforcement
    func enforceMinimumSize() -> Self {
        self
    }

    /// Default frame replacement returns self (override in shapes with rect property)
    func withFrame(_ newFrame: CGRect) -> Self {
        self
    }

    // MARK: - Validation Helpers

    /// Clamp CGRect values to reasonable bounds
    func clampRect(_ rect: CGRect) -> CGRect {
        let boundsLimit: CGFloat = 100_000

        let x = max(-boundsLimit, min(boundsLimit, rect.origin.x))
        let y = max(-boundsLimit, min(boundsLimit, rect.origin.y))
        let w = max(0, min(boundsLimit, rect.size.width))
        let h = max(0, min(boundsLimit, rect.size.height))

        return CGRect(x: x, y: y, width: w, height: h)
    }
}

// MARK: - Shape Error Types

enum ShapeError: Error, LocalizedError {
    case invalidCoordinates([CGPoint])
    case invalidText(String)
    case minimumSizeNotMet

    var errorDescription: String? {
        switch self {
        case .invalidCoordinates(let points):
            return "Invalid coordinates for shape: \(points)"
        case .invalidText(let text):
            let preview = String(text.prefix(50))
            return "Invalid text: '\(preview)'"
        case .minimumSizeNotMet:
            return "Shape does not meet minimum size requirement"
        }
    }
}
