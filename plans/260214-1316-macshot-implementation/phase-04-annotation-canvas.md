---
title: "Phase 03 - Annotation Canvas"
description: "Drawing canvas with shapes, text, and transforms for screenshot annotation"
status: completed
priority: P1
effort: 10h
branch: main
tags: [canvas, drawing, annotation, swiftui]
created: 2026-02-14
---

## Context Links

- [SwiftUI Canvas Drawing Research](../reports/researcher-260214-1310-swiftui-canvas-drawing.md) - Complete drawing guide
- [Transform Operations](../reports/researcher-260214-1310-swiftui-canvas-drawing.md#5-transform-operations)
- [Undo/Redo Pattern](../reports/researcher-260214-1310-swiftui-canvas-drawing.md#6-undoredo-with-undomanager)

## Overview

**Priority**: P1 (Core annotation feature)
**Status**: Completed
**Description**: SwiftUI Canvas-based annotation system with shape tools, text, transforms, and undo/redo.
**Completion Date**: 2026-02-14

## Key Insights

From research:
- **SwiftUI Canvas** - Declarative drawing, auto-redraw
- **Core Graphics** - For complex shapes/performance
- **UndoManager** - Built-in undo/redo support
- **Transform operations** - Move, rotate, scale
- **Custom shapes** - Arrow, number badge

## Requirements

### Functional
- Shape tools: Rectangle, Ellipse, Arrow, Line
- Text annotation with font/color
- Number badges (1, 2, 3...)
- Spotlight/blur effect
- Selection and transform (move, resize, rotate)
- Undo/redo support
- Layer ordering

### Non-Functional
- 60fps rendering
- < 16ms draw time
- Smooth interactions
- Memory efficient

## Architecture

```
Core/Annotation/
├── AnnotationCanvas.swift         # SwiftUI Canvas view
├── AnnotationEngine.swift         # Drawing coordinator
├── Models/
│   ├── ShapeProtocol.swift        # Shape interface
│   ├── RectangleShape.swift
│   ├── EllipseShape.swift
│   ├── ArrowShape.swift
│   ├── LineShape.swift
│   ├── TextShape.swift
│   ├── NumberShape.swift
│   └── SpotlightShape.swift
├── Tools/
│   ├── ToolType.swift             # Current tool enum
│   ├── ToolManager.swift          # Tool state
│   └── ShapeFactory.swift         # Shape creation
└── UndoManager.swift              # Undo/redo stack
```

### Data Flow

```
User Input → ToolManager → ShapeFactory → AnnotationEngine → Canvas Render
                 ↓                                      ↓
            Current Tool                          Shapes Array
                                                      ↓
                                                 UndoManager
```

## Related Code Files

### Create
- `MacShot/Core/Annotation/AnnotationCanvas.swift`
- `MacShot/Core/Annotation/AnnotationEngine.swift`
- `MacShot/Core/Annotation/Models/ShapeProtocol.swift`
- `MacShot/Core/Annotation/Models/RectangleShape.swift`
- `MacShot/Core/Annotation/Models/EllipseShape.swift`
- `MacShot/Core/Annotation/Models/ArrowShape.swift`
- `MacShot/Core/Annotation/Models/LineShape.swift`
- `MacShot/Core/Annotation/Models/TextShape.swift`
- `MacShot/Core/Annotation/Models/NumberShape.swift`
- `MacShot/Core/Annotation/Models/SpotlightShape.swift`
- `MacShot/Core/Annotation/Tools/ToolType.swift`
- `MacShot/Core/Annotation/Tools/ToolManager.swift`
- `MacShot/Core/Annotation/Tools/ShapeFactory.swift`
- `MacShot/Core/Annotation/UndoManager.swift`

## Implementation Steps

### 1. Base Shape Protocol (1.5h)

```swift
// ShapeProtocol.swift
protocol Shape: Identifiable {
    var id: UUID { get }
    var bounds: CGRect { get }
    var isSelected: Bool { get set }

    func path(in rect: CGRect) -> Path
    func draw(in context: GraphicsContext, rect: CGRect)
}

struct ShapeStyle {
    var strokeColor: Color
    var fillColor: Color?
    var strokeWidth: CGFloat
    var opacity: Double
}
```

### 2. Shape Implementations (3h)

```swift
// RectangleShape.swift
struct RectangleShape: Shape {
    let id = UUID()
    var rect: CGRect
    var style: ShapeStyle
    var isSelected = false

    func path(in rect: CGRect) -> Path {
        Path(Rectangle().path(in: self.rect))
    }

    func draw(in context: GraphicsContext, rect: CGRect) {
        if let fill = style.fillColor {
            context.fill(path(in: rect), with: .color(fill))
        }
        context.stroke(path(in: rect), with: .color(style.strokeColor), lineWidth: style.strokeWidth)
    }
}

// ArrowShape.swift
struct ArrowShape: Shape {
    let startPoint: CGPoint
    let endPoint: CGPoint
    var style: ShapeStyle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Draw arrow shaft
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        // Draw arrow head
        // ... (arrow head logic)
        return path
    }
}
```

### 3. Canvas View (2h)

```swift
// AnnotationCanvas.swift
struct AnnotationCanvas: View {
    @StateObject private var engine: AnnotationEngine
    let backgroundImage: NSImage

    var body: some View {
        Canvas { context, size in
            // Draw background image
            context.draw(Image(nsImage: backgroundImage), in: CGRect(origin: .zero, size: size))

            // Draw all shapes
            for shape in engine.shapes {
                shape.draw(in: context, rect: CGRect(origin: .zero, size: size))
            }

            // Draw selection handles
            if let selected = engine.selectedShape {
                drawSelectionHandles(for: selected, in: context)
            }
        }
        .gesture(dragGesture)
    }
}
```

### 4. Tool Manager (1.5h)

```swift
// ToolManager.swift
enum ToolType: CaseIterable {
    case select
    case rectangle
    case ellipse
    case arrow
    case line
    case text
    case number
    case spotlight
}

@Observable
final class ToolManager {
    var currentTool: ToolType = .select
    var currentStyle: ShapeStyle = .default
    var currentNumber: Int = 1
}
```

### 5. Annotation Engine (1h)

```swift
// AnnotationEngine.swift
@Observable
final class AnnotationEngine {
    var shapes: [any Shape] = []
    var selectedShape: (any Shape)?
    private let undoManager = UndoManager()

    func addShape(_ shape: any Shape) {
        undoManager.registerUndo(withTarget: self) { $0.removeShape(shape) }
        shapes.append(shape)
    }

    func removeShape(_ shape: any Shape) {
        undoManager.registerUndo(withTarget: self) { $0.addShape(shape) }
        shapes.removeAll { $0.id == shape.id }
    }

    func undo() { undoManager.undo() }
    func redo() { undoManager.redo() }
}
```

### 6. Interaction Handlers (1h)

```swift
// Drag gesture for drawing
var dragGesture: some Gesture {
    DragGesture(coordinateSpace: .global)
        .onChanged { value in
            handleDragChanged(value)
        }
        .onEnded { value in
            handleDragEnded(value)
        }
}
```

## Todo List

- [x] Create ShapeProtocol
- [x] Implement RectangleShape
- [x] Implement EllipseShape
- [x] Implement ArrowShape
- [x] Implement LineShape
- [x] Implement TextShape
- [x] Implement NumberShape
- [x] Implement SpotlightShape (blur effect)
- [x] Create Canvas view
- [x] Implement ToolManager
- [x] Implement AnnotationEngine
- [x] Add drag gesture handling
- [x] Implement selection handles
- [x] Implement transform operations (move, resize, rotate)
- [x] Integrate UndoManager
- [x] Add keyboard shortcuts (Cmd+Z, Cmd+Shift+Z)
- [x] Test with multiple shapes
- [x] Verify 60fps rendering

## Success Criteria

- [x] All 7 shape tools functional
- [x] Shapes selectable and movable
- [x] Undo/redo works for all operations
- [x] Canvas renders at 60fps
- [x] Text input working
- [x] Number auto-increment
- [x] Spotlight blur effect renders

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Canvas performance | Medium | Limit shape count, use CG for complex |
| Transform complexity | Medium | Start with move only, add resize/rotate |
| Undo stack memory | Low | Limit to 50 operations |

## Security Considerations

- No sensitive data in shapes
- Text input sanitized
- Memory limits on undo stack

## Completion Summary

### Achievements ✅

All annotation canvas features have been successfully implemented:
- **Shape Tools**: All 7 tools (Rectangle, Ellipse, Arrow, Line, Text, Number, Spotlight) are functional
- **Selection System**: Shapes can be selected and moved with visual feedback
- **Transform Operations**: Full support for move, resize, and rotate operations
- **Undo/Redo**: Complete undo/redo functionality with keyboard shortcuts (Cmd+Z, Cmd+Shift+Z)
- **Performance**: Canvas renders at 60fps with draw times under 16ms
- **Layer System**: Proper layer ordering and z-index management
- **Text Input**: Inline text editing with font and color customization
- **Number Badges**: Auto-incrementing numbering system

### Key Implementation Details

- Used SwiftUI Canvas for declarative drawing with automatic redrawing
- Implemented a Shape protocol for extensible shape system
- Created comprehensive shape implementations with Core Graphics for performance
- Integrated UndoManager for seamless undo/redo operations
- Implemented drag gesture handling for intuitive shape creation and manipulation
- Added selection handles with resize and rotate controls
- Optimized rendering for 60fps performance

### Technical Architecture

The annotation system follows MVVM architecture with:
- **AnnotationCanvas**: SwiftUI view for rendering
- **AnnotationEngine**: Coordinator managing shapes and state
- **ShapeProtocol**: Common interface for all shapes
- **ToolManager**: Current tool and style management
- **UndoManager**: Built-in undo/redo support

## Next Steps

Proceed to **Phase 05 - Editor UI** where:
- Annotation canvas will be integrated into the main editor window
- Toolbar and palette UI will be implemented
- Export options will be added to the editor interface
