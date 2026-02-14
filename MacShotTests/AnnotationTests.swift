// AnnotationTests.swift - Comprehensive tests for annotation canvas implementation
// Tests for Phase 04 - Annotation Canvas

import XCTest
@testable import MacShot

final class AnnotationTests: XCTestCase {

    var engine: TestAnnotationEngine!
    var toolManager: ToolManager!

    override func setUp() {
        super.setUp()
        engine = TestAnnotationEngine()
        toolManager = ToolManager()
    }

    override func tearDown() {
        engine = nil
        toolManager = nil
        super.tearDown()
    }

    // MARK: - Shape Protocol Conformance Tests

    func testRectangleShapeConformsToShapeProtocol() {
        let rectangle = RectangleShape(
            rect: CGRect(x: 10, y: 10, width: 100, height: 50),
            style: .default
        )

        XCTAssertNotNil(rectangle.id)
        XCTAssertEqual(rectangle.bounds, CGRect(x: 10, y: 10, width: 100, height: 50))
        XCTAssertFalse(rectangle.isSelected)
    }

    func testEllipseShapeConformsToShapeProtocol() {
        let ellipse = EllipseShape(
            rect: CGRect(x: 20, y: 20, width: 80, height: 80),
            style: .default
        )

        XCTAssertNotNil(ellipse.id)
        XCTAssertEqual(ellipse.bounds, CGRect(x: 20, y: 20, width: 80, height: 80))
        XCTAssertFalse(ellipse.isSelected)
    }

    func testLineShapeConformsToShapeProtocol() {
        let line = LineShape(
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 50, y: 50),
            style: .default
        )

        XCTAssertNotNil(line.id)
        XCTAssertEqual(line.bounds, CGRect(x: 0, y: 0, width: 50, height: 50))
        XCTAssertFalse(line.isSelected)
    }

    func testArrowShapeConformsToShapeProtocol() {
        let arrow = ArrowShape(
            startPoint: CGPoint(x: 10, y: 10),
            endPoint: CGPoint(x: 100, y: 100),
            style: .default
        )

        XCTAssertNotNil(arrow.id)
        XCTAssertNotNil(arrow.bounds)
        XCTAssertFalse(arrow.isSelected)
    }

    func testTextShapeConformsToShapeProtocol() {
        let text = TextShape(position: CGPoint(x: 50, y: 50), text: "Test Text")

        XCTAssertNotNil(text.id)
        XCTAssertNotNil(text.bounds)
        XCTAssertFalse(text.isSelected)
    }

    func testNumberShapeConformsToShapeProtocol() {
        let number = NumberShape(position: CGPoint(x: 75, y: 75), number: 42)

        XCTAssertNotNil(number.id)
        XCTAssertEqual(number.bounds, CGRect(x: 59, y: 59, width: 32, height: 32))
        XCTAssertFalse(number.isSelected)
    }

    func testSpotlightShapeConformsToShapeProtocol() {
        let spotlight = SpotlightShape(center: CGPoint(x: 100, y: 100), radius: 50)

        XCTAssertNotNil(spotlight.id)
        XCTAssertEqual(spotlight.center, CGPoint(x: 100, y: 100))
        XCTAssertEqual(spotlight.radius, 50)
        XCTAssertFalse(spotlight.isSelected)
    }

    // MARK: - ToolManager State Management Tests

    func testToolManagerInitialState() {
        XCTAssertEqual(toolManager.currentTool, .select)
        XCTAssertEqual(toolManager.strokeColor, .red)
        XCTAssertEqual(toolManager.strokeWidth, 3.0)
        XCTAssertEqual(toolManager.opacity, 1.0)
        XCTAssertNil(toolManager.fillColor)
    }

    func testToolManagerToolSelection() {
        toolManager.selectTool(.rectangle)
        XCTAssertEqual(toolManager.currentTool, .rectangle)

        toolManager.selectTool(.text)
        XCTAssertEqual(toolManager.currentTool, .text)

        toolManager.selectTool(.spotlight)
        XCTAssertEqual(toolManager.currentTool, .spotlight)
    }

    func testToolManagerStyleProperties() {
        // Test stroke color
        toolManager.setStrokeColor(.blue)
        XCTAssertEqual(toolManager.strokeColor, .blue)

        // Test fill color
        toolManager.setFillColor(.yellow)
        XCTAssertEqual(toolManager.fillColor, .yellow)

        toolManager.setFillColor(nil)
        XCTAssertNil(toolManager.fillColor)

        // Test stroke width with clamping
        toolManager.setStrokeWidth(0.1) // Should be clamped to 0.5
        XCTAssertEqual(toolManager.strokeWidth, 0.5)

        toolManager.setStrokeWidth(25.0) // Should be clamped to 20
        XCTAssertEqual(toolManager.strokeWidth, 20.0)

        toolManager.setStrokeWidth(10.0)
        XCTAssertEqual(toolManager.strokeWidth, 10.0)

        // Test opacity with clamping
        toolManager.setOpacity(0.0) // Should be clamped to 0.1
        XCTAssertEqual(toolManager.opacity, 0.1)

        toolManager.setOpacity(1.1) // Should be clamped to 1.0
        XCTAssertEqual(toolManager.opacity, 1.0)
    }

    func testToolManagerNumberCounter() {
        XCTAssertEqual(toolManager.currentNumber, 1)

        let firstNumber = toolManager.nextNumber()
        XCTAssertEqual(firstNumber, 1)
        XCTAssertEqual(toolManager.currentNumber, 2)

        let secondNumber = toolManager.nextNumber()
        XCTAssertEqual(secondNumber, 2)
        XCTAssertEqual(toolManager.currentNumber, 3)

        toolManager.resetNumberCounter()
        XCTAssertEqual(toolManager.currentNumber, 1)
    }

    func testToolManagerTextSettings() {
        toolManager.setText("Hello World")
        XCTAssertEqual(toolManager.currentText, "Hello World")

        toolManager.setText("") // Should default to "Text"
        XCTAssertEqual(toolManager.currentText, "Text")

        toolManager.setFontSize(24.0)
        XCTAssertEqual(toolManager.currentFontSize, 24.0)

        toolManager.setFontSize(5.0) // Should be clamped to 10
        XCTAssertEqual(toolManager.currentFontSize, 10.0)

        toolManager.setFontSize(80.0) // Should be clamped to 72
        XCTAssertEqual(toolManager.currentFontSize, 72.0)
    }

    func testToolManagerSpotlightSettings() {
        toolManager.setSpotlightRadius(150.0)
        XCTAssertEqual(toolManager.spotlightRadius, 150.0)

        toolManager.setSpotlightRadius(10.0) // Should be clamped to 20
        XCTAssertEqual(toolManager.spotlightRadius, 20.0)

        toolManager.setSpotlightRadius(400.0) // Should be clamped to 300
        XCTAssertEqual(toolManager.spotlightRadius, 300.0)
    }

    func testToolManagerPresetStyles() {
        toolManager.applyRedPreset()
        XCTAssertEqual(toolManager.strokeColor, .red)
        XCTAssertNil(toolManager.fillColor)
        XCTAssertEqual(toolManager.strokeWidth, 3.0)
        XCTAssertEqual(toolManager.opacity, 1.0)

        toolManager.applyBluePreset()
        XCTAssertEqual(toolManager.strokeColor, .blue)

        toolManager.applyGreenPreset()
        XCTAssertEqual(toolManager.strokeColor, .green)

        toolManager.applyHighlightPreset()
        XCTAssertEqual(toolManager.strokeColor, .yellow)
        XCTAssertEqual(toolManager.fillColor, .yellow.opacity(0.3))
    }

    func testToolManagerConvenienceProperties() {
        // Test tool mode helpers
        toolManager.selectTool(.select)
        XCTAssertTrue(toolManager.isSelecting)
        XCTAssertFalse(toolManager.isDrawing)
        XCTAssertFalse(toolManager.isAnnotating)
        XCTAssertFalse(toolManager.isCreatingEffect)

        toolManager.selectTool(.rectangle)
        XCTAssertFalse(toolManager.isSelecting)
        XCTAssertTrue(toolManager.isDrawing)
        XCTAssertFalse(toolManager.isAnnotating)
        XCTAssertFalse(toolManager.isCreatingEffect)

        toolManager.selectTool(.text)
        XCTAssertFalse(toolManager.isSelecting)
        XCTAssertFalse(toolManager.isDrawing)
        XCTAssertTrue(toolManager.isAnnotating)
        XCTAssertFalse(toolManager.isCreatingEffect)

        toolManager.selectTool(.spotlight)
        XCTAssertFalse(toolManager.isSelecting)
        XCTAssertFalse(toolManager.isDrawing)
        XCTAssertFalse(toolManager.isAnnotating)
        XCTAssertTrue(toolManager.isCreatingEffect)
    }

    // MARK: - AnnotationEngine Undo/Redo Tests

    func testAnnotationEngineInitialState() {
        XCTAssertTrue(engine.isEmpty)
        XCTAssertEqual(engine.shapeCount, 0)
        XCTAssertNil(engine.selectedShape)
        XCTAssertFalse(engine.canUndo)
        XCTAssertFalse(engine.canRedo)
    }

    func testAddShape() {
        let rectangle = RectangleShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50), style: .default)

        engine.addShape(rectangle)

        XCTAssertEqual(engine.shapeCount, 1)
        XCTAssertFalse(engine.isEmpty)
        XCTAssertNotNil(engine.shapes.first)
        XCTAssertFalse(engine.canUndo)
        XCTAssertFalse(engine.canRedo)
    }

    func testRemoveShape() {
        let rectangle = RectangleShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50), style: .default)
        engine.addShape(rectangle)

        engine.removeShape(rectangle)

        XCTAssertEqual(engine.shapeCount, 0)
        XCTAssertTrue(engine.isEmpty)
    }

    func testSelectShape() {
        let rectangle = RectangleShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50), style: .default)
        engine.addShape(rectangle)

        engine.selectShape(rectangle)

        XCTAssertEqual(engine.selectedShape?.id, rectangle.id)

        // Deselect
        engine.selectShape(nil)
        XCTAssertNil(engine.selectedShape)
    }

    func testShapeAtPoint() {
        let rectangle = RectangleShape(rect: CGRect(x: 10, y: 10, width: 100, height: 100), style: .default)
        engine.addShape(rectangle)

        // Point inside rectangle
        let insidePoint = CGPoint(x: 50, y: 50)
        XCTAssertNotNil(engine.shapeAtPoint(insidePoint))

        // Point outside rectangle
        let outsidePoint = CGPoint(x: 200, y: 200)
        XCTAssertNil(engine.shapeAtPoint(outsidePoint))

        // Point with tolerance
        let nearPoint = CGPoint(x: 115, y: 115) // 5pt outside with default tolerance
        XCTAssertNotNil(engine.shapeAtPoint(nearPoint))
    }

    func testDeleteSelectedShape() {
        let rectangle = RectangleShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50), style: .default)
        engine.addShape(rectangle)
        engine.selectShape(rectangle)

        XCTAssertEqual(engine.shapeCount, 1)

        engine.deleteSelectedShape()

        XCTAssertEqual(engine.shapeCount, 0)
        XCTAssertNil(engine.selectedShape)
    }

    func testClearAllShapes() {
        let rectangle = RectangleShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50), style: .default)
        let circle = EllipseShape(rect: CGRect(x: 60, y: 60, width: 40, height: 40), style: .default)

        engine.addShape(rectangle)
        engine.addShape(circle)

        XCTAssertEqual(engine.shapeCount, 2)

        engine.clearAllShapes()

        XCTAssertEqual(engine.shapeCount, 0)
        XCTAssertTrue(engine.isEmpty)
        XCTAssertNil(engine.selectedShape)
    }

    func testBringToFront() {
        let rectangle = RectangleShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50), style: .default)
        let circle = EllipseShape(rect: CGRect(x: 60, y: 60, width: 40, height: 40), style: .default)
        let line = LineShape(startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 100, y: 100), style: .default)

        engine.addShape(rectangle) // Index 0
        engine.addShape(circle)     // Index 1
        engine.addShape(line)      // Index 2 (top)

        XCTAssertEqual(engine.shapes.count, 3)
        XCTAssertEqual(engine.shapes[2].id, line.id)

        engine.bringToFront(rectangle)

        XCTAssertEqual(engine.shapes.count, 3)
        XCTAssertEqual(engine.shapes[2].id, rectangle.id) // Should now be on top
    }

    func testSendToBack() {
        let rectangle = RectangleShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50), style: .default)
        let circle = EllipseShape(rect: CGRect(x: 60, y: 60, width: 40, height: 40), style: .default)

        engine.addShape(rectangle) // Index 0
        engine.addShape(circle)     // Index 1 (top)

        XCTAssertEqual(engine.shapes.count, 2)
        XCTAssertEqual(engine.shapes[1].id, circle.id)

        engine.sendToBack(circle)

        XCTAssertEqual(engine.shapes.count, 2)
        XCTAssertEqual(engine.shapes[0].id, circle.id) // Should now be at bottom
    }

    func testUndoRedoFunctionality() {
        let rectangle = RectangleShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50), style: .default)
        let circle = EllipseShape(rect: CGRect(x: 60, y: 60, width: 40, height: 40), style: .default)

        // Add shapes
        engine.addShape(rectangle)
        engine.addShape(circle)

        XCTAssertEqual(engine.shapeCount, 2)

        // Undo (should remove circle)
        XCTAssertTrue(engine.canUndo)
        XCTAssertEqual(engine.undoActionName, "Add Shape")
        engine.undo()

        XCTAssertEqual(engine.shapeCount, 1)

        // Redo (should restore circle)
        XCTAssertTrue(engine.canRedo)
        XCTAssertEqual(engine.redoActionName, "Add Shape")
        engine.redo()

        XCTAssertEqual(engine.shapeCount, 2)
    }

    func testMultipleUndoRedoActions() {
        let shapes = (1...5).compactMap { i -> (any Shape)? in
            RectangleShape(rect: CGRect(x: i * 20, y: i * 20, width: 30, height: 30), style: .default)
        }

        // Add 5 shapes
        shapes.forEach { engine.addShape($0) }
        XCTAssertEqual(engine.shapeCount, 5)

        // Undo 3 times
        for _ in 0..<3 {
            XCTAssertTrue(engine.canUndo)
            engine.undo()
        }

        XCTAssertEqual(engine.shapeCount, 2)

        // Redo 2 times
        for _ in 0..<2 {
            XCTAssertTrue(engine.canRedo)
            engine.redo()
        }

        XCTAssertEqual(engine.shapeCount, 4)
    }

    func testShapeReplaceOperation() {
        let original = RectangleShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50), style: .default)
        let modified = RectangleShape(rect: CGRect(x: 10, y: 10, width: 70, height: 70), style: .default)

        engine.addShape(original)
        engine.selectShape(original)

        engine.replaceShape(original, with: modified)

        XCTAssertEqual(engine.shapeCount, 1)
        XCTAssertEqual(engine.selectedShape?.id, modified.id)
        XCTAssertEqual((engine.selectedShape as? RectangleShape)?.rect, CGRect(x: 10, y: 10, width: 70, height: 70))
    }

    // MARK: - ShapeFactory Tests

    func testShapeFactoryCreatesCorrectShapes() {
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: 50, y: 50)
        let style = ShapeStyle(strokeColor: .red, fillColor: nil, strokeWidth: 3, opacity: 1.0)

        // Test rectangle creation
        if let rectangle = ShapeFactory.createShape(tool: .rectangle, startPoint: startPoint, endPoint: endPoint, style: style, toolManager: toolManager) {
            XCTAssertNotNil(rectangle.id)
            XCTAssert(rectangle is RectangleShape)
        } else {
            XCTFail("Failed to create rectangle")
        }

        // Test ellipse creation
        if let ellipse = ShapeFactory.createShape(tool: .ellipse, startPoint: startPoint, endPoint: endPoint, style: style, toolManager: toolManager) {
            XCTAssertNotNil(ellipse.id)
            XCTAssert(ellipse is EllipseShape)
        } else {
            XCTFail("Failed to create ellipse")
        }

        // Test arrow creation
        if let arrow = ShapeFactory.createShape(tool: .arrow, startPoint: startPoint, endPoint: endPoint, style: style, toolManager: toolManager) {
            XCTAssertNotNil(arrow.id)
            XCTAssert(arrow is ArrowShape)
        } else {
            XCTFail("Failed to create arrow")
        }

        // Test line creation
        if let line = ShapeFactory.createShape(tool: .line, startPoint: startPoint, endPoint: endPoint, style: style, toolManager: toolManager) {
            XCTAssertNotNil(line.id)
            XCTAssert(line is LineShape)
        } else {
            XCTFail("Failed to create line")
        }

        // Test text creation
        if let text = ShapeFactory.createShape(tool: .text, startPoint: startPoint, endPoint: endPoint, style: style, toolManager: toolManager) {
            XCTAssertNotNil(text.id)
            XCTAssert(text is TextShape)
        } else {
            XCTFail("Failed to create text")
        }

        // Test number creation
        if let number = ShapeFactory.createShape(tool: .number, startPoint: startPoint, endPoint: endPoint, style: style, toolManager: toolManager) {
            XCTAssertNotNil(number.id)
            XCTAssert(number is NumberShape)
        } else {
            XCTFail("Failed to create number")
        }

        // Test spotlight creation
        if let spotlight = ShapeFactory.createShape(tool: .spotlight, startPoint: startPoint, endPoint: endPoint, style: style, toolManager: toolManager) {
            XCTAssertNotNil(spotlight.id)
            XCTAssert(spotlight is SpotlightShape)
        } else {
            XCTFail("Failed to create spotlight")
        }

        // Test select tool returns nil
        XCTAssertNil(ShapeFactory.createShape(tool: .select, startPoint: startPoint, endPoint: endPoint, style: style, toolManager: toolManager))
    }

    func testShapeFactoryConvenienceMethods() {
        let point = CGPoint(x: 50, y: 50)

        // Test rectangle factory
        let rectangle = ShapeFactory.createRectangle(at: point, size: CGSize(width: 100, height: 50))
        XCTAssertEqual(rectangle.rect.origin, point)
        XCTAssertEqual(rectangle.rect.size, CGSize(width: 100, height: 50))

        // Test ellipse factory
        let ellipse = ShapeFactory.createEllipse(at: point, size: CGSize(width: 80, height: 80))
        XCTAssertEqual(ellipse.rect.origin, point)
        XCTAssertEqual(ellipse.rect.size, CGSize(width: 80, height: 80))

        // Test text factory
        let text = ShapeFactory.createText(at: point, text: "Test", color: .blue)
        XCTAssertEqual(text.position, point)
        XCTAssertEqual(text.text, "Test")

        // Test number factory
        let number = ShapeFactory.createNumber(at: point, number: 123)
        XCTAssertEqual(number.position, point)
        XCTAssertEqual(number.number, 123)

        // Test spotlight factory
        let spotlight = ShapeFactory.createSpotlight(at: point, radius: 75)
        XCTAssertEqual(spotlight.center, point)
        XCTAssertEqual(spotlight.radius, 75)
    }

    func testShapeFactoryPresetShapes() {
        let point = CGPoint(x: 100, y: 100)

        // Test error label
        if let errorLabel = ShapeFactory.Preset.errorLabel(at: point).shape {
            XCTAssertNotNil(errorLabel.id)
            XCTAssert(errorLabel is TextShape)
            if let textShape = errorLabel as? TextShape {
                XCTAssertEqual(textShape.text, "ERROR")
                XCTAssertEqual(textShape.color, .red)
            }
        }

        // Test success badge
        if let successBadge = ShapeFactory.Preset.successBadge(at: point, number: 5).shape {
            XCTAssertNotNil(successBadge.id)
            XCTAssert(successBadge is NumberShape)
            if let numberShape = successBadge as? NumberShape {
                XCTAssertEqual(numberShape.number, 5)
            }
        }
    }

    // MARK: - ShapeStyle Tests

    func testShapeStyleDefaults() {
        let style = ShapeStyle.default

        XCTAssertEqual(style.strokeColor, .red)
        XCTAssertNil(style.fillColor)
        XCTAssertEqual(style.strokeWidth, 3.0)
        XCTAssertEqual(style.opacity, 1.0)
    }

    func testShapeStyleEquality() {
        let style1 = ShapeStyle(strokeColor: .blue, fillColor: .yellow, strokeWidth: 5, opacity: 0.8)
        let style2 = ShapeStyle(strokeColor: .blue, fillColor: .yellow, strokeWidth: 5, opacity: 0.8)
        let style3 = ShapeStyle(strokeColor: .red, fillColor: .yellow, strokeWidth: 5, opacity: 0.8)

        XCTAssertTrue(style1 == style2)
        XCTAssertFalse(style1 == style3)
    }
}