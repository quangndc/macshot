// TestAnnotationEngine.swift - Testable version of AnnotationEngine for unit tests
// Part of Phase 04 - Annotation Canvas Tests

import XCTest
@testable import MacShot

/// Testable version of AnnotationEngine without @MainActor and @Observable
class TestAnnotationEngine {
    // MARK: - Shape Management

    /// All shapes on the canvas (layer order = array order)
    private(set) var shapes: [any Shape] = []

    /// Currently selected shape for manipulation
    private(set) var selectedShape: (any Shape)?

    // MARK: - Initialization

    init() {
        // Simple test implementation without UndoManager
    }

    // MARK: - Shape CRUD

    /// Add a shape to the canvas
    func addShape(_ shape: any Shape) {
        shapes.append(shape)
    }

    /// Remove a shape from the canvas
    func removeShape(_ shape: any Shape) {
        if let index = shapes.firstIndex(where: { $0.id == shape.id }) {
            shapes.remove(at: index)
        }
    }

    /// Select a shape (nil deselects all)
    func selectShape(_ shape: (any Shape)?) {
        selectedShape = shape
    }

    /// Get the shape at a given point (for selection)
    func shapeAtPoint(_ point: CGPoint, tolerance: CGFloat = 10.0) -> (any Shape)? {
        // Check shapes in reverse order (top to bottom)
        for shape in shapes.reversed() {
            if shape.hitTest(point: point, tolerance: tolerance) {
                return shape
            }
        }
        return nil
    }

    /// Delete the currently selected shape
    func deleteSelectedShape() {
        if let selected = selectedShape {
            removeShape(selected)
            selectedShape = nil
        }
    }

    /// Clear all shapes from the canvas
    func clearAllShapes() {
        shapes.removeAll()
        selectedShape = nil
    }

    /// Move a shape to the front (top of z-order)
    func bringToFront(_ shape: any Shape) {
        if let index = shapes.firstIndex(where: { $0.id == shape.id }) {
            shapes.remove(at: index)
            shapes.append(shape)
        }
    }

    /// Move a shape to the back (bottom of z-order)
    func sendToBack(_ shape: any Shape) {
        if let index = shapes.firstIndex(where: { $0.id == shape.id }) {
            shapes.remove(at: index)
            shapes.insert(shape, at: 0)
        }
    }

    /// Replace a shape with modified version (for transform operations)
    func replaceShape(_ oldShape: any Shape, with newShape: any Shape) {
        guard let index = shapes.firstIndex(where: { $0.id == oldShape.id }) else {
            return
        }

        shapes[index] = newShape
        selectedShape = newShape
    }

    // MARK: - Computed Properties

    /// Number of shapes on canvas
    var shapeCount: Int {
        shapes.count
    }

    /// Check if canvas is empty
    var isEmpty: Bool {
        shapes.isEmpty
    }

    // Simple test properties - always false in test mode
    var canUndo: Bool { false }
    var canRedo: Bool { false }
    var undoActionName: String? { nil }
    var redoActionName: String? { nil }

    // Stub methods for test compatibility
    func undo() { /* No-op in test mode */ }
    func redo() { /* No-op in test mode */ }
}