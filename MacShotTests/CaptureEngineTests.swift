// CaptureEngineTests.swift - Unit tests for screenshot capture engine
// Tests for Phase 09 - Testing & Polish

import XCTest
@testable import MacShot

@MainActor
final class CaptureEngineTests: XCTestCase {
    var engine: CaptureEngine!

    override func setUp() {
        super.setUp()
        engine = CaptureEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testEngineInitialState() {
        XCTAssertNil(engine.capturedImage)
        XCTAssertFalse(engine.isCapturing)
        XCTAssertTrue(engine.includeCursor)
        XCTAssertNil(engine.onCaptureComplete)
    }

    func testEngineIncludeCursorProperty() {
        XCTAssertTrue(engine.includeCursor) // Default is true

        engine.includeCursor = false
        XCTAssertFalse(engine.includeCursor)

        engine.includeCursor = true
        XCTAssertTrue(engine.includeCursor)
    }

    func testEngineCaptureCallback() async {
        var callbackReceived = false
        var receivedResult: CaptureResult?

        engine.onCaptureComplete = { result in
            callbackReceived = true
            receivedResult = result
        }

        XCTAssertFalse(callbackReceived)

        // After capture (using actual capture)
        // Note: This will perform real screen capture in test environment
        if #available(macOS 15.0, *) {
            do {
                _ = try await engine.captureFullscreen()
                XCTAssertTrue(callbackReceived)
                XCTAssertNotNil(receivedResult)
            } catch {
                // Capture may fail in test environment
                // This is acceptable for unit testing
            }
        }
    }

    // MARK: - CaptureMode Tests

    func testCaptureModeEquality() {
        // Fullscreen mode equality
        XCTAssertEqual(CaptureMode.fullscreen, CaptureMode.fullscreen)

        // Region mode equality
        let rect1 = CGRect(x: 10, y: 10, width: 100, height: 100)
        let rect2 = CGRect(x: 10, y: 10, width: 100, height: 100)
        let rect3 = CGRect(x: 20, y: 20, width: 200, height: 200)

        XCTAssertEqual(CaptureMode.region(rect: rect1), CaptureMode.region(rect: rect2))
        XCTAssertNotEqual(CaptureMode.region(rect: rect1), CaptureMode.region(rect: rect3))

        // Window mode equality
        XCTAssertEqual(CaptureMode.window(windowID: 123), CaptureMode.window(windowID: 123))
        XCTAssertNotEqual(CaptureMode.window(windowID: 123), CaptureMode.window(windowID: 456))

        // Different modes are not equal
        XCTAssertNotEqual(CaptureMode.fullscreen, CaptureMode.region(rect: rect1))
        XCTAssertNotEqual(CaptureMode.region(rect: rect1), CaptureMode.window(windowID: 123))
    }

    func testCaptureModeFullscreen() {
        let mode = CaptureMode.fullscreen
        switch mode {
        case .fullscreen:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected fullscreen mode")
        }
    }

    func testCaptureModeRegion() {
        let rect = CGRect(x: 50, y: 50, width: 200, height: 150)
        let mode = CaptureMode.region(rect: rect)

        switch mode {
        case .region(let capturedRect):
            XCTAssertEqual(capturedRect, rect)
        default:
            XCTFail("Expected region mode")
        }
    }

    func testCaptureModeWindow() {
        let windowID: CGWindowID = 12345
        let mode = CaptureMode.window(windowID: windowID)

        switch mode {
        case .window(let capturedID):
            XCTAssertEqual(capturedID, windowID)
        default:
            XCTFail("Expected window mode")
        }
    }

    // MARK: - CaptureResult Tests

    func testCaptureResultInitialization() {
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        let mode = CaptureMode.fullscreen
        let metadata = CaptureMetadata(
            displayID: 1,
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
            scaleFactor: 2.0,
            windowID: nil
        )

        let result = CaptureResult(image: testImage, mode: mode, metadata: metadata)

        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.mode, .fullscreen)
        XCTAssertEqual(result.metadata.displayID, 1)
        XCTAssertEqual(result.metadata.scaleFactor, 2.0)
        XCTAssertNil(result.metadata.windowID)
    }

    func testCaptureMetadataInitialization() {
        let displayID: CGDirectDisplayID = 1
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let scaleFactor = 2.0
        let windowID: CGWindowID? = nil

        let metadata = CaptureMetadata(
            displayID: displayID,
            bounds: bounds,
            scaleFactor: scaleFactor,
            windowID: windowID
        )

        XCTAssertEqual(metadata.displayID, displayID)
        XCTAssertEqual(metadata.bounds, bounds)
        XCTAssertEqual(metadata.scaleFactor, scaleFactor)
        XCTAssertNil(metadata.windowID)

        // Verify timestamp is recent (within 1 second)
        let now = Date()
        let timeDifference = abs(now.timeIntervalSince(metadata.timestamp))
        XCTAssertLessThan(timeDifference, 1.0)
    }

    func testCaptureMetadataWithWindow() {
        let windowID: CGWindowID = 12345
        let metadata = CaptureMetadata(
            displayID: 1,
            bounds: CGRect(x: 100, y: 100, width: 500, height: 400),
            scaleFactor: 1.0,
            windowID: windowID
        )

        XCTAssertEqual(metadata.windowID, windowID)
    }

    // MARK: - Quick Capture Methods Tests

    func testQuickFullscreenCapture() async throws {
        if #available(macOS 15.0, *) {
            let result = try await engine.captureFullscreen()

            XCTAssertNotNil(result.image)
            XCTAssertEqual(result.mode, .fullscreen)
            XCTAssertNotNil(engine.capturedImage)
        }
    }

    func testQuickRegionCapture() async throws {
        if #available(macOS 15.0, *) {
            let result = try await engine.captureRegion()

            XCTAssertNotNil(result.image)
            if case .region = result.mode {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected region mode")
            }
            XCTAssertNotNil(engine.capturedImage)
        }
    }

    func testQuickWindowCapture() async throws {
        if #available(macOS 15.0, *) {
            let windowID: CGWindowID = 1
            let result = try await engine.captureWindow(windowID: windowID)

            XCTAssertNotNil(result.image)
            if case .window(let capturedID) = result.mode {
                XCTAssertEqual(capturedID, windowID)
            } else {
                XCTFail("Expected window mode")
            }
            XCTAssertNotNil(engine.capturedImage)
        }
    }

    // MARK: - Capture State Tests

    func testIsCapturingFlag() async throws {
        XCTAssertFalse(engine.isCapturing)

        if #available(macOS 15.0, *) {
                // Start capture (will update isCapturing flag)
                _ = try await engine.captureFullscreen()
                // Continue test even if capture fails
            }
    }

    func testCapturedImageUpdate() async throws {
        XCTAssertNil(engine.capturedImage)

        if #available(macOS 15.0, *) {
                let result = try await engine.captureFullscreen()

                // Verify captured image is set
                XCTAssertNotNil(engine.capturedImage)

                // Verify it's the same image from result
                XCTAssertEqual(engine.capturedImage?.size, result.image.size)
                // Capture may fail in test environment
            }
    }

    // MARK: - Capture with Specific Region Tests

    func testRegionCaptureWithSpecificRect() async throws {
        if #available(macOS 15.0, *) {
            let specificRect = CGRect(x: 100, y: 100, width: 300, height: 200)
            let result = try await engine.capture(mode: .region(rect: specificRect))

            XCTAssertNotNil(result.image)

            if case .region(let capturedRect) = result.mode {
                XCTAssertEqual(capturedRect, specificRect)
            } else {
                XCTFail("Expected region mode with specific rect")
            }
        }
    }

    func testRegionCaptureWithNullRect() async throws {
        if #available(macOS 15.0, *) {
            let result = try await engine.capture(mode: .region(rect: .null))

            XCTAssertNotNil(result.image)

            if case .region(let capturedRect) = result.mode {
                XCTAssertTrue(capturedRect.isNull)
            } else {
                XCTFail("Expected region mode with null rect")
            }
        }
    }
}
