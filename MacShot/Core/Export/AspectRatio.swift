// AspectRatio.swift - Aspect ratio presets for cropping
// Part of Phase 06 - Export System

import Foundation
import SwiftUI

/// Aspect ratio presets for image cropping
enum AspectRatio: String, CaseIterable, Identifiable {
    case free = "Freeform"
    case original = "Original"
    case square = "1:1"
    case landscape43 = "4:3"
    case landscape169 = "16:9"
    case portrait34 = "3:4"

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Computed Properties

    /// Numeric ratio (width/height), nil for unconstrained
    var ratio: CGFloat? {
        switch self {
        case .free, .original: return nil
        case .square: return 1
        case .landscape43: return 4.0 / 3.0
        case .landscape169: return 16.0 / 9.0
        case .portrait34: return 3.0 / 4.0
        }
    }

    /// Display name for UI
    var displayName: String { rawValue }

    /// Width:Height label for UI
    var label: String {
        switch self {
        case .free: return "Free"
        case .original: return "Original"
        default: return rawValue
        }
    }

    // MARK: - Methods

    /// Calculate constrained size for given bounds
    /// - Parameter bounds: The available bounds
    /// - Returns: Size constrained to aspect ratio
    func constrainedSize(for bounds: CGRect) -> CGSize {
        guard let ratio = ratio else {
            return bounds.size
        }

        let boundsRatio = bounds.width / bounds.height

        if boundsRatio > ratio {
            // Width constrained
            let height = bounds.height
            let width = height * ratio
            return CGSize(width: width, height: height)
        } else {
            // Height constrained
            let width = bounds.width
            let height = width / ratio
            return CGSize(width: width, height: height)
        }
    }

    /// Constrain rect to aspect ratio
    /// - Parameter rect: The rect to constrain
    /// - Parameter anchor: The anchor point (center by default)
    /// - Returns: Rect constrained to aspect ratio
    func constrain(_ rect: CGRect, anchor: CGRectAnchor = .center) -> CGRect {
        guard let ratio = ratio else {
            return rect
        }

        let currentRatio = rect.width / rect.height

        if abs(currentRatio - ratio) < 0.01 {
            return rect // Already at ratio
        }

        let newSize: CGSize
        switch anchor {
        case .width:
            let width = rect.width
            let height = width / ratio
            newSize = CGSize(width: width, height: height)
        case .height:
            let height = rect.height
            let width = height * ratio
            newSize = CGSize(width: width, height: height)
        case .center:
            // Use larger dimension to maintain area
            if currentRatio > ratio {
                let width = rect.width
                let height = width / ratio
                newSize = CGSize(width: width, height: height)
            } else {
                let height = rect.height
                let width = height * ratio
                newSize = CGSize(width: width, height: height)
            }
        }

        return CGRect(
            x: rect.midX - newSize.width / 2,
            y: rect.midY - newSize.height / 2,
            width: newSize.width,
            height: newSize.height
        )
    }
}

/// Anchor point for aspect ratio constraint
enum CGRectAnchor {
    case width   // Fix width, adjust height
    case height  // Fix height, adjust width
    case center  // Maintain area, adjust both
}
