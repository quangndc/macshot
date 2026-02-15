# Phase 05: Annotation System Validation

**Priority:** MEDIUM
**Status:** Pending
**Estimated Complexity:** Medium

---

## Overview

Fix annotation system edge cases related to input validation, shape constraints, and state management. These fixes ensure the annotation system handles invalid or edge case inputs gracefully.

---

## Issues to Fix

### 1. Invalid Shape Coordinates

**Problem:** No validation for NaN, infinity, or extreme coordinate values
**Location:** All shape models in `Core/Annotation/Models/`

**Impact:**
- Can create invalid shapes
- Export failures
- Rendering artifacts

**Solution:**
```swift
// Add to ShapeProtocol.swift
protocol ShapeProtocol: Identifiable, Equatable, Codable {
    var id: UUID { get }
    var type: ToolType { get }
    var frame: CGRect { get }

    // NEW: Validation
    func isValid() -> Bool
    func normalize() -> Self
}

// Default implementation
extension ShapeProtocol {
    func isValid() -> Bool {
        // Check frame validity
        guard !frame.isEmpty else { return false }
        guard !frame.isInfinite else { return false }
        guard !frame.isNull else { return false }

        // Check for NaN values
        guard !frame.origin.x.isNaN,
              !frame.origin.y.isNaN,
              !frame.size.width.isNaN,
              !frame.size.height.isNaN else {
            return false
        }

        // Check for infinity
        guard !frame.origin.x.isInfinite,
              !frame.origin.y.isInfinite,
              !frame.size.width.isInfinite,
              !frame.size.height.isInfinite else {
            return false
        }

        // Reasonable bounds (optional: within ±100,000 pixels)
        let bounds: CGFloat = 100_000
        guard abs(frame.origin.x) < bounds,
              abs(frame.origin.y) < bounds,
              frame.size.width < bounds,
              frame.size.height < bounds else {
            return false
        }

        return true
    }

    func normalize() -> Self {
        var normalized = self

        // Clamp extreme values
        if let mutable = normalized as? RectangleShape {
            mutable.rect = clampRect(mutable.rect)
            return mutable as! Self
        }

        if let mutable = normalized as? EllipseShape {
            mutable.rect = clampRect(mutable.rect)
            return mutable as! Self
        }

        // ... similar for other shapes ...

        return normalized
    }

    private func clampRect(_ rect: CGRect) -> CGRect {
        let bounds: CGFloat = 100_000

        let x = max(-bounds, min(bounds, rect.origin.x))
        let y = max(-bounds, min(bounds, rect.origin.y))
        let w = max(0, min(bounds, rect.size.width))
        let h = max(0, min(bounds, rect.size.height))

        return CGRect(x: x, y: y, width: w, height: h)
    }
}

// Update ShapeFactory.swift
struct ShapeFactory {
    static func createShape(type: ToolType, points: [CGPoint]) throws -> some ShapeProtocol {
        let shape: ShapeProtocol

        switch type {
        case .rectangle:
            shape = RectangleShape(from: points)
        case .ellipse:
            shape = EllipseShape(from: points)
        // ... other cases ...
        }

        // Validate before returning
        guard shape.isValid() else {
            throw ShapeError.invalidCoordinates(points)
        }

        return shape.normalize() as! some ShapeProtocol
    }
}

enum ShapeError: Error, LocalizedError {
    case invalidCoordinates([CGPoint])

    var errorDescription: String? {
        if case let .invalidCoordinates(points) = self {
            "Invalid coordinates for shape: \(points)"
        }
        return nil
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/Annotation/Models/ShapeProtocol.swift`
- MODIFY: `MacShot/Core/Annotation/Models/*` (all shape types)
- MODIFY: `MacShot/Core/Annotation/Tools/ShapeFactory.swift`

**Testing:**
- Create shapes with NaN values
- Create shapes with infinity
- Create shapes with extreme values
- Verify normalization works

---

### 2. Text Shape Content Validation

**Problem:** Empty or excessively long text strings not handled
**Location:** `Core/Annotation/Models/TextShape.swift`

**Impact:**
- Can create invisible text shapes
- Memory issues with very long text
- Rendering performance

**Solution:**
```swift
// Add to TextShape.swift
struct TextShape: ShapeProtocol {
    let text: String
    let point: CGPoint
    let frame: CGRect
    let id: UUID = UUID()
    let type: ToolType = .text

    // NEW: Constants
    private static let maxTextLength = 1000
    private static let minTextLength = 1

    // NEW: Validation
    func isValid() -> Bool {
        // Check text length
        guard text.count >= Self.minTextLength else { return false }
        guard text.count <= Self.maxTextLength else { return false }

        // Check frame validity
        guard !frame.isEmpty else { return false }
        guard !frame.isInfinite else { return false }

        // Text should contain visible characters
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        return true
    }

    // NEW: Sanitization
    func normalize() -> Self {
        var sanitized = self

        // Trim whitespace
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Limit length
        if trimmed.count > Self.maxTextLength {
            let index = trimmed.index(trimmed.startIndex, offsetBy: Self.maxTextLength)
            trimmed = String(trimmed[..<index])
        }

        // Replace control characters
        trimmed = trimmed.compactMap { char in
            char.isControl ? nil : char
        }

        sanitized.text = trimmed
        return sanitized
    }
}

// Update Text creation in ShapeFactory
struct ShapeFactory {
    static func createTextShape(at point: CGPoint, text: String) throws -> TextShape {
        var shape = TextShape(point: point, text: text)

        // Validate
        guard shape.isValid() else {
            throw ShapeError.invalidText(text)
        }

        // Normalize
        shape = shape.normalize()

        return shape
    }
}

enum ShapeError: Error, LocalizedError {
    case invalidText(String)

    var errorDescription: String? {
        if case let .invalidText(text) = self {
            "Invalid text: '\(text.prefix(50))'"
        }
        return nil
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/Annotation/Models/TextShape.swift`
- MODIFY: `MacShot/Core/Annotation/Tools/ShapeFactory.swift`

**Testing:**
- Empty text string
- Only whitespace
- Very long text
- Control characters
- Unicode text

---

### 3. Shape Minimum Size Enforcement

**Problem:** Inconsistent minimum size handling across shape types
**Location:** All shape models

**Impact:**
- Can create invisible shapes (zero dimensions)
- Poor UX
- Export issues

**Solution:**
```swift
// Add to ShapeProtocol.swift
extension ShapeProtocol {
    private static let minSize: CGFloat = 5.0  // Minimum 5 pixels

    func enforceMinimumSize() -> Self {
        var result = self

        // Ensure minimum dimensions
        let minDim = Self.minSize
        let frame = self.frame

        let newWidth = max(minDim, frame.width)
        let newHeight = max(minDim, frame.height)
        let newFrame = CGRect(
            x: frame.minX,
            y: frame.minY,
            width: newWidth,
            height: newHeight
        )

        // Update shape's frame
        result = result.withFrame(newFrame)

        return result
    }

    func withFrame(_ newFrame: CGRect) -> Self {
        var copy = self
        // This would be implemented per shape type
        // For now, return self
        return self
    }
}

// Implement for RectangleShape
extension RectangleShape {
    func withFrame(_ newFrame: CGRect) -> RectangleShape {
        RectangleShape(
            rect: newFrame,
            strokeWidth: strokeWidth,
            strokeColor: strokeColor,
            fillColor: fillColor
        )
    }

    func isValid() -> Bool {
        // Check minimum size
        guard rect.width >= 5.0, rect.height >= 5.0 else {
            return false
        }

        // Other validations...
        return true
    }
}

// Implement for EllipseShape
extension EllipseShape {
    func withFrame(_ newFrame: CGRect) -> EllipseShape {
        EllipseShape(
            rect: newFrame,
            strokeWidth: strokeWidth,
            strokeColor: strokeColor,
            fillColor: fillColor
        )
    }

    func isValid() -> Bool {
        // Check minimum size
        guard rect.width >= 5.0, rect.height >= 5.0 else {
            return false
        }

        // Other validations...
        return true
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/Annotation/Models/ShapeProtocol.swift`
- MODIFY: `MacShot/Core/Annotation/Models/RectangleShape.swift`
- MODIFY: `MacShot/Core/Annotation/Models/EllipseShape.swift`
- MODIFY: All other shape types

**Testing:**
- Create zero-size shapes
- Create very small shapes
- Verify minimum enforcement

---

### 4. Empty Annotation Export

**Problem:** No validation before exporting empty annotations
**Location:** `AnnotationEngine.swift`, Export system

**Impact:**
- Unnecessary export operations
- Confusing user experience

**Solution:**
```swift
// Add to AnnotationEngine.swift
@MainActor
final class AnnotationEngine: ObservableObject {
    @Published var shapes: [any ShapeProtocol] = []

    // NEW: Check if has annotations
    var hasAnnotations: Bool {
        !shapes.isEmpty
    }

    var annotationCount: Int {
        shapes.count
    }

    // NEW: Export validation
    func canExport() -> Bool {
        hasAnnotations
    }

    func exportAnnotations() async throws -> ExportResult {
        guard canExport() else {
            throw AnnotationError.noAnnotations
        }

        // Continue with export...
    }
}

enum AnnotationError: Error, LocalizedError {
    case noAnnotations

    var errorDescription: String? {
        "No annotations to export"
    }
}

// Update ExportButton
struct ExportButton: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        Button(action: handleExport) {
            Text("Export")
        }
        .disabled(!viewModel.annotationEngine.canExport())
        .help("Export annotated image")
    }

    private func handleExport() {
        Task {
            do {
                try await viewModel.exportAnnotations()
            } catch let error as AnnotationError {
                if error == .noAnnotations {
                    showNoAnnotationsAlert()
                }
            }
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/Annotation/AnnotationEngine.swift`
- MODIFY: `MacShot/Features/Editor/Components/ExportButton.swift`

**Testing:**
- Export with no annotations
- Export with annotations
- Verify button state

---

### 5. Undo/Redo Memory Monitoring

**Problem:** Fixed limit but no memory monitoring
**Location:** `AnnotationEngine.swift`

**Impact:**
- Could exceed memory with complex shapes
- No adaptive behavior
- Potential crashes

**Solution:**
```swift
// Enhance AnnotationEngine.swift
@MainActor
final class AnnotationEngine: ObservableObject {
    @Published var shapes: [any ShapeProtocol] = []
    private let undoManager = UndoManager()
    private let maxUndoLevels = 50

    // NEW: Memory monitoring
    private var currentMemoryUsage: Int64 {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: Int(MemoryLayout<mach_task_basic_info>.size)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $1, &count)
            }
        }

        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }

    private var estimatedShapeMemory: Int64 {
        // Rough estimate: 1KB per shape (overestimate for safety)
        Int64(shapes.count * 1024)
    }

    // NEW: Adaptive undo limit
    private var adaptiveUndoLimit: Int {
        let totalMemory = currentMemoryUsage
        let availableForUndo = 50_000_000  // 50MB max for undo

        if totalMemory > 200_000_000 {  // >200MB used
            return 10  // Reduce limit
        } else if totalMemory > 100_000_000 {  // >100MB used
            return 25  // Moderate limit
        } else {
            return 50  // Full limit
        }
    }

    func addShape(_ shape: some ShapeProtocol) {
        let newShape = shape.enforceMinimumSize().normalize()

        guard newShape.isValid() else {
            return
        }

        undoManager.registerUndo(withTarget: self) { target in
            target.shapes.removeLast()
        }

        shapes.append(newShape)

        // Prune if over limit
        pruneUndoStack()
    }

    private func pruneUndoStack() {
        let limit = adaptiveUndoLimit

        while undoManager.levelsOfUndo > limit {
            if !undoManager.undo() {
                break
            }
        }
    }

    // NEW: Memory warning
    func checkMemoryPressure() -> Bool {
        let usage = currentMemoryUsage
        return usage > 150_000_000  // Warn at 150MB
    }
}
```

**Files:**
- MODIFY: `MacShot/Core/Annotation/AnnotationEngine.swift`

**Testing:**
- Add many shapes
- Monitor memory usage
- Verify adaptive limits

---

## Success Criteria

- [ ] Shape coordinates validated and normalized
- [ ] Text content properly sanitized
- [ ] Minimum size enforced consistently
- [ ] Empty annotation export prevented
- [ ] Memory monitoring implemented
- [ ] All annotation edge cases tested

---

## Next Steps

After completing this phase:
1. Move to [Phase 06: Export System Error Handling](./phase-06-export-fixes.md)
2. Update annotation tests
3. Verify memory usage

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Validation false positives | Medium | Test various inputs |
| Performance impact | Low | Validation is fast |
| Memory estimate accuracy | Low | Conservative estimates |
