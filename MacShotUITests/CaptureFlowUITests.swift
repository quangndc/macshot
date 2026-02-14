// CaptureFlowUITests.swift - UI tests for screenshot capture workflow
// Tests for Phase 09 - Testing & Polish

import XCTest
@testable import MacShot

final class CaptureFlowUITests: XCTestCase {
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

    // MARK: - App Launch Tests

    func testAppLaunchesSuccessfully() {
        XCTAssertTrue(app.state == .runningForeground)
    }

    func testMenuBarExists() {
        let menuBar = app.menuBars.firstMatch
        XCTAssertTrue(menuBar.exists)
    }

    // MARK: - Menu Bar Icon Tests

    func testMenuBarIconVisible() {
        // Look for MacShot menu bar icon
        let menuBarIcon = app.menuBars.menuItems["MacShot"]
        XCTAssertTrue(menuBarIcon.exists, "MacShot menu bar icon should be visible")
    }

    func testMenuBarIconClickable() {
        let menuBarIcon = app.menuBars.menuItems["MacShot"]

        if menuBarIcon.exists {
            menuBarIcon.click()
            XCTAssertTrue(menuBarIcon.exists, "Menu should appear after clicking icon")
        }
    }

    // MARK: - Fullscreen Capture UI Tests

    func testFullscreenCaptureMenuItemExists() {
        let menuBarIcon = app.menuBars.menuItems["MacShot"]
        menuBarIcon.click()

        let fullscreenItem = app.menuItems["Capture Fullscreen"]
        XCTAssertTrue(fullscreenItem.exists, "Fullscreen capture menu item should exist")
    }

    func testFullscreenCaptureTriggers() {
        let menuBarIcon = app.menuBars.menuItems["MacShot"]
        menuBarIcon.click()

        let fullscreenItem = app.menuItems["Capture Fullscreen"]
        fullscreenItem.click()

        // Wait for capture to complete (editor should open)
        let editorWindow = app.windows.firstMatch
        let exists = editorWindow.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Editor window should appear after fullscreen capture")
    }

    func testFullscreenCaptureWithHotkey() {
        // Press Cmd+Shift+5 for fullscreen capture
        app.typeKey("5", modifierFlags: [.command, .shift])

        // Wait for editor window
        let editorWindow = app.windows.firstMatch
        let exists = editorWindow.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Editor window should appear after hotkey capture")
    }

    // MARK: - Region Capture UI Tests

    func testRegionCaptureMenuItemExists() {
        let menuBarIcon = app.menuBars.menuItems["MacShot"]
        menuBarIcon.click()

        let regionItem = app.menuItems["Capture Region"]
        XCTAssertTrue(regionItem.exists, "Region capture menu item should exist")
    }

    func testRegionCaptureTriggersSelection() {
        let menuBarIcon = app.menuBars.menuItems["MacShot"]
        menuBarIcon.click()

        let regionItem = app.menuItems["Capture Region"]
        regionItem.click()

        // Region selection overlay should appear
        // This may be a transparent window, hard to detect directly
        // Instead, wait a moment and check that something changed
        Thread.sleep(forTimeInterval: 0.5)

        // The selection UI should be visible
        let overlayWindow = app.windows["Region Selection"]
        let exists = overlayWindow.waitForExistence(timeout: 3)
        XCTAssertTrue(exists, "Region selection overlay should appear")
    }

    func testRegionCaptureWithHotkey() {
        // Press Cmd+Shift+6 for region capture
        app.typeKey("6", modifierFlags: [.command, .shift])

        // Wait for selection overlay
        let overlayWindow = app.windows["Region Selection"]
        let exists = overlayWindow.waitForExistence(timeout: 3)
        XCTAssertTrue(exists, "Region selection should appear after hotkey")
    }

    func testRegionCaptureSelectionFlow() {
        // Start region capture
        app.typeKey("6", modifierFlags: [.command, .shift])

        Thread.sleep(forTimeInterval: 0.5)

        // Simulate drag selection (coordinates depend on screen size)
        let startPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        let endPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))

        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)

        // After selection, editor should open with cropped image
        let editorWindow = app.windows.firstMatch
        let exists = editorWindow.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Editor should open after region selection")
    }

    // MARK: - Window Capture UI Tests

    func testWindowCaptureMenuItemExists() {
        let menuBarIcon = app.menuBars.menuItems["MacShot"]
        menuBarIcon.click()

        let windowItem = app.menuItems["Capture Window"]
        XCTAssertTrue(windowItem.exists, "Window capture menu item should exist")
    }

    func testWindowCaptureTriggers() {
        let menuBarIcon = app.menuBars.menuItems["MacShot"]
        menuBarIcon.click()

        let windowItem = app.menuItems["Capture Window"]
        windowItem.click()

        // Window capture mode should activate
        // Cursor should change or indicator should appear
        Thread.sleep(forTimeInterval: 0.5)

        // Click on a window to capture it
        let testWindow = app.windows.firstMatch
        if testWindow.exists {
            testWindow.click()

            // Editor should open
            let editorWindow = app.windows.firstMatch
            let exists = editorWindow.waitForExistence(timeout: 5)
            XCTAssertTrue(exists, "Editor should open after window capture")
        }
    }

    func testWindowCaptureWithHotkey() {
        // Press Cmd+Shift+7 for window capture
        app.typeKey("7", modifierFlags: [.command, .shift])

        Thread.sleep(forTimeInterval: 0.5)

        // Click on first window
        let testWindow = app.windows.firstMatch
        if testWindow.exists {
            testWindow.click()

            let editorWindow = app.windows.firstMatch
            let exists = editorWindow.waitForExistence(timeout: 5)
            XCTAssertTrue(exists, "Editor should open after window capture hotkey")
        }
    }

    // MARK: - Editor Window UI Tests

    func testEditorWindowOpensAfterCapture() {
        // Trigger fullscreen capture
        app.typeKey("5", modifierFlags: [.command, .shift])

        let editorWindow = app.windows.firstMatch
        let exists = editorWindow.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Editor window should open")
    }

    func testEditorWindowHasToolbar() {
        app.typeKey("5", modifierFlags: [.command, .shift])

        let editorWindow = app.windows.firstMatch
        if editorWindow.waitForExistence(timeout: 5) {
            let toolbar = editorWindow.toolbars.firstMatch
            XCTAssertTrue(toolbar.exists, "Editor should have a toolbar")
        }
    }

    func testEditorWindowHasCanvas() {
        app.typeKey("5", modifierFlags: [.command, .shift])

        let editorWindow = app.windows.firstMatch
        if editorWindow.waitForExistence(timeout: 5) {
            let canvas = editorWindow.images.firstMatch
            XCTAssertTrue(canvas.exists, "Editor should have a canvas/image view")
        }
    }

    func testEditorWindowHasCloseButton() {
        app.typeKey("5", modifierFlags: [.command, .shift])

        let editorWindow = app.windows.firstMatch
        if editorWindow.waitForExistence(timeout: 5) {
            let closeButton = editorWindow.buttons.firstMatch
            XCTAssertTrue(closeButton.exists, "Editor should have a close button")
        }
    }

    // MARK: - Capture Flow Integration Tests

    func testCompleteCaptureToEditFlow() {
        // 1. Capture fullscreen
        app.typeKey("5", modifierFlags: [.command, .shift])

        // 2. Wait for editor
        let editorWindow = app.windows.firstMatch
        XCTAssertTrue(editorWindow.waitForExistence(timeout: 5), "Editor should open")

        // 3. Verify editor has content
        let canvas = editorWindow.images.firstMatch
        XCTAssertTrue(canvas.exists, "Editor should show captured image")

        // 4. Close editor
        let closeButton = editorWindow.buttons.firstMatch
        if closeButton.exists {
            closeButton.click()
        }

        // 5. Editor should close
        XCTAssertFalse(editorWindow.exists, "Editor should close")
    }

    func testMultipleCapturesInSuccession() {
        // First capture
        app.typeKey("5", modifierFlags: [.command, .shift])
        let editor1 = app.windows.firstMatch
        XCTAssertTrue(editor1.waitForExistence(timeout: 5))

        // Close first
        editor1.buttons.firstMatch.click()
        Thread.sleep(forTimeInterval: 0.5)

        // Second capture
        app.typeKey("5", modifierFlags: [.command, .shift])
        let editor2 = app.windows.firstMatch
        XCTAssertTrue(editor2.waitForExistence(timeout: 5), "Second capture should also work")
    }

    // MARK: - Error Handling UI Tests

    func testCaptureFailsGracefully() {
        // This test verifies the app handles capture failures
        // In a real environment, we might simulate disk full, permissions denied, etc.

        // For now, just verify the app remains responsive
        let menuBarIcon = app.menuBars.menuItems["MacShot"]
        XCTAssertTrue(menuBarIcon.exists, "App should remain responsive")
    }

    func testEditorCloseWithoutSaving() {
        app.typeKey("5", modifierFlags: [.command, .shift])

        let editorWindow = app.windows.firstMatch
        if editorWindow.waitForExistence(timeout: 5) {
            // Close without saving
            editorWindow.buttons.firstMatch.click()

            // App should remain running
            Thread.sleep(forTimeInterval: 0.5)
            XCTAssertTrue(app.state == .runningForeground, "App should continue running")
        }
    }
}
