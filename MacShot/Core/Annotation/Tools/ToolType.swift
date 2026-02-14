// ToolType.swift - Available annotation tools
// Part of Phase 04 - Annotation Canvas

import Foundation

/// All available annotation tools for the canvas
enum ToolType: String, CaseIterable {
    /// Select and manipulate existing shapes
    case select

    /// Draw rectangle shapes
    case rectangle

    /// Draw ellipse/circle shapes
    case ellipse

    /// Draw arrow annotations
    case arrow

    /// Draw straight lines
    case line

    /// Add text annotations
    case text

    /// Add numbered badges
    case number

    /// Create spotlight (dim overlay) effects
    case spotlight

    // MARK: - Display Properties

    /// Display name for UI
    var displayName: String {
        switch self {
        case .select: return "Select"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .arrow: return "Arrow"
        case .line: return "Line"
        case .text: return "Text"
        case .number: return "Number"
        case .spotlight: return "Spotlight"
        }
    }

    /// Icon name for toolbar buttons (SF Symbol)
    var iconName: String {
        switch self {
        case .select: return "cursorarrow"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .arrow: return "arrow.right"
        case .line: return "line.diagonal"
        case .text: return "textformat"
        case .number: return "1.circle"
        case .spotlight: return "circle.lefthalf.filled"
        }
    }

    /// Keyboard shortcut for quick tool access
    var keyboardShortcut: String? {
        switch self {
        case .select: return "V"
        case .rectangle: return "R"
        case .ellipse: return "E"
        case .arrow: return "A"
        case .line: return "L"
        case .text: return "T"
        case .number: return "N"
        case .spotlight: return "S"
        }
    }
}

/// Tool categories for grouping in UI
extension ToolType {
    enum Category: String, CaseIterable {
        case selection = "Selection"
        case shapes = "Shapes"
        case annotations = "Annotations"
        case effects = "Effects"
    }

    var category: Category {
        switch self {
        case .select: return .selection
        case .rectangle, .ellipse, .arrow, .line: return .shapes
        case .text, .number: return .annotations
        case .spotlight: return .effects
        }
    }
}
