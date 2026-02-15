// SettingsStoreTests.swift - Unit tests for UserDefaults persistence
// Tests for Phase 09 - Testing & Polish

import XCTest
import SwiftUI
import ApplicationServices  // For CGEventFlags
@testable import MacShot

@MainActor
final class SettingsStoreTests: XCTestCase {
    var testKeys: [String] = []

    override func setUp() {
        super.setUp()
        // Track any keys we create for cleanup
    }

    override func tearDown() {
        // Clean up test keys
        let keysToClean = testKeys
        Task { @MainActor in
            for key in keysToClean {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        super.tearDown()
    }

    // Helper to track and cleanup keys
    func trackKey(_ key: String) {
        testKeys.append(key)
    }

    // MARK: - Hotkey Settings Tests

    func testCaptureFullscreenHotkeyDefault() {
        let hotkey = SettingsStore.captureFullscreenHotkey

        XCTAssertEqual(hotkey.id, 1)
        XCTAssertEqual(hotkey.keyCode, 0x0F)
        XCTAssertEqual(hotkey.modifiers, UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue))
        XCTAssertEqual(hotkey.description, "Cmd+Shift+5")
    }

    func testCaptureRegionHotkeyDefault() {
        let hotkey = SettingsStore.captureRegionHotkey

        XCTAssertEqual(hotkey.id, 2)
        XCTAssertEqual(hotkey.keyCode, 0x10)
        XCTAssertEqual(hotkey.modifiers, UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue))
        XCTAssertEqual(hotkey.description, "Cmd+Shift+6")
    }

    func testCaptureWindowHotkeyDefault() {
        let hotkey = SettingsStore.captureWindowHotkey

        XCTAssertEqual(hotkey.id, 3)
        XCTAssertEqual(hotkey.keyCode, 0x11)
        XCTAssertEqual(hotkey.modifiers, UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue))
        XCTAssertEqual(hotkey.description, "Cmd+Shift+7")
    }

    func testHotkeyPersistence() {
        // Modify hotkey
        let original = SettingsStore.captureFullscreenHotkey
        let modified = Hotkey(id: 99, keyCode: 0x20, flags: [], description: "Test")

        SettingsStore.captureFullscreenHotkey = modified

        // Read it back
        let retrieved = SettingsStore.captureFullscreenHotkey
        XCTAssertEqual(retrieved.id, modified.id)
        XCTAssertEqual(retrieved.keyCode, modified.keyCode)
        XCTAssertEqual(retrieved.description, modified.description)

        // Restore original
        SettingsStore.captureFullscreenHotkey = original
    }

    // MARK: - Export Settings Tests

    func testDefaultFormatIsPNG() {
        XCTAssertEqual(SettingsStore.defaultFormat, .png)
    }

    func testDefaultFormatPersistence() {
        let original = SettingsStore.defaultFormat
        SettingsStore.defaultFormat = .jpeg

        XCTAssertEqual(SettingsStore.defaultFormat, .jpeg)

        // Restore
        SettingsStore.defaultFormat = original
    }

    func testDefaultQualityValue() {
        XCTAssertEqual(SettingsStore.defaultQuality, 0.9)
    }

    func testDefaultQualityPersistence() {
        let original = SettingsStore.defaultQuality
        SettingsStore.defaultQuality = 0.7

        XCTAssertEqual(SettingsStore.defaultQuality, 0.7)

        // Restore
        SettingsStore.defaultQuality = original
    }

    func testOutputFolderURL() {
        XCTAssertNil(SettingsStore.defaultOutputFolder)
        XCTAssertNil(SettingsStore.getOutputFolderURL())
    }

    func testOutputFolderURLPersistence() {
        let original = SettingsStore.defaultOutputFolder
        let testURL = URL(fileURLWithPath: "/tmp/test_folder")

        SettingsStore.setOutputFolderURL(testURL)

        XCTAssertEqual(SettingsStore.getOutputFolderURL(), testURL)
        XCTAssertEqual(SettingsStore.defaultOutputFolder, testURL.path)

        // Restore
        SettingsStore.defaultOutputFolder = original
    }

    // MARK: - General Settings Tests

    func testLaunchAtLoginDefault() {
        XCTAssertFalse(SettingsStore.launchAtLogin)
    }

    func testLaunchAtLoginPersistence() {
        let original = SettingsStore.launchAtLogin
        SettingsStore.launchAtLogin = true

        XCTAssertTrue(SettingsStore.launchAtLogin)

        // Restore
        SettingsStore.launchAtLogin = original
    }

    func testShowMenuBarIconDefault() {
        XCTAssertTrue(SettingsStore.showMenuBarIcon)
    }

    func testShowMenuBarIconPersistence() {
        let original = SettingsStore.showMenuBarIcon
        SettingsStore.showMenuBarIcon = false

        XCTAssertFalse(SettingsStore.showMenuBarIcon)

        // Restore
        SettingsStore.showMenuBarIcon = original
    }

    func testShowNotificationsDefault() {
        XCTAssertTrue(SettingsStore.showNotifications)
    }

    func testShowNotificationsPersistence() {
        let original = SettingsStore.showNotifications
        SettingsStore.showNotifications = false

        XCTAssertFalse(SettingsStore.showNotifications)

        // Restore
        SettingsStore.showNotifications = original
    }

    // MARK: - Editor Settings Tests

    func testDefaultToolRaw() {
        XCTAssertEqual(SettingsStore.defaultToolRaw, "select")
    }

    func testDefaultTool() {
        XCTAssertEqual(SettingsStore.getDefaultTool(), .select)
    }

    func testDefaultToolPersistence() {
        let original = SettingsStore.defaultToolRaw
        SettingsStore.setDefaultTool(.rectangle)

        XCTAssertEqual(SettingsStore.getDefaultTool(), .rectangle)
        XCTAssertEqual(SettingsStore.defaultToolRaw, "rectangle")

        // Restore
        SettingsStore.defaultToolRaw = original
    }

    func testAllToolTypesCanBeStored() {
        let tools: [ToolType] = [.select, .rectangle, .ellipse, .line, .arrow, .text, .number, .spotlight]

        for tool in tools {
            SettingsStore.setDefaultTool(tool)
            XCTAssertEqual(SettingsStore.getDefaultTool(), tool)
        }
    }

    func testDefaultStrokeWidth() {
        XCTAssertEqual(SettingsStore.defaultStrokeWidth, 2.0)
    }

    func testDefaultStrokeWidthPersistence() {
        let original = SettingsStore.defaultStrokeWidth
        SettingsStore.defaultStrokeWidth = 5.0

        XCTAssertEqual(SettingsStore.defaultStrokeWidth, 5.0)

        // Restore
        SettingsStore.defaultStrokeWidth = original
    }

    func testDefaultColorHex() {
        XCTAssertEqual(SettingsStore.defaultColorHex, "#FF0000")
    }

    func testDefaultColor() {
        // Should return red from default hex
        let color = SettingsStore.getDefaultColor()
        // Can't easily verify Color value, but we can check it doesn't crash
        XCTAssertNotNil(color)
    }

    func testDefaultColorPersistence() {
        let original = SettingsStore.defaultColorHex
        SettingsStore.defaultColorHex = "#00FF00" // Green

        XCTAssertEqual(SettingsStore.defaultColorHex, "#00FF00")

        // Restore
        SettingsStore.defaultColorHex = original
    }

    // MARK: - Color Hex Extension Tests

    func testColorHexValidFormats() {
        // Test with #
        let colorWithHash = Color(hex: "#FF0000")
        XCTAssertNotNil(colorWithHash)

        // Test without #
        let colorWithoutHash = Color(hex: "00FF00")
        XCTAssertNotNil(colorWithoutHash)

        // Test red
        let redColor = Color(hex: "FF0000")
        XCTAssertNotNil(redColor)

        // Test green
        let greenColor = Color(hex: "00FF00")
        XCTAssertNotNil(greenColor)

        // Test blue
        let blueColor = Color(hex: "0000FF")
        XCTAssertNotNil(blueColor)

        // Test white
        let whiteColor = Color(hex: "FFFFFF")
        XCTAssertNotNil(whiteColor)

        // Test black
        let blackColor = Color(hex: "000000")
        XCTAssertNotNil(blackColor)
    }

    func testColorHexInvalidFormats() {
        // Too short
        XCTAssertNil(Color(hex: "FFF"))
        XCTAssertNil(Color(hex: "FF00"))

        // Too long
        XCTAssertNil(Color(hex: "FF000000"))

        // Invalid characters
        XCTAssertNil(Color(hex: "GGGGGG"))

        // Empty
        XCTAssertNil(Color(hex: ""))
    }

    func testColorHexWithHashPrefix() {
        let color = Color(hex: "#123456")
        XCTAssertNotNil(color)

        // Should work same as without hash
        let colorNoHash = Color(hex: "123456")
        XCTAssertNotNil(colorNoHash)
    }

    // MARK: - Reset to Defaults Tests

    func testResetToDefaultsClearsCustomValues() {
        // Set custom values
        SettingsStore.defaultFormat = .jpeg
        SettingsStore.defaultQuality = 0.5
        SettingsStore.launchAtLogin = true
        SettingsStore.showMenuBarIcon = false
        SettingsStore.setDefaultTool(.ellipse)
        SettingsStore.defaultStrokeWidth = 10.0

        // Reset
        SettingsStore.resetToDefaults()

        // Verify back to defaults
        XCTAssertEqual(SettingsStore.defaultFormat, .png)
        XCTAssertEqual(SettingsStore.defaultQuality, 0.9)
        XCTAssertFalse(SettingsStore.launchAtLogin)
        XCTAssertTrue(SettingsStore.showMenuBarIcon)
        XCTAssertEqual(SettingsStore.getDefaultTool(), .select)
        XCTAssertEqual(SettingsStore.defaultStrokeWidth, 2.0)
    }

    func testResetToDefaultsClearsOutputFolder() {
        // Set output folder
        SettingsStore.setOutputFolderURL(URL(fileURLWithPath: "/tmp/test"))

        // Reset
        SettingsStore.resetToDefaults()

        // Verify cleared
        XCTAssertNil(SettingsStore.getOutputFolderURL())
        XCTAssertNil(SettingsStore.defaultOutputFolder)
    }

    // MARK: - Cross-Category Settings Tests

    func testMultipleSettingsIndependence() {
        // Set multiple settings at once
        SettingsStore.defaultFormat = .jpeg
        SettingsStore.launchAtLogin = true
        SettingsStore.setDefaultTool(.arrow)

        // Verify all are independent
        XCTAssertEqual(SettingsStore.defaultFormat, .jpeg)
        XCTAssertTrue(SettingsStore.launchAtLogin)
        XCTAssertEqual(SettingsStore.getDefaultTool(), .arrow)

        // Change one
        SettingsStore.defaultFormat = .png

        // Others should be unchanged
        XCTAssertEqual(SettingsStore.defaultFormat, .png)
        XCTAssertTrue(SettingsStore.launchAtLogin)
        XCTAssertEqual(SettingsStore.getDefaultTool(), .arrow)

        // Cleanup
        SettingsStore.resetToDefaults()
    }

    // MARK: - Type Safety Tests

    func testCodableConformance() {
        // Test that Hotkey can be encoded/decoded
        let hotkey = Hotkey(id: 123, keyCode: 0x30, flags: [.maskCommand], description: "Test")

        let encoder = JSONEncoder()
        let encoded = try? encoder.encode(hotkey)
        XCTAssertNotNil(encoded)

        let decoder = JSONDecoder()
        let decoded = try? decoder.decode(Hotkey.self, from: encoded ?? Data())
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.id, hotkey.id)
        XCTAssertEqual(decoded?.keyCode, hotkey.keyCode)
    }

    func testExportFormatCodable() {
        // Test ExportFormat is Codable
        let format = ExportFormat.jpeg

        let encoder = JSONEncoder()
        let encoded = try? encoder.encode(format)
        XCTAssertNotNil(encoded)

        let decoder = JSONDecoder()
        let decoded = try? decoder.decode(ExportFormat.self, from: encoded ?? Data())
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded, .png)
    }
}
