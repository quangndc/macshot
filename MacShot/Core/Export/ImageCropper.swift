// ImageCropper.swift - Non-destructive image cropping
// Part of Phase 06 - Export System

import SwiftUI
import AppKit

/// Non-destructive image cropper with aspect ratio support
@Observable
final class ImageCropper {
    // MARK: - Properties

    /// Current crop rectangle in image coordinates (nil = no crop)
    var cropRect: CGRect?

    /// Active aspect ratio constraint (nil = freeform)
    var aspectRatio: AspectRatio?

    /// Original image bounds for clamping
    private var imageBounds: CGRect = .zero

    // MARK: - Initialization

    init() {}

    // MARK: - Configuration

    /// Set the image bounds for clamping crop operations
    /// - Parameter bounds: The image bounds
    func setImageBounds(_ bounds: CGRect) {
        imageBounds = bounds
    }

    // MARK: - Crop Operations

    /// Apply crop to image
    /// - Parameter image: The source image
    /// - Returns: Cropped image (or original if no crop)
    func crop(_ image: NSImage) -> NSImage {
        guard let cropRect = cropRect else {
            return image
        }

        // Clamp crop rect to image bounds
        let clampedRect = clampToImageBounds(cropRect)

        // Validate crop rect has positive size
        guard clampedRect.width > 0 && clampedRect.height > 0 else {
            return image
        }

        let cropped = NSImage(size: clampedRect.size)
        cropped.lockFocus()

        image.draw(
            in: CGRect(origin: .zero, size: clampedRect.size),
            from: clampedRect,
            operation: .copy,
            fraction: 1.0
        )

        cropped.unlockFocus()

        return cropped
    }

    /// Set crop rect and apply aspect ratio constraint
    /// - Parameter rect: The desired crop rectangle
    func setCropRect(_ rect: CGRect) {
        if let ratio = aspectRatio {
            cropRect = ratio.constrain(rect, anchor: .center)
        } else {
            cropRect = rect
        }
    }

    /// Set crop rect from normalized coordinates (0-1)
    /// - Parameter normalizedRect: Rect in normalized coordinates
    func setNormalizedCropRect(_ normalizedRect: CGRect) {
        let imageRect = CGRect(
            x: normalizedRect.origin.x * imageBounds.width,
            y: normalizedRect.origin.y * imageBounds.height,
            width: normalizedRect.width * imageBounds.width,
            height: normalizedRect.height * imageBounds.height
        )
        setCropRect(imageRect)
    }

    /// Get crop rect as normalized coordinates (0-1)
    /// - Returns: Normalized rect or nil if no crop
    func getNormalizedCropRect() -> CGRect? {
        guard let cropRect = cropRect else {
            return nil
        }

        return CGRect(
            x: cropRect.origin.x / imageBounds.width,
            y: cropRect.origin.y / imageBounds.height,
            width: cropRect.width / imageBounds.width,
            height: cropRect.height / imageBounds.height
        )
    }

    // MARK: - Aspect Ratio

    /// Update aspect ratio and constrain existing crop
    /// - Parameter ratio: New aspect ratio (nil = freeform)
    func setAspectRatio(_ ratio: AspectRatio?) {
        aspectRatio = ratio
        if let existingCrop = cropRect {
            setCropRect(existingCrop)
        }
    }

    /// Constrain rect to current aspect ratio
    /// - Parameter rect: The rect to constrain
    /// - Returns: Constrained rect
    func constrainAspect(_ rect: CGRect) -> CGRect {
        guard let ratio = aspectRatio else {
            return rect
        }
        return ratio.constrain(rect, anchor: .center)
    }

    // MARK: - Reset

    /// Reset crop to none
    func resetCrop() {
        cropRect = nil
    }

    // MARK: - Private Helpers

    /// Clamp rect to image bounds
    private func clampToImageBounds(_ rect: CGRect) -> CGRect {
        CGRect(
            x: max(0, min(rect.origin.x, imageBounds.maxX - 1)),
            y: max(0, min(rect.origin.y, imageBounds.maxY - 1)),
            width: min(rect.width, imageBounds.width),
            height: min(rect.height, imageBounds.height)
        )
    }
}

// MARK: - Crop Handle Types

/// Crop handle positions for resizing
enum CropHandle {
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
    case center  // For dragging the whole crop

    /// Cursor for this handle
    var cursor: NSCursor {
        switch self {
        case .topLeft, .bottomRight: return .closedHand
        case .topRight, .bottomLeft: return .closedHand
        case .top, .bottom: return .resizeUpDown
        case .left, .right: return .resizeLeftRight
        case .center: return .openHand
        }
    }
}
