// AnnotationEngine.swift - Coordinates drawing, shapes, and undo/redo
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import Observation

@Observable
@MainActor
final class AnnotationEngine {
    // MARK: - Shape Management

    /// All shapes on the canvas (layer order = array order)
    private(set) var shapes: [any Shape] = []

    /// Currently selected shape for manipulation
    private(set) var selectedShape: (any Shape)?

    /// Undo/redo manager
    private var undoManager = UndoManager()

    /// Maximum undo stack size
    private let maxUndoLevels = 50

    // MARK: - Initialization

    init() {
        undoManager.levelsOfUndo = maxUndoLevels
    }

    // MARK: - Memory Monitoring

    /// Current memory usage in bytes
    private var currentMemoryUsage: Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }

    /// Estimated memory used by shapes
    private var estimatedShapeMemory: Int64 {
        // Rough estimate: 1KB per shape (overestimate for safety)
        Int64(shapes.count * 1024)
    }

    /// Adaptive undo limit based on memory usage
    private var adaptiveUndoLimit: Int {
        let totalMemory = currentMemoryUsage

        if totalMemory > 200_000_000 {  // >200MB used
            return 10  // Reduce limit
        } else if totalMemory > 100_000_000 {  // >100MB used
            return 25  // Moderate limit
        } else {
            return 50  // Full limit
        }
    }

    /// Check if memory pressure is high
    func checkMemoryPressure() -> Bool {
        let usage = currentMemoryUsage
        return usage > 150_000_000  // Warn at 150MB
    }

    // MARK: - Shape CRUD

    /// Add a new shape to the canvas
    func addShape(_ shape: any Shape) {
        // Register undo action
        undoManager.registerUndo(withTarget: self) { target in
            target.removeShape(shape)
        }
        undoManager.setActionName("Add Shape")

        shapes.append(shape)
    }

    /// Remove a shape from the canvas
    func removeShape(_ shape: any Shape) {
        // Register undo action
        undoManager.registerUndo(withTarget: self) { target in
            target.addShape(shape)
        }
        undoManager.setActionName("Remove Shape")

        shapes.removeAll { $0.id == shape.id }

        // Clear selection if removed shape was selected
        if selectedShape?.id == shape.id {
            selectedShape = nil
        }
    }

    /// Replace a shape with modified version (for transform operations)
    func replaceShape(_ oldShape: any Shape, with newShape: any Shape) {
        guard let index = shapes.firstIndex(where: { $0.id == oldShape.id }) else {
            return
        }

        // Register undo action
        undoManager.registerUndo(withTarget: self) { target in
            target.replaceShape(newShape, with: oldShape)
        }
        undoManager.setActionName("Modify Shape")

        shapes[index] = newShape

        // Update selection if needed
        if selectedShape?.id == oldShape.id {
            selectedShape = newShape
        }
    }

    /// Bring shape to front (top of layer stack)
    func bringToFront(_ shape: any Shape) {
        guard let index = shapes.firstIndex(where: { $0.id == shape.id }) else {
            return
        }

        undoManager.registerUndo(withTarget: self) { target in
            target.sendToBack(shape)
        }
        undoManager.setActionName("Bring to Front")

        shapes.remove(at: index)
        shapes.append(shape)
    }

    /// Send shape to back (bottom of layer stack)
    func sendToBack(_ shape: any Shape) {
        guard let index = shapes.firstIndex(where: { $0.id == shape.id }) else {
            return
        }

        undoManager.registerUndo(withTarget: self) { target in
            target.bringToFront(shape)
        }
        undoManager.setActionName("Send to Back")

        shapes.remove(at: index)
        shapes.insert(shape, at: 0)
    }

    // MARK: - Selection

    /// Select a shape (nil deselects all)
    func selectShape(_ shape: (any Shape)?) {
        // Deselect current selection
        if let current = selectedShape {
            var mutable = current
            mutable.isSelected = false
            replaceShape(current, with: mutable)
        }

        // Set new selection
        selectedShape = shape

        // Mark new selection
        if let newShape = shape {
            var mutable = newShape
            mutable.isSelected = true
            replaceShape(newShape, with: mutable)
        }
    }

    /// Find shape at point for selection
    func shapeAtPoint(_ point: CGPoint, tolerance: CGFloat = 10) -> (any Shape)? {
        // Search from top (end) to bottom (start) for first hit
        for shape in shapes.reversed() {
            if shape.hitTest(point: point, tolerance: tolerance) {
                return shape
            }
        }
        return nil
    }

    /// Delete selected shape
    func deleteSelectedShape() {
        guard let shape = selectedShape else { return }
        removeShape(shape)
    }

    // MARK: - Clear

    /// Remove all shapes from canvas
    func clearAllShapes() {
        // Store for undo
        let previousShapes = shapes

        undoManager.registerUndo(withTarget: self) { target in
            target.restoreShapes(previousShapes)
        }
        undoManager.setActionName("Clear All")

        shapes.removeAll()
        selectedShape = nil
    }

    private func restoreShapes(_ shapes: [any Shape]) {
        undoManager.registerUndo(withTarget: self) { target in
            target.clearAllShapes()
        }

        self.shapes = shapes
        selectedShape = nil
    }

    // MARK: - Undo/Redo

    /// Undo last action
    func undo() {
        undoManager.undo()
    }

    /// Redo last undone action
    func redo() {
        undoManager.redo()
    }

    /// Check if undo is available
    var canUndo: Bool {
        undoManager.canUndo
    }

    /// Check if redo is available
    var canRedo: Bool {
        undoManager.canRedo
    }

    /// Human-readable undo action name
    var undoActionName: String? {
        undoManager.undoActionName
    }

    /// Human-readable redo action name
    var redoActionName: String? {
        undoManager.redoActionName
    }

    // MARK: - Layer Queries

    /// Number of shapes on canvas
    var shapeCount: Int {
        shapes.count
    }

    /// Check if canvas is empty
    var isEmpty: Bool {
        shapes.isEmpty
    }

    // MARK: - Export Validation

    /// Check if has annotations for export
    var hasAnnotations: Bool {
        !shapes.isEmpty
    }

    /// Check if can export (has valid annotations)
    func canExport() -> Bool {
        hasAnnotations
    }

    /// Export annotations with validation
    func exportAnnotations() async throws -> [any Shape] {
        guard canExport() else {
            throw AnnotationError.noAnnotations
        }

        return shapes
    }
}

// MARK: - Annotation Errors

enum AnnotationError: Error, LocalizedError {
    case noAnnotations

    var errorDescription: String? {
        switch self {
        case .noAnnotations:
            return "No annotations to export"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noAnnotations:
            return "Add annotations before exporting"
        }
    }
}

// MARK: - Shape Mutation Helpers

extension AnnotationEngine {
    /// Update a shape's property with undo support
    func updateShape<T: Shape>(
        _ shape: T,
        keyPath: WritableKeyPath<T, Bool>,
        value: Bool
    ) {
        var copy = shape
        copy[keyPath: keyPath] = value
        replaceShape(shape, with: copy)
    }

    /// Update a shape's position (for shapes with CGPoint position)
    func moveShape<T: Shape>(
        _ shape: T,
        offset: CGSize
    ) -> T? where T: PositionalShape {
        var copy = shape
        copy.position = CGPoint(
            x: shape.position.x + offset.width,
            y: shape.position.y + offset.height
        )
        replaceShape(shape, with: copy)
        return copy
    }
}

/// Protocol for shapes that have a position property
protocol PositionalShape: Shape {
    var position: CGPoint { get set }
}

// Extend relevant shapes to conform
extension TextShape: PositionalShape {}
extension NumberShape: PositionalShape {}
// SpotlightShape uses 'center' instead of 'position', handled separately
