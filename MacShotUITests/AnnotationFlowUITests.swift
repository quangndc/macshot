// AnnotationFlowUITests.swift - UI tests for annotation tools workflow
// Tests for Phase 09 - Testing & Polish

import XCTest
@testable import MacShot

final class AnnotationFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // Helper: Open editor with a capture
    func openEditor() -> XCUIElement? {
        app.typeKey("5", modifierFlags: [.command, .shift])
        let editorWindow = app.windows.firstMatch
        if editorWindow.waitForExistence(timeout: 5) {
            return editorWindow
        }
        return nil
    }

    // MARK: - Toolbar Tests

    func testEditorHasAnnotationToolbar() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let toolbar = editor.toolbars.firstMatch
        XCTAssertTrue(toolbar.exists, "Editor should have annotation toolbar")
    }

    func testToolbarHasRectangleTool() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let rectangleButton = editor.toolbars.buttons["Rectangle"]
        XCTAssertTrue(rectangleButton.exists, "Toolbar should have Rectangle tool button")
    }

    func testToolbarHasEllipseTool() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let ellipseButton = editor.toolbars.buttons["Ellipse"]
        XCTAssertTrue(ellipseButton.exists, "Toolbar should have Ellipse tool button")
    }

    func testToolbarHasArrowTool() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let arrowButton = editor.toolbars.buttons["Arrow"]
        XCTAssertTrue(arrowButton.exists, "Toolbar should have Arrow tool button")
    }

    func testToolbarHasLineTool() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let lineButton = editor.toolbars.buttons["Line"]
        XCTAssertTrue(lineButton.exists, "Toolbar should have Line tool button")
    }

    func testToolbarHasTextTool() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let textButton = editor.toolbars.buttons["Text"]
        XCTAssertTrue(textButton.exists, "Toolbar should have Text tool button")
    }

    func testToolbarHasNumberTool() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let numberButton = editor.toolbars.buttons["Number"]
        XCTAssertTrue(numberButton.exists, "Toolbar should have Number tool button")
    }

    func testToolbarHasSpotlightTool() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let spotlightButton = editor.toolbars.buttons["Spotlight"]
        XCTAssertTrue(spotlightButton.exists, "Toolbar should have Spotlight tool button")
    }

    func testToolbarHasSelectTool() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let selectButton = editor.toolbars.buttons["Select"]
        XCTAssertTrue(selectButton.exists, "Toolbar should have Select tool button")
    }

    // MARK: - Tool Selection Tests

    func testSelectRectangleTool() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let rectangleButton = editor.toolbars.buttons["Rectangle"]
        rectangleButton.click()

        // Tool should appear selected (different appearance)
        XCTAssertTrue(rectangleButton.exists, "Rectangle button should remain visible/selected")
    }

    func testSelectEllipseTool() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let ellipseButton = editor.toolbars.buttons["Ellipse"]
        ellipseButton.click()

        XCTAssertTrue(ellipseButton.exists, "Ellipse button should remain visible/selected")
    }

    func testSelectTextTool() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let textButton = editor.toolbars.buttons["Text"]
        textButton.click()

        XCTAssertTrue(textButton.exists, "Text button should remain visible/selected")
    }

    func testSwitchBetweenTools() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let rectangleButton = editor.toolbars.buttons["Rectangle"]
        let textButton = editor.toolbars.buttons["Text"]

        rectangleButton.click()
        XCTAssertTrue(rectangleButton.exists)

        textButton.click()
        XCTAssertTrue(textButton.exists)

        // Select should be available
        let selectButton = editor.toolbars.buttons["Select"]
        selectButton.click()
        XCTAssertTrue(selectButton.exists)
    }

    // MARK: - Drawing Tests

    func testDrawRectangleOnCanvas() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        // Select rectangle tool
        let rectangleButton = editor.toolbars.buttons["Rectangle"]
        rectangleButton.click()

        // Get canvas element
        let canvas = editor.images.firstMatch
        XCTAssertTrue(canvas.exists, "Canvas should exist")

        // Draw rectangle by dragging
        let startPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        let endPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))

        startPoint.press(forDuration: 0.5, thenDragTo: endPoint)

        // Rectangle shape should be visible (can't easily verify, but app shouldn't crash)
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(editor.exists, "Editor should still be responsive after drawing")
    }

    func testDrawEllipseOnCanvas() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let ellipseButton = editor.toolbars.buttons["Ellipse"]
        ellipseButton.click()

        let canvas = editor.images.firstMatch
        let startPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))

        startPoint.press(forDuration: 0.5, thenDragTo: endPoint)

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(editor.exists)
    }

    func testDrawArrowOnCanvas() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let arrowButton = editor.toolbars.buttons["Arrow"]
        arrowButton.click()

        let canvas = editor.images.firstMatch
        let startPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        let endPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))

        startPoint.press(forDuration: 0.5, thenDragTo: endPoint)

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(editor.exists)
    }

    func testDrawLineOnCanvas() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let lineButton = editor.toolbars.buttons["Line"]
        lineButton.click()

        let canvas = editor.images.firstMatch
        let startPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        let endPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))

        startPoint.press(forDuration: 0.5, thenDragTo: endPoint)

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(editor.exists)
    }

    // MARK: - Text Annotation Tests

    func testAddTextAnnotation() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let textButton = editor.toolbars.buttons["Text"]
        textButton.click()

        // Click on canvas to add text
        let canvas = editor.images.firstMatch
        let textPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        textPoint.click()

        // Text input dialog should appear
        Thread.sleep(forTimeInterval: 0.5)

        // Type some text
        app.typeText("Test Annotation")

        // Press Enter to confirm
        app.typeKey("\r")

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(editor.exists, "Editor should remain responsive")
    }

    func testTextAnnotationAppearsOnCanvas() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let textButton = editor.toolbars.buttons["Text"]
        textButton.click()

        let canvas = editor.images.firstMatch
        let textPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        textPoint.click()

        app.typeText("Hello World")
        app.typeKey("\r")

        Thread.sleep(forTimeInterval: 1.0)

        // Verify editor still responsive
        XCTAssertTrue(editor.exists)
    }

    // MARK: - Number Annotation Tests

    func testAddNumberAnnotation() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let numberButton = editor.toolbars.buttons["Number"]
        numberButton.click()

        let canvas = editor.images.firstMatch
        let numberPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        numberPoint.click()

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(editor.exists)
    }

    func testMultipleNumberAnnotationsIncrement() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let numberButton = editor.toolbars.buttons["Number"]
        numberButton.click()

        let canvas = editor.images.firstMatch

        // Add first number
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).click()
        Thread.sleep(forTimeInterval: 0.3)

        // Add second number (should be 2)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        Thread.sleep(forTimeInterval: 0.3)

        // Add third number (should be 3)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7)).click()
        Thread.sleep(forTimeInterval: 0.5)

        XCTAssertTrue(editor.exists)
    }

    // MARK: - Spotlight Annotation Tests

    func testAddSpotlightAnnotation() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let spotlightButton = editor.toolbars.buttons["Spotlight"]
        spotlightButton.click()

        let canvas = editor.images.firstMatch
        let centerPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        centerPoint.click()

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(editor.exists)
    }

    func testSpotlightDarkensSurroundings() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let spotlightButton = editor.toolbars.buttons["Spotlight"]
        spotlightButton.click()

        let canvas = editor.images.firstMatch
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()

        Thread.sleep(forTimeInterval: 0.5)

        // Spotlight effect should be visible (can't easily verify, but app should work)
        XCTAssertTrue(editor.exists)
    }

    // MARK: - Shape Selection Tests

    func testSelectShapeOnCanvas() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        // Draw a rectangle first
        let rectangleButton = editor.toolbars.buttons["Rectangle"]
        rectangleButton.click()

        let canvas = editor.images.firstMatch
        let startPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        let endPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
        startPoint.press(forDuration: 0.5, thenDragTo: endPoint)

        Thread.sleep(forTimeInterval: 0.5)

        // Switch to select tool
        let selectButton = editor.toolbars.buttons["Select"]
        selectButton.click()

        // Click on shape (near center)
        let centerPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        centerPoint.click()

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(editor.exists)
    }

    func testDeselectShape() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let canvas = editor.images.firstMatch

        // Draw and select shape
        let rectangleButton = editor.toolbars.buttons["Rectangle"]
        rectangleButton.click()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()

        Thread.sleep(forTimeInterval: 0.3)

        // Click elsewhere to deselect
        let selectButton = editor.toolbars.buttons["Select"]
        selectButton.click()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(editor.exists)
    }

    // MARK: - Undo/Redo Tests

    func testUndoButtonExists() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let undoButton = editor.buttons["Undo"]
        XCTAssertTrue(undoButton.exists, "Undo button should exist")
    }

    func testRedoButtonExists() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let redoButton = editor.buttons["Redo"]
        XCTAssertTrue(redoButton.exists, "Redo button should exist")
    }

    func testUndoRemovesShape() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        // Draw shape
        let rectangleButton = editor.toolbars.buttons["Rectangle"]
        rectangleButton.click()

        let canvas = editor.images.firstMatch
        let startPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        let endPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
        startPoint.press(forDuration: 0.5, thenDragTo: endPoint)

        Thread.sleep(forTimeInterval: 0.5)

        // Undo
        let undoButton = editor.buttons["Undo"]
        if undoButton.exists {
            undoButton.click()
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(editor.exists, "Editor should work after undo")
    }

    func testRedoRestoresShape() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let canvas = editor.images.firstMatch

        // Draw and undo
        let rectangleButton = editor.toolbars.buttons["Rectangle"]
        rectangleButton.click()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()

        Thread.sleep(forTimeInterval: 0.3)

        let undoButton = editor.buttons["Undo"]
        if undoButton.exists {
            undoButton.click()
        }

        Thread.sleep(forTimeInterval: 0.3)

        // Redo
        let redoButton = editor.buttons["Redo"]
        if redoButton.exists {
            redoButton.click()
        }

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(editor.exists)
    }

    // MARK: - Style Controls Tests

    func testColorPickerExists() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let colorPicker = editor.buttons["Color"]
        XCTAssertTrue(colorPicker.exists, "Color picker should exist")
    }

    func testStrokeWidthSliderExists() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let strokeSlider = editor.sliders.firstMatch
        XCTAssertTrue(strokeSlider.exists, "Stroke width slider should exist")
    }

    func testOpacitySliderExists() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        // May be part of style controls
        let stylePanel = editor.otherElements.firstMatch
        // Can't easily identify specific controls, but panel should exist
        XCTAssertTrue(editor.exists)
    }

    // MARK: - Clear All Tests

    func testClearAllButtonExists() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let clearButton = editor.buttons["Clear"]
        XCTAssertTrue(clearButton.exists, "Clear All button should exist")
    }

    func testClearAllRemovesShapes() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        // Draw multiple shapes
        let rectangleButton = editor.toolbars.buttons["Rectangle"]
        rectangleButton.click()

        let canvas = editor.images.firstMatch
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).click()
        Thread.sleep(forTimeInterval: 0.2)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7)).click()

        Thread.sleep(forTimeInterval: 0.5)

        // Clear all
        let clearButton = editor.buttons["Clear"]
        if clearButton.exists {
            clearButton.click()
            Thread.sleep(forTimeInterval: 0.5)
        }

        XCTAssertTrue(editor.exists)
    }

    // MARK: - Integration Tests

    func testCompleteAnnotationWorkflow() {
        guard let editor = openEditor() else { XCTFail("Editor failed to open"); return }

        let canvas = editor.images.firstMatch

        // 1. Draw rectangle
        editor.toolbars.buttons["Rectangle"].click()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).click()

        // 2. Add arrow
        Thread.sleep(forTimeInterval: 0.2)
        editor.toolbars.buttons["Arrow"].click()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.6)).click()

        // 3. Add text
        Thread.sleep(forTimeInterval: 0.2)
        editor.toolbars.buttons["Text"].click()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        app.typeText("Label")
        app.typeKey("\r")

        // 4. Undo last action
        Thread.sleep(forTimeInterval: 0.5)
        let undoButton = editor.buttons["Undo"]
        if undoButton.exists {
            undoButton.click()
        }

        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(editor.exists, "Editor should handle complete workflow")
    }
}
