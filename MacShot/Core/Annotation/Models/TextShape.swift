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

    // MARK: - Constants

    private static let maxTextLength = 1000
    private static let minTextLength = 1

    // MARK: - Convenience Initializers

    init(position: CGPoint, text: String, font: NSFont = .systemFont(ofSize: 18), color: Color = .red) {
        self.position = position
        self.text = text
        self.font = font
        self.color = color
    }

    // MARK: - Validation

    func isValid() -> Bool {
        // Check text length
        guard text.count >= Self.minTextLength else { return false }
        guard text.count <= Self.maxTextLength else { return false }

        // Check frame validity
        let frame = bounds
        guard !frame.isEmpty else { return false }
        guard !frame.isInfinite else { return false }

        // Text should contain visible characters
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        return true
    }

    func normalize() -> TextShape {
        var sanitized = self

        // Trim whitespace
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Limit length
        if trimmed.count > Self.maxTextLength {
            let index = trimmed.index(trimmed.startIndex, offsetBy: Self.maxTextLength)
            trimmed = String(trimmed[..<index])
        }

        // Remove control characters (except tabs and newlines)
        trimmed = String(trimmed.compactMap { char -> Character? in
            // Check if character is a control character (ASCII 0-31, except 9=tab, 10=newline, 13=carriage return)
            let scalars = char.unicodeScalars
            guard let scalar = scalars.first else { return char }
            if scalar.value < 32 && scalar.value != 9 && scalar.value != 10 && scalar.value != 13 {
                return nil
            }
            return char
        })

        sanitized.text = trimmed
        return sanitized
    }

    func enforceMinimumSize() -> TextShape {
        // Text size is determined by content, not manually set
        // Just validate it's renderable
        return self
    }

    func withFrame(_ newFrame: CGRect) -> TextShape {
        // For text, frame is derived from content, so we adjust position instead
        var copy = self
        copy.position = CGPoint(x: newFrame.origin.x, y: newFrame.maxY)
        return copy
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
