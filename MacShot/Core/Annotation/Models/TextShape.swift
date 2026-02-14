// TextShape.swift - Text annotation shape
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import CoreGraphics

/// Text annotation with customizable font, size, and color
struct TextShape: Shape {
    // MARK: - Shape Protocol

    let id = UUID()
    var position: CGPoint
    var text: String
    var font: NSFont
    var color: Color
    var isSelected = false

    // MARK: - Convenience Initializers

    init(position: CGPoint, text: String, font: NSFont = .systemFont(ofSize: 18), color: Color = .red) {
        self.position = position
        self.text = text
        self.font = font
        self.color = color
    }

    // MARK: - Computed Properties

    var style: ShapeStyle {
        ShapeStyle(strokeColor: color, fillColor: nil, strokeWidth: 0, opacity: 1.0)
    }

    var bounds: CGRect {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return CGRect(
            x: position.x,
            y: position.y - size.height, // Position is bottom-left origin
            width: size.width,
            height: size.height
        )
    }

    // MARK: - Shape Protocol Implementation

    func path(in rect: CGRect) -> Path {
        // Text doesn't have a path for drawing, return empty
        Path()
    }

    func draw(in context: GraphicsContext, rect: CGRect) {
        let resolvedContext = context

        let resolvedFont = font
        let attributes: [NSAttributedString.Key: Any] = [
            .font: resolvedFont,
            .foregroundColor: NSColor(color)
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let size = (text as NSString).size(withAttributes: attributes)

        // Draw text at position
        resolvedContext.draw(
            Text(attributedString.string).font(Font(resolvedFont)).foregroundColor(color),
            in: CGRect(
                x: position.x,
                y: position.y - size.height,
                width: size.width,
                height: size.height
            )
        )

        if isSelected {
            drawSelectionBorder(in: resolvedContext, size: size)
        }
    }

    // MARK: - Selection

    private func drawSelectionBorder(in context: GraphicsContext, size: CGSize) {
        let borderRect = CGRect(
            x: position.x - 2,
            y: position.y - size.height - 2,
            width: size.width + 4,
            height: size.height + 4
        )
        let borderPath = Path { path in path.addRect(borderRect) }
        context.stroke(borderPath, with: .color(.blue), lineWidth: 1)
    }

    // MARK: - Hit Test

    func hitTest(point: CGPoint, tolerance: CGFloat) -> Bool {
        bounds.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
    }
}

/// Predefined text styles for quick access
extension TextShape {
    /// Small text annotation
    static func small(at position: CGPoint, text: String, color: Color = .red) -> TextShape {
        TextShape(position: position, text: text, font: .systemFont(ofSize: 14), color: color)
    }

    /// Medium text annotation
    static func medium(at position: CGPoint, text: String, color: Color = .red) -> TextShape {
        TextShape(position: position, text: text, font: .systemFont(ofSize: 18), color: color)
    }

    /// Large text annotation
    static func large(at position: CGPoint, text: String, color: Color = .red) -> TextShape {
        TextShape(position: position, text: text, font: .systemFont(ofSize: 24), color: color)
    }

    /// Bold text annotation
    static func bold(at position: CGPoint, text: String, color: Color = .red) -> TextShape {
        TextShape(position: position, text: text, font: .boldSystemFont(ofSize: 18), color: color)
    }
}
