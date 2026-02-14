// NumberShape.swift - Numbered badge annotation
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import CoreGraphics

/// Numbered circular badge for step-by-step annotations
struct NumberShape: Shape {
    // MARK: - Shape Protocol

    let id = UUID()
    var position: CGPoint
    var number: Int
    var style: ShapeStyle
    var isSelected = false

    /// Badge size (diameter)
    var size: CGFloat = 32

    // MARK: - Convenience Initializers

    init(position: CGPoint, number: Int, size: CGFloat = 32, style: ShapeStyle = .default) {
        self.position = position
        self.number = number
        self.size = size
        self.style = style
    }

    // MARK: - Computed Properties

    var bounds: CGRect {
        CGRect(
            x: position.x - size / 2,
            y: position.y - size / 2,
            width: size,
            height: size
        )
    }

    // MARK: - Shape Protocol Implementation

    func path(in rect: CGRect) -> Path {
        Path { path in path.addEllipse(in: bounds) }
    }

    func draw(in context: GraphicsContext, rect: CGRect) {
        var resolvedContext = context

        if style.opacity < 1.0 {
            resolvedContext.opacity = style.opacity
        }

        let circlePath = path(in: rect)

        // Fill circle
        let fillStyle = style.fillColor ?? style.strokeColor
        resolvedContext.fill(circlePath, with: .color(fillStyle))

        // Draw number text
        let fontSize = size * 0.55
        let font = NSFont.boldSystemFont(ofSize: fontSize)
        let text = String(number)

        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (text as NSString).size(withAttributes: attributes)

        // Draw number text using resolvedContext with Text view
        let textSymbol = Text(text)
            .font(Font(font))
            .foregroundStyle(.white)
        let textRect = CGRect(
            x: position.x - textSize.width / 2,
            y: position.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        resolvedContext.draw(textSymbol, in: textRect)

        if isSelected {
            drawSelectionBorder(in: resolvedContext)
        }
    }

    // MARK: - Selection

    private func drawSelectionBorder(in context: GraphicsContext) {
        let borderRect = bounds.insetBy(dx: -4, dy: -4)
        let borderPath = Path { path in path.addEllipse(in: borderRect) }
        context.stroke(borderPath, with: .color(.blue), lineWidth: 1.5)
    }

    // MARK: - Hit Test

    func hitTest(point: CGPoint, tolerance: CGFloat) -> Bool {
        bounds.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
    }
}

/// Predefined number badge styles
extension NumberShape {
    /// Red badge (default)
    static func red(at position: CGPoint, number: Int) -> NumberShape {
        NumberShape(
            position: position,
            number: number,
            style: ShapeStyle(strokeColor: .red, fillColor: .red, strokeWidth: 0, opacity: 1.0)
        )
    }

    /// Blue badge
    static func blue(at position: CGPoint, number: Int) -> NumberShape {
        NumberShape(
            position: position,
            number: number,
            style: ShapeStyle(strokeColor: .blue, fillColor: .blue, strokeWidth: 0, opacity: 1.0)
        )
    }

    /// Green badge
    static func green(at position: CGPoint, number: Int) -> NumberShape {
        NumberShape(
            position: position,
            number: number,
            style: ShapeStyle(strokeColor: .green, fillColor: .green, strokeWidth: 0, opacity: 1.0)
        )
    }

    /// Yellow badge
    static func yellow(at position: CGPoint, number: Int) -> NumberShape {
        NumberShape(
            position: position,
            number: number,
            style: ShapeStyle(strokeColor: .yellow, fillColor: .yellow, strokeWidth: 0, opacity: 1.0)
        )
    }
}
