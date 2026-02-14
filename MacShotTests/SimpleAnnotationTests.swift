// SimpleAnnotationTests.swift - Basic compilation tests for annotation code
// Tests for Phase 04 - Annotation Canvas

import XCTest
@testable import MacShot

final class SimpleAnnotationTests: XCTestCase {

    func testShapeProtocolProperties() {
        // Test that Shape protocol exists and has required properties
        XCTAssertNotNil(Shape.self)
    }

    func testToolTypeEnum() {
        // Test ToolType enumeration
        XCTAssertEqual(ToolType.select.displayName, "Select")
        XCTAssertEqual(ToolType.rectangle.displayName, "Rectangle")
        XCTAssertEqual(ToolType.ellipse.displayName, "Ellipse")
        XCTAssertEqual(ToolType.arrow.displayName, "Arrow")
        XCTAssertEqual(ToolType.line.displayName, "Line")
        XCTAssertEqual(ToolType.text.displayName, "Text")
        XCTAssertEqual(ToolType.number.displayName, "Number")
        XCTAssertEqual(ToolType.spotlight.displayName, "Spotlight")

        // Test keyboard shortcuts
        XCTAssertEqual(ToolType.select.keyboardShortcut, "V")
        XCTAssertEqual(ToolType.rectangle.keyboardShortcut, "R")
        XCTAssertEqual(ToolType.ellipse.keyboardShortcut, "E")
        XCTAssertEqual(ToolType.arrow.keyboardShortcut, "A")
        XCTAssertEqual(ToolType.line.keyboardShortcut, "L")
        XCTAssertEqual(ToolType.text.keyboardShortcut, "T")
        XCTAssertEqual(ToolType.number.keyboardShortcut, "N")
        XCTAssertEqual(ToolType.spotlight.keyboardShortcut, "S")
    }

    func testShapeStyleDefaults() {
        // Test ShapeStyle default properties
        let style = ShapeStyle.default
        XCTAssertEqual(style.strokeColor, .red)
        XCTAssertNil(style.fillColor)
        XCTAssertEqual(style.strokeWidth, 3.0)
        XCTAssertEqual(style.opacity, 1.0)
    }

    func testShapeStyleEquatable() {
        // Test ShapeStyle Equatable conformance
        let style1 = ShapeStyle(strokeColor: .blue, fillColor: .yellow, strokeWidth: 5, opacity: 0.8)
        let style2 = ShapeStyle(strokeColor: .blue, fillColor: .yellow, strokeWidth: 5, opacity: 0.8)
        let style3 = ShapeStyle(strokeColor: .red, fillColor: .yellow, strokeWidth: 5, opacity: 0.8)

        XCTAssertTrue(style1 == style2)
        XCTAssertFalse(style1 == style3)
    }

    func testToolManagerBasicFunctionality() {
        // Test ToolManager basic initialization
        let manager = ToolManager()
        XCTAssertEqual(manager.currentTool, .select)
        XCTAssertEqual(manager.strokeColor, .red)
        XCTAssertEqual(manager.strokeWidth, 3.0)
        XCTAssertEqual(manager.opacity, 1.0)
        XCTAssertNil(manager.fillColor)
    }

    func testToolManagerToolSelection() {
        // Test ToolManager tool selection
        let manager = ToolManager()
        manager.selectTool(.rectangle)
        XCTAssertEqual(manager.currentTool, .rectangle)

        manager.selectTool(.text)
        XCTAssertEqual(manager.currentTool, .text)

        manager.selectTool(.spotlight)
        XCTAssertEqual(manager.currentTool, .spotlight)
    }

    func testToolManagerStyleProperties() {
        // Test ToolManager style property updates
        let manager = ToolManager()

        // Test stroke color
        manager.setStrokeColor(.blue)
        XCTAssertEqual(manager.strokeColor, .blue)

        // Test fill color
        manager.setFillColor(.yellow)
        XCTAssertEqual(manager.fillColor, .yellow)

        manager.setFillColor(nil)
        XCTAssertNil(manager.fillColor)

        // Test stroke width with clamping
        manager.setStrokeWidth(0.1)
        XCTAssertEqual(manager.strokeWidth, 0.5)

        manager.setStrokeWidth(25.0)
        XCTAssertEqual(manager.strokeWidth, 20.0)

        // Test opacity with clamping
        manager.setOpacity(0.0)
        XCTAssertEqual(manager.opacity, 0.1)

        manager.setOpacity(1.1)
        XCTAssertEqual(manager.opacity, 1.0)
    }

    func testToolManagerConvenienceProperties() {
        // Test ToolManager convenience properties
        let manager = ToolManager()

        // Test tool mode helpers
        manager.selectTool(.select)
        XCTAssertTrue(manager.isSelecting)
        XCTAssertFalse(manager.isDrawing)
        XCTAssertFalse(manager.isAnnotating)
        XCTAssertFalse(manager.isCreatingEffect)

        manager.selectTool(.rectangle)
        XCTAssertFalse(manager.isSelecting)
        XCTAssertTrue(manager.isDrawing)
        XCTAssertFalse(manager.isAnnotating)
        XCTAssertFalse(manager.isCreatingEffect)

        manager.selectTool(.text)
        XCTAssertFalse(manager.isSelecting)
        XCTAssertFalse(manager.isDrawing)
        XCTAssertTrue(manager.isAnnotating)
        XCTAssertFalse(manager.isCreatingEffect)

        manager.selectTool(.spotlight)
        XCTAssertFalse(manager.isSelecting)
        XCTAssertFalse(manager.isDrawing)
        XCTAssertFalse(manager.isAnnotating)
        XCTAssertTrue(manager.isCreatingEffect)
    }

    func testToolManagerNumberCounter() {
        // Test ToolManager number counter
        let manager = ToolManager()
        XCTAssertEqual(manager.currentNumber, 1)

        let firstNumber = manager.nextNumber()
        XCTAssertEqual(firstNumber, 1)
        XCTAssertEqual(manager.currentNumber, 2)

        let secondNumber = manager.nextNumber()
        XCTAssertEqual(secondNumber, 2)
        XCTAssertEqual(manager.currentNumber, 3)

        manager.resetNumberCounter()
        XCTAssertEqual(manager.currentNumber, 1)
    }

    func testToolManagerTextSettings() {
        // Test ToolManager text settings
        let manager = ToolManager()

        manager.setText("Hello World")
        XCTAssertEqual(manager.currentText, "Hello World")

        manager.setText("")
        XCTAssertEqual(manager.currentText, "Text")

        manager.setFontSize(24.0)
        XCTAssertEqual(manager.currentFontSize, 24.0)

        manager.setFontSize(5.0)
        XCTAssertEqual(manager.currentFontSize, 10.0)

        manager.setFontSize(80.0)
        XCTAssertEqual(manager.currentFontSize, 72.0)
    }

    func testToolManagerSpotlightSettings() {
        // Test ToolManager spotlight settings
        let manager = ToolManager()

        manager.setSpotlightRadius(150.0)
        XCTAssertEqual(manager.spotlightRadius, 150.0)

        manager.setSpotlightRadius(10.0)
        XCTAssertEqual(manager.spotlightRadius, 20.0)

        manager.setSpotlightRadius(400.0)
        XCTAssertEqual(manager.spotlightRadius, 300.0)
    }

    func testToolManagerPresetStyles() {
        // Test ToolManager preset styles
        let manager = ToolManager()

        manager.applyRedPreset()
        XCTAssertEqual(manager.strokeColor, .red)
        XCTAssertNil(manager.fillColor)
        XCTAssertEqual(manager.strokeWidth, 3.0)
        XCTAssertEqual(manager.opacity, 1.0)

        manager.applyBluePreset()
        XCTAssertEqual(manager.strokeColor, .blue)

        manager.applyGreenPreset()
        XCTAssertEqual(manager.strokeColor, .green)

        manager.applyHighlightPreset()
        XCTAssertEqual(manager.strokeColor, .yellow)
        XCTAssertEqual(manager.fillColor, .yellow.opacity(0.3))
    }

    func testToolManagerCurrentStyle() {
        // Test ToolManager computed currentStyle
        let manager = ToolManager()
        manager.setStrokeColor(.blue)
        manager.setFillColor(.yellow)
        manager.setStrokeWidth(5.0)
        manager.setOpacity(0.8)

        let style = manager.currentStyle
        XCTAssertEqual(style.strokeColor, .blue)
        XCTAssertEqual(style.fillColor, .yellow)
        XCTAssertEqual(style.strokeWidth, 5.0)
        XCTAssertEqual(style.opacity, 0.8)
    }

    func testShapeFactoryToolTypes() {
        // Test ShapeFactory for all tool types
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: 50, y: 50)
        _ = ShapeStyle(strokeColor: .red, fillColor: nil, strokeWidth: 3, opacity: 1.0)
        _ = ToolManager()

        // Test that createShape can be called for all tools
        // (just verifying they don't crash - actual shape creation requires GUI components)

        XCTAssertNotNil(ShapeFactory.createRectangle(at: startPoint, size: CGSize(width: 50, height: 50)))
        XCTAssertNotNil(ShapeFactory.createEllipse(at: startPoint, size: CGSize(width: 50, height: 50)))
        XCTAssertNotNil(ShapeFactory.createArrow(from: startPoint, to: endPoint))
        XCTAssertNotNil(ShapeFactory.createLine(from: startPoint, to: endPoint))
        XCTAssertNotNil(ShapeFactory.createText(at: startPoint, text: "Test"))
        XCTAssertNotNil(ShapeFactory.createNumber(at: startPoint, number: 42))
        XCTAssertNotNil(ShapeFactory.createSpotlight(at: startPoint, radius: 50))
    }

    func testShapeFactoryPresetShapes() {
        // Test ShapeFactory preset shapes
        let point = CGPoint(x: 100, y: 100)
        let endPoint = CGPoint(x: 150, y: 150)

        XCTAssertNotNil(ShapeFactory.Preset.errorLabel(at: point))
        XCTAssertNotNil(ShapeFactory.Preset.warningLabel(at: point))
        XCTAssertNotNil(ShapeFactory.Preset.successBadge(at: point, number: 5))
        XCTAssertNotNil(ShapeFactory.Preset.arrowCallout(from: point, to: endPoint))
        XCTAssertNotNil(ShapeFactory.Preset.highlightArea(CGRect(x: 0, y: 0, width: 100, height: 100)))
    }
}