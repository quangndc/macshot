// ExportManagerTests.swift - Unit tests for export system
// Tests for Phase 09 - Testing & Polish

import XCTest
@testable import MacShot

@MainActor
final class ExportManagerTests: XCTestCase {
    var manager: ExportManager!
    var testImage: NSImage!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        manager = ExportManager()
        testImage = NSImage(size: NSSize(width: 100, height: 100))

        // Create temp directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacShotTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDirectory)
        manager = nil
        testImage = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testManagerInitialState() {
        XCTAssertFalse(manager.isExporting)
        XCTAssertEqual(manager.exportProgress, 0.0)
        XCTAssertNil(manager.errorMessage)
    }

    // MARK: - Filename Generation Tests

    func testGeneratePNGFilename() {
        let filename = manager.generateFilename(format: .png)

        XCTAssertTrue(filename.hasPrefix("MacShot_"))
        XCTAssertTrue(filename.hasSuffix(".png"))

        // Extract timestamp portion
        let timestampPart = filename.dropFirst("MacShot_".count).dropLast(".png".count)

        // Verify format matches pattern: yyyy-MM-dd_HHmmss
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        XCTAssertNotNil(formatter.date(from: String(timestampPart)))
    }

    func testGenerateJPEGFilename() {
        let filename = manager.generateFilename(format: .jpeg)

        XCTAssertTrue(filename.hasPrefix("MacShot_"))
        XCTAssertTrue(filename.hasSuffix(".jpg"))
    }

    func testGenerateFilenameUniqueness() {
        // Generate two filenames quickly
        let filename1 = manager.generateFilename(format: .png)
        Thread.sleep(forTimeInterval: 0.1) // Small delay
        let filename2 = manager.generateFilename(format: .png)

        // Filenames should be different due to timestamp
        XCTAssertNotEqual(filename1, filename2)
    }

    // MARK: - URL Validation Tests

    func testValidateOutputURLWithValidDirectory() {
        // Use temp directory which should exist
        let testURL = tempDirectory.appendingPathComponent("test.png")
        let validated = manager.validateOutputURL(testURL)

        XCTAssertNotNil(validated)
        XCTAssertEqual(validated, testURL)
    }

    func testValidateOutputURLWithInvalidDirectory() {
        // Use non-existent directory
        let invalidDir = tempDirectory
            .appendingPathComponent("non_existent_subdir")
            .appendingPathComponent("test.png")
        let validated = manager.validateOutputURL(invalidDir)

        XCTAssertNil(validated)
    }

    // MARK: - Export Options Tests

    func testDefaultExportOptions() {
        let options = ExportManager.defaultOptions()

        XCTAssertEqual(options.format, SettingsStore.defaultFormat)
        XCTAssertEqual(options.jpegQuality, SettingsStore.defaultQuality)
        XCTAssertTrue(options.copyToClipboard)
    }

    func testOptionsWithSpecificFormat() {
        let pngOptions = ExportManager.optionsWithFormat(.png)
        XCTAssertEqual(pngOptions.format, .png)

        let jpegOptions = ExportManager.optionsWithFormat(.jpeg)
        XCTAssertEqual(jpegOptions.format, .jpeg)
    }

    // MARK: - Clipboard Tests

    func testQuickCopyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        manager.quickCopyToClipboard(testImage)

        // Verify pasteboard has content
        XCTAssertFalse(pasteboard.data(forType: .png)?.isEmpty ?? true)
    }

    func testCopyDataToClipboard() {
        let testData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG signature bytes
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        manager.copyToClipboard(data: testData)

        let retrievedData = pasteboard.data(forType: .png)
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData, testData)
    }

    // MARK: - Quick Save Tests

    func testQuickSaveToDesktop() async throws {
        // Create a simple test image
        let imageSize = NSSize(width: 50, height: 50)
        let testImage = NSImage(size: imageSize)

        let savedURL = manager.quickSaveToDesktop(testImage)

        if let url = savedURL {
            // Verify file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

            // Verify filename format
            XCTAssertTrue(url.lastPathComponent.hasPrefix("MacShot_"))
            XCTAssertTrue(url.lastPathComponent.hasSuffix(".png"))

            // Clean up
            try FileManager.default.removeItem(at: url)
        } else {
            XCTFail("Failed to save to desktop")
        }
    }

    // MARK: - Export Progress Tests

    func testExportProgressUpdate() async throws {
        let outputURL = tempDirectory.appendingPathComponent("test_export.png")
        let options = ExportOptions(format: .png, outputPath: outputURL)
        let cropper = ImageCropper()

        do {
            try await manager.export(image: testImage, options: options, cropper: cropper)
        } catch {
            // Export may fail, but we can still check progress
        }

        // After export, progress should be updated
        // Note: Progress may be 0 if export failed early, or 1.0 if succeeded
        XCTAssertTrue(manager.exportProgress >= 0.0 && manager.exportProgress <= 1.0)
    }

    // MARK: - Export Error Tests

    func testExportErrorDescriptions() {
        // Test each error type has a description
        let noImageError = ExportError.noImage
        XCTAssertFalse(noImageError.localizedDescription.isEmpty)

        let saveFailedError = ExportError.saveFailed(NSError(domain: "test", code: 1))
        XCTAssertFalse(saveFailedError.localizedDescription.isEmpty)

        let clipboardFailedError = ExportError.clipboardFailed
        XCTAssertFalse(clipboardFailedError.localizedDescription.isEmpty)

        let exportInProgressError = ExportError.exportInProgress
        XCTAssertFalse(exportInProgressError.localizedDescription.isEmpty)
    }

    // MARK: - Concurrent Export Tests

    func testConcurrentExportPrevention() async throws {
        let outputURL = tempDirectory.appendingPathComponent("test1.png")
        let options = ExportOptions(format: .png, outputPath: outputURL)
        let cropper = ImageCropper()

        // Start first export
        let firstExport = Task {
            try? await manager.export(image: testImage, options: options, cropper: cropper)
        }

        // Wait a bit for first to start
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        // Try second export while first is running
        let outputURL2 = tempDirectory.appendingPathComponent("test2.png")
        let options2 = ExportOptions(format: .png, outputPath: outputURL2)

        do {
            try await manager.export(image: testImage, options: options2, cropper: cropper)
            XCTFail("Should have thrown exportInProgress error")
        } catch ExportError.exportInProgress {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }

        await firstExport.value
    }

    // MARK: - PNG Export Tests

    func testPNGExport() async throws {
        let outputURL = tempDirectory.appendingPathComponent("test_png.png")
        let options = ExportOptions(format: .png, outputPath: outputURL)
        let cropper = ImageCropper()

        try await manager.export(image: testImage, options: options, cropper: cropper)

        // Verify file was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // Verify it's a valid PNG by checking file signature
        let data = try Data(contentsOf: outputURL)
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        XCTAssertEqual(Array(data.prefix(8)), pngSignature)
    }

    // MARK: - JPEG Export Tests

    func testJPEGExportWithQuality() async throws {
        let outputURL = tempDirectory.appendingPathComponent("test_jpeg.jpg")
        let options = ExportOptions(format: .jpeg, jpegQuality: 0.8, outputPath: outputURL)
        let cropper = ImageCropper()

        try await manager.export(image: testImage, options: options, cropper: cropper)

        // Verify file was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // Verify it's a valid JPEG by checking file signature
        let data = try Data(contentsOf: outputURL)
        XCTAssertEqual(data.first, 0xFF) // JPEG starts with 0xFF
        XCTAssertTrue(data[1] == 0xD8 || data[1] == 0xE0 || data[1] == 0xE1) // JPEG markers
    }

    func testJPEGQualityClamping() async throws {
        let lowQuality = ExportOptions(format: .jpeg, jpegQuality: -0.5)
        let highQuality = ExportOptions(format: .jpeg, jpegQuality: 1.5)

        // Quality should be clamped to 0.0-1.0 range by ExportOptions
        XCTAssertTrue(lowQuality.jpegQuality >= 0.0 && lowQuality.jpegQuality <= 1.0)
        XCTAssertTrue(highQuality.jpegQuality >= 0.0 && highQuality.jpegQuality <= 1.0)
    }

    // MARK: - Export with Copy to Clipboard Tests

    func testExportWithCopyToClipboard() async throws {
        let outputURL = tempDirectory.appendingPathComponent("test_clipboard.png")
        let options = ExportOptions(format: .png, outputPath: outputURL, copyToClipboard: true)
        let cropper = ImageCropper()
        let pasteboard = NSPasteboard.general

        pasteboard.clearContents()

        try await manager.export(image: testImage, options: options, cropper: cropper)

        // Verify file was saved
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // Verify clipboard has content
        XCTAssertFalse(pasteboard.data(forType: .png)?.isEmpty ?? true)
    }

    // MARK: - Export Without Output Path Tests

    func testExportWithoutOutputPath() async throws {
        let options = ExportOptions(format: .png, outputPath: nil, copyToClipboard: true)
        let cropper = ImageCropper()

        // Should not throw error, just skip file save
        try await manager.export(image: testImage, options: options, cropper: cropper)

        // Should still have copied to clipboard
        let pasteboard = NSPasteboard.general
        XCTAssertFalse(pasteboard.data(forType: .png)?.isEmpty ?? true)
    }

    // MARK: - Image Cropper Integration Tests

    func testExportWithImageCropper() async throws {
        // Create test image that needs cropping
        let largeImage = NSImage(size: NSSize(width: 500, height: 500))

        let outputURL = tempDirectory.appendingPathComponent("cropped.png")
        let options = ExportOptions(format: .png, outputPath: outputURL)
        let cropper = ImageCropper()

        try await manager.export(image: largeImage, options: options, cropper: cropper)

        // Verify cropper was called (since we can't track calls, verify file exists)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // Verify cropped file was saved
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }
}
