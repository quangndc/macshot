// AnnotationCanvas.swift - SwiftUI Canvas view for annotation rendering
// Part of Phase 04 - Annotation Canvas

import SwiftUI
import AppKit

struct AnnotationCanvas: View {
    // MARK: - State

    @State private var engine: AnnotationEngine
    @State private var dragStartPoint: CGPoint?
    @State private var currentDragShape: (any Shape)?

    let backgroundImage: NSImage
    let toolManager: ToolManager

    // MARK: - Initialization

    init(backgroundImage: NSImage, toolManager: ToolManager = ToolManager()) {
        self.backgroundImage = backgroundImage
        self.toolManager = toolManager
        self._engine = State(initialValue: AnnotationEngine())
    }

    // MARK: - Body

    var body: some View {
        Canvas { context, size in
            // Draw background screenshot
            context.draw(
                Image(nsImage: backgroundImage),
                in: CGRect(origin: .zero, size: size)
            )

            // Draw all shapes
            for shape in engine.shapes {
                shape.draw(in: context, rect: CGRect(origin: .zero, size: size))
            }

            // Draw shape being created (during drag)
            if let creatingShape = currentDragShape {
                creatingShape.draw(in: context, rect: CGRect(origin: .zero, size: size))
            }
        }
        .gesture(dragGesture)
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .local)
            .onChanged { value in
                handleDragChanged(value)
            }
            .onEnded { value in
                handleDragEnded(value)
            }
    }

    // MARK: - Drag Handling

    private func handleDragChanged(_ value: DragGesture.Value) {
        let location = value.location

        if dragStartPoint == nil {
            dragStartPoint = location
            createDragShape(at: location)
        }

        updateDragShape(at: location)
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        finalizeDragShape(at: value.location)

        // Reset drag state
        dragStartPoint = nil
        currentDragShape = nil
    }

    // MARK: - Shape Creation During Drag

    private func createDragShape(at point: CGPoint) {
        switch toolManager.currentTool {
        case .select:
            // Try to select existing shape
            if let shape = engine.shapeAtPoint(point) {
                engine.selectShape(shape)
            } else {
                engine.selectShape(nil)
            }
            return

        case .rectangle:
            currentDragShape = RectangleShape(
                rect: CGRect(origin: point, size: .zero),
                style: toolManager.currentStyle
            )

        case .ellipse:
            currentDragShape = EllipseShape(
                rect: CGRect(origin: point, size: .zero),
                style: toolManager.currentStyle
            )

        case .arrow:
            currentDragShape = ArrowShape(
                startPoint: point,
                endPoint: point,
                style: toolManager.currentStyle
            )

        case .line:
            currentDragShape = LineShape(
                startPoint: point,
                endPoint: point,
                style: toolManager.currentStyle
            )

        case .text:
            // Text is added immediately on click, not drag
            let textShape = TextShape.medium(at: point, text: toolManager.currentText, color: toolManager.strokeColor)
            engine.addShape(textShape)
            toolManager.currentText = "Text"

        case .number:
            // Number badge is added immediately on click
            let number = toolManager.nextNumber()
            let numberShape = NumberShape.red(at: point, number: number)
            engine.addShape(numberShape)

        case .spotlight:
            currentDragShape = SpotlightShape(
                center: point,
                radius: 0,
                blurRadius: 20,
                dimOpacity: 0.7
            )
        }
    }

    private func updateDragShape(at point: CGPoint) {
        guard let startPoint = dragStartPoint,
              let shape = currentDragShape else {
            return
        }

        switch toolManager.currentTool {
        case .rectangle, .ellipse:
            // Update rect based on drag
            let rect = CGRect(
                x: min(startPoint.x, point.x),
                y: min(startPoint.y, point.y),
                width: abs(point.x - startPoint.x),
                height: abs(point.y - startPoint.y)
            )

            if var rectShape = shape as? RectangleShape {
                rectShape.rect = rect
                currentDragShape = rectShape
            } else if var ellipseShape = shape as? EllipseShape {
                ellipseShape.rect = rect
                currentDragShape = ellipseShape
            }

        case .arrow, .line:
            // Update end point
            if var arrowShape = shape as? ArrowShape {
                arrowShape.endPoint = point
                currentDragShape = arrowShape
            } else if var lineShape = shape as? LineShape {
                lineShape.endPoint = point
                currentDragShape = lineShape
            }

        case .spotlight:
            // Update radius based on distance
            if var spotlightShape = shape as? SpotlightShape {
                let radius = hypot(point.x - startPoint.x, point.y - startPoint.y)
                spotlightShape.radius = radius
                currentDragShape = spotlightShape
            }

        default:
            break
        }
    }

    private func finalizeDragShape(at point: CGPoint) {
        guard let shape = currentDragShape else { return }

        // Don't add zero-size shapes
        if shape.bounds.width < 5 && shape.bounds.height < 5 {
            return
        }

        // Add to engine
        engine.addShape(shape)
    }

    // MARK: - Keyboard Shortcuts

    // TODO: Implement keyboard shortcuts in Editor UI phase
    // KeyEquivalent API requires proper handling - deferred for now
    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        return .ignored
    }
}

// MARK: - Preview

#Preview {
    AnnotationCanvas(backgroundImage: NSImage(size: NSSize(width: 800, height: 600)))
}
