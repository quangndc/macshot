// ShapeFactory.swift - Factory for creating annotation shapes
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import CoreGraphics

/// Factory for creating shapes based on current tool settings
enum ShapeFactory {
    // MARK: - Shape Creation

    /// Create a shape based on tool type and points
    static func createShape(
        tool: ToolType,
        startPoint: CGPoint,
        endPoint: CGPoint,
        style: ShapeStyle,
        toolManager: ToolManager
    ) -> (any Shape)? {
        switch tool {
        case .select:
            return nil // Selection tool doesn't create shapes

        case .rectangle:
            return RectangleShape(
                rect: rectFromPoints(startPoint, endPoint),
                style: style
            )

        case .ellipse:
            return EllipseShape(
                rect: rectFromPoints(startPoint, endPoint),
                style: style
            )

        case .arrow:
            return ArrowShape(
                startPoint: startPoint,
                endPoint: endPoint,
                style: style
            )

        case .line:
            return LineShape(
                startPoint: startPoint,
                endPoint: endPoint,
                style: style
            )

        case .text:
            return TextShape.medium(
                at: startPoint,
                text: toolManager.currentText,
                color: style.strokeColor
            )

        case .number:
            let number = toolManager.nextNumber()
            return NumberShape.red(
                at: startPoint,
                number: number
            )

        case .spotlight:
            let radius = distance(from: startPoint, to: endPoint)
            return SpotlightShape(
                center: startPoint,
                radius: max(radius, 30),
                blurRadius: 20,
                dimOpacity: 0.7
            )
        }
    }

    /// Create shape with specific parameters
    static func createRectangle(
        at point: CGPoint,
        size: CGSize,
        style: ShapeStyle = .default
    ) -> RectangleShape {
        RectangleShape(
            rect: CGRect(origin: point, size: size),
            style: style
        )
    }

    static func createEllipse(
        at point: CGPoint,
        size: CGSize,
        style: ShapeStyle = .default
    ) -> EllipseShape {
        EllipseShape(
            rect: CGRect(origin: point, size: size),
            style: style
        )
    }

    static func createArrow(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        style: ShapeStyle = .default
    ) -> ArrowShape {
        ArrowShape(
            startPoint: startPoint,
            endPoint: endPoint,
            style: style
        )
    }

    static func createLine(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        style: ShapeStyle = .default
    ) -> LineShape {
        LineShape(
            startPoint: startPoint,
            endPoint: endPoint,
            style: style
        )
    }

    static func createText(
        at point: CGPoint,
        text: String,
        color: Color = .red,
        size: TextSize = .medium
    ) -> TextShape {
        let font: NSFont
        switch size {
        case .small: font = .systemFont(ofSize: 14)
        case .medium: font = .systemFont(ofSize: 18)
        case .large: font = .systemFont(ofSize: 24)
        case .bold: font = .boldSystemFont(ofSize: 18)
        }

        return TextShape(position: point, text: text, font: font, color: color)
    }

    static func createNumber(
        at point: CGPoint,
        number: Int,
        color: NumberColor = .red,
        size: CGFloat = 32
    ) -> NumberShape {
        let style: ShapeStyle
        switch color {
        case .red: style = ShapeStyle(strokeColor: .red, fillColor: .red, strokeWidth: 0, opacity: 1.0)
        case .blue: style = ShapeStyle(strokeColor: .blue, fillColor: .blue, strokeWidth: 0, opacity: 1.0)
        case .green: style = ShapeStyle(strokeColor: .green, fillColor: .green, strokeWidth: 0, opacity: 1.0)
        case .yellow: style = ShapeStyle(strokeColor: .yellow, fillColor: .yellow, strokeWidth: 0, opacity: 1.0)
        }

        return NumberShape(position: point, number: number, size: size, style: style)
    }

    static func createSpotlight(
        at center: CGPoint,
        radius: CGFloat = 80,
        blurRadius: CGFloat = 20,
        dimOpacity: Double = 0.7
    ) -> SpotlightShape {
        SpotlightShape(
            center: center,
            radius: radius,
            blurRadius: blurRadius,
            dimOpacity: dimOpacity
        )
    }

    // MARK: - Helper Types

    enum TextSize {
        case small, medium, large, bold
    }

    enum NumberColor {
        case red, blue, green, yellow
    }

    // MARK: - Private Helpers

    private static func rectFromPoints(_ start: CGPoint, _ end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    private static func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        hypot(to.x - from.x, to.y - from.y)
    }
}

// MARK: - Preset Shapes

extension ShapeFactory {
    /// Quick shapes for common annotation scenarios
    enum Preset {
        case errorLabel(at: CGPoint)
        case warningLabel(at: CGPoint)
        case successBadge(at: CGPoint, number: Int)
        case arrowCallout(from: CGPoint, to: CGPoint)
        case highlightArea(CGRect)

        var shape: (any Shape)? {
            switch self {
            case .errorLabel(let point):
                return TextShape.bold(at: point, text: "ERROR", color: .red)

            case .warningLabel(let point):
                return TextShape.bold(at: point, text: "WARNING", color: .yellow)

            case .successBadge(let point, let number):
                return NumberShape.green(at: point, number: number)

            case .arrowCallout(let from, let to):
                return ArrowShape(
                    startPoint: from,
                    endPoint: to,
                    style: ShapeStyle(strokeColor: .blue, fillColor: nil, strokeWidth: 3, opacity: 1)
                )

            case .highlightArea(let rect):
                return EllipseShape(
                    rect: rect,
                    style: ShapeStyle(
                        strokeColor: .yellow,
                        fillColor: .yellow.opacity(0.3),
                        strokeWidth: 2,
                        opacity: 0.8
                    )
                )
            }
        }
    }
}
