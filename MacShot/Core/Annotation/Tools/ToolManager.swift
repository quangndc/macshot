// ToolManager.swift - Manages current tool and drawing state
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import Observation

@Observable
final class ToolManager {
    // MARK: - Current Tool

    /// Currently selected tool
    var currentTool: ToolType = .select

    // MARK: - Style Properties

    /// Current stroke color for new shapes
    var strokeColor: Color = .red

    /// Current fill color (nil = no fill)
    var fillColor: Color?

    /// Current stroke width
    var strokeWidth: Double = 3.0

    /// Current opacity (0.0 - 1.0)
    var opacity: Double = 1.0

    // MARK: - Tool-Specific State

    /// Current number for number badges (auto-increments after use)
    var currentNumber: Int = 1

    /// Current text for text tool
    var currentText: String = "Text"

    /// Current font size for text
    var currentFontSize: CGFloat = 18

    /// Current spotlight radius
    var spotlightRadius: CGFloat = 80

    // MARK: - Convenience Properties

    /// Computed ShapeStyle from current style settings
    var currentStyle: ShapeStyle {
        ShapeStyle(
            strokeColor: strokeColor,
            fillColor: fillColor,
            strokeWidth: strokeWidth,
            opacity: opacity
        )
    }

    // MARK: - Tool Actions

    /// Change to a different tool
    func selectTool(_ tool: ToolType) {
        currentTool = tool
    }

    /// Set stroke color
    func setStrokeColor(_ color: Color) {
        strokeColor = color
    }

    /// Set fill color (nil removes fill)
    func setFillColor(_ color: Color?) {
        fillColor = color
    }

    /// Set stroke width
    func setStrokeWidth(_ width: Double) {
        strokeWidth = max(0.5, min(width, 20))
    }

    /// Set opacity
    func setOpacity(_ value: Double) {
        opacity = max(0.1, min(value, 1.0))
    }

    /// Increment number badge and return value
    func nextNumber() -> Int {
        let result = currentNumber
        currentNumber += 1
        return result
    }

    /// Reset number counter
    func resetNumberCounter() {
        currentNumber = 1
    }

    /// Set text for text tool
    func setText(_ text: String) {
        currentText = text.isEmpty ? "Text" : text
    }

    /// Set font size
    func setFontSize(_ size: CGFloat) {
        currentFontSize = max(10, min(size, 72))
    }

    /// Set spotlight radius
    func setSpotlightRadius(_ radius: CGFloat) {
        spotlightRadius = max(20, min(radius, 300))
    }

    // MARK: - Presets

    /// Red annotation preset
    func applyRedPreset() {
        strokeColor = .red
        fillColor = nil
        strokeWidth = 3.0
        opacity = 1.0
    }

    /// Blue annotation preset
    func applyBluePreset() {
        strokeColor = .blue
        fillColor = nil
        strokeWidth = 3.0
        opacity = 1.0
    }

    /// Green annotation preset
    func applyGreenPreset() {
        strokeColor = .green
        fillColor = nil
        strokeWidth = 3.0
        opacity = 1.0
    }

    /// Yellow highlight preset
    func applyHighlightPreset() {
        strokeColor = .yellow
        fillColor = .yellow.opacity(0.3)
        strokeWidth = 2.0
        opacity = 1.0
    }
}

// MARK: - Tool Selection Helpers

extension ToolManager {
    /// Check if currently in selection mode
    var isSelecting: Bool {
        currentTool == .select
    }

    /// Check if currently drawing a shape
    var isDrawing: Bool {
        switch currentTool {
        case .rectangle, .ellipse, .arrow, .line:
            return true
        default:
            return false
        }
    }

    /// Check if currently adding annotation
    var isAnnotating: Bool {
        switch currentTool {
        case .text, .number:
            return true
        default:
            return false
        }
    }

    /// Check if currently creating effect
    var isCreatingEffect: Bool {
        currentTool == .spotlight
    }
}
