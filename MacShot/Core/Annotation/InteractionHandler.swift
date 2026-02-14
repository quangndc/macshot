// InteractionHandler.swift - Handles selection, transform, and manipulation
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import CoreGraphics

/// Handles user interactions with shapes on the canvas
@Observable
final class InteractionHandler {
    // MARK: - State

    /// Current interaction mode
    private(set) var mode: InteractionMode = .idle

    /// Shape being manipulated
    private(set) var activeShape: (any Shape)?

    /// Handle being dragged (nil if dragging entire shape)
    private(set) var activeHandle: SelectionHandle?

    /// Drag start position
    private(set) var dragStartPosition: CGPoint = .zero

    /// Original shape state before drag
    private(set) var originalShape: (any Shape)?

    /// Selection handle hit tolerance
    let handleTolerance: CGFloat = 12

    // MARK: - Interaction Modes

    enum InteractionMode {
        case idle
        case dragging      // Moving entire shape
        case resizing      // Dragging resize handle
        case rotating      // Dragging rotate handle
        case creating      // Creating new shape
    }

    // MARK: - Selection Handles

    enum SelectionHandle: Equatable {
        // Rectangle handles
        case topLeft, topRight, bottomRight, bottomLeft
        // Ellipse handles
        case top, right, bottom, left
        // Line/Arrow handles
        case startPoint, endPoint
        // Spotlight handles
        case center, edge
        // Rotate handle
        case rotate
    }

    // MARK: - Hit Testing

    /// Find which handle is at a point for a selected shape
    func handleAtPoint(_ point: CGPoint, for shape: any Shape) -> SelectionHandle? {
        guard shape.isSelected else { return nil }

        let tolerance = handleTolerance

        switch shape {
        case let rect as RectangleShape:
            return handleForRectangle(at: point, rect: rect.rect, tolerance: tolerance)

        case let ellipse as EllipseShape:
            return handleForEllipse(at: point, rect: ellipse.rect, tolerance: tolerance)

        case let line as LineShape:
            if pointNearPoint(point, target: line.startPoint, tolerance: tolerance) {
                return .startPoint
            }
            if pointNearPoint(point, target: line.endPoint, tolerance: tolerance) {
                return .endPoint
            }

        case let arrow as ArrowShape:
            if pointNearPoint(point, target: arrow.startPoint, tolerance: tolerance) {
                return .startPoint
            }
            if pointNearPoint(point, target: arrow.endPoint, tolerance: tolerance) {
                return .endPoint
            }

        case let spotlight as SpotlightShape:
            if pointNearPoint(point, target: spotlight.center, tolerance: tolerance) {
                return .center
            }
            // Check edge handles
            let edges = [
                CGPoint(x: spotlight.center.x + spotlight.radius, y: spotlight.center.y),
                CGPoint(x: spotlight.center.x - spotlight.radius, y: spotlight.center.y),
                CGPoint(x: spotlight.center.x, y: spotlight.center.y + spotlight.radius),
                CGPoint(x: spotlight.center.x, y: spotlight.center.y - spotlight.radius)
            ]
            for edge in edges where pointNearPoint(point, target: edge, tolerance: tolerance) {
                return .edge
            }

        default:
            break
        }

        return nil
    }

    // MARK: - Handle Detection Helpers

    private func handleForRectangle(at point: CGPoint, rect: CGRect, tolerance: CGFloat) -> SelectionHandle? {
        let corners = [
            (point: CGPoint(x: rect.minX, y: rect.minY), handle: SelectionHandle.topLeft),
            (point: CGPoint(x: rect.maxX, y: rect.minY), handle: SelectionHandle.topRight),
            (point: CGPoint(x: rect.maxX, y: rect.maxY), handle: SelectionHandle.bottomRight),
            (point: CGPoint(x: rect.minX, y: rect.maxY), handle: SelectionHandle.bottomLeft)
        ]

        for corner in corners {
            if pointNearPoint(point, target: corner.point, tolerance: tolerance) {
                return corner.handle
            }
        }
        return nil
    }

    private func handleForEllipse(at point: CGPoint, rect: CGRect, tolerance: CGFloat) -> SelectionHandle? {
        let handles = [
            (point: CGPoint(x: rect.midX, y: rect.minY), handle: SelectionHandle.top),
            (point: CGPoint(x: rect.maxX, y: rect.midY), handle: SelectionHandle.right),
            (point: CGPoint(x: rect.midX, y: rect.maxY), handle: SelectionHandle.bottom),
            (point: CGPoint(x: rect.minX, y: rect.midY), handle: SelectionHandle.left)
        ]

        for handle in handles {
            if pointNearPoint(point, target: handle.point, tolerance: tolerance) {
                return handle.handle
            }
        }
        return nil
    }

    private func pointNearPoint(_ point: CGPoint, target: CGPoint, tolerance: CGFloat) -> Bool {
        hypot(point.x - target.x, point.y - target.y) <= tolerance
    }

    // MARK: - Drag Management

    /// Start a drag operation
    func startDrag(
        shape: any Shape,
        at point: CGPoint,
        handle: SelectionHandle? = nil
    ) {
        activeShape = shape
        activeHandle = handle
        dragStartPosition = point
        originalShape = shape

        if handle == nil {
            mode = .dragging
        } else {
            switch handle {
            case .rotate:
                mode = .rotating
            default:
                mode = .resizing
            }
        }
    }

    /// Update drag in progress
    func updateDrag(to point: CGPoint) -> (any Shape)? {
        guard let original = originalShape else { return nil }

        let offset = CGSize(
            width: point.x - dragStartPosition.x,
            height: point.y - dragStartPosition.y
        )

        switch mode {
        case .dragging:
            return moveShape(original, by: offset)

        case .resizing:
            return resizeShape(original, at: point)

        case .rotating:
            return rotateShape(original, at: point)

        default:
            return nil
        }
    }

    /// End current drag operation
    func endDrag() {
        mode = .idle
        activeShape = nil
        activeHandle = nil
        dragStartPosition = .zero
        originalShape = nil
    }

    // MARK: - Transform Operations

    private func moveShape(_ shape: any Shape, by offset: CGSize) -> (any Shape)? {
        switch shape {
        case var rect as RectangleShape:
            rect.rect.origin.x += offset.width
            rect.rect.origin.y += offset.height
            return rect

        case var ellipse as EllipseShape:
            ellipse.rect.origin.x += offset.width
            ellipse.rect.origin.y += offset.height
            return ellipse

        case var arrow as ArrowShape:
            arrow.startPoint.x += offset.width
            arrow.startPoint.y += offset.height
            arrow.endPoint.x += offset.width
            arrow.endPoint.y += offset.height
            return arrow

        case var line as LineShape:
            line.startPoint.x += offset.width
            line.startPoint.y += offset.height
            line.endPoint.x += offset.width
            line.endPoint.y += offset.height
            return line

        case var text as TextShape:
            text.position.x += offset.width
            text.position.y += offset.height
            return text

        case var number as NumberShape:
            number.position.x += offset.width
            number.position.y += offset.height
            return number

        case var spotlight as SpotlightShape:
            spotlight.center.x += offset.width
            spotlight.center.y += offset.height
            return spotlight

        default:
            return nil
        }
    }

    private func resizeShape(_ shape: any Shape, at point: CGPoint) -> (any Shape)? {
        guard let handle = activeHandle else { return nil }

        switch (shape, handle) {
        case (var rect as RectangleShape, .topLeft):
            let newRect = CGRect(
                x: point.x,
                y: point.y,
                width: rect.rect.maxX - point.x,
                height: rect.rect.maxY - point.y
            )
            rect.rect = newRect
            return rect

        case (var rect as RectangleShape, .bottomRight):
            let newRect = CGRect(
                x: rect.rect.minX,
                y: rect.rect.minY,
                width: point.x - rect.rect.minX,
                height: point.y - rect.rect.minY
            )
            rect.rect = newRect
            return rect

        case (var ellipse as EllipseShape, .right):
            let newWidth = point.x - ellipse.rect.minX
            ellipse.rect.size.width = max(newWidth, 20)
            return ellipse

        case (var ellipse as EllipseShape, .bottom):
            let newHeight = point.y - ellipse.rect.minY
            ellipse.rect.size.height = max(newHeight, 20)
            return ellipse

        case (var line as LineShape, .endPoint):
            line.endPoint = point
            return line

        case (var line as LineShape, .startPoint):
            line.startPoint = point
            return line

        case (var arrow as ArrowShape, .endPoint):
            arrow.endPoint = point
            return arrow

        case (var arrow as ArrowShape, .startPoint):
            arrow.startPoint = point
            return arrow

        case (var spotlight as SpotlightShape, .edge):
            let radius = hypot(point.x - spotlight.center.x, point.y - spotlight.center.y)
            spotlight.radius = max(radius, 20)
            return spotlight

        default:
            return nil
        }
    }

    private func rotateShape(_ shape: any Shape, at point: CGPoint) -> (any Shape)? {
        // Rotation not implemented in MVP
        // Would require CGAffineTransform or angle property on shapes
        return nil
    }

    // MARK: - Cursor Feedback

    /// Get appropriate cursor for current state
    func cursorForPoint(_ point: CGPoint, on shape: (any Shape)?) -> NSCursor {
        if let shape = shape ?? activeShape,
           let handle = handleAtPoint(point, for: shape) {
            return cursorForHandle(handle)
        }

        if let targetShape = shape ?? activeShape,
           targetShape.hitTest(point: point, tolerance: 5) {
            return .openHand
        }

        return .arrow
    }

    private func cursorForHandle(_ handle: SelectionHandle) -> NSCursor {
        switch handle {
        case .topLeft, .bottomRight:
            return .resizeLeftRight

        case .topRight, .bottomLeft:
            return .resizeLeftRight

        case .top, .bottom:
            return .resizeUpDown

        case .left, .right:
            return .resizeLeftRight

        case .rotate:
            return .closedHand

        case .center:
            return .openHand

        case .startPoint, .endPoint, .edge:
            return .crosshair
        }
    }
}
