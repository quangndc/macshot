// HotkeyTests.swift - Basic tests for hotkey functionality without instantiating HotkeyManager
// Tests for Phase 09 - Testing & Validation
// Focus: Hotkey struct validation, CGEventFlags conversion, basic functionality

import XCTest
import ApplicationServices
@testable import MacShot

final class HotkeyTests: XCTestCase {

    // MARK: - Hotkey Struct Tests

    func testHotkeyDefaultValues() {
        // Test the default hotkey configuration
        let hotkey = Hotkey.default

        XCTAssertEqual(hotkey.id, 1)
        XCTAssertEqual(hotkey.keyCode, 59)  // F5 key
        XCTAssertEqual(hotkey.modifiers, UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue))
        XCTAssertEqual(hotkey.description, "⌘⇧5")
    }

    func testHotkeyCGEventFlagsConversion() {
        // Test the cgEventFlags property conversion
        let hotkey = Hotkey.default

        // Convert stored modifiers to CGEventFlags
        var expectedFlags: CGEventFlags = []
        expectedFlags.insert(.maskCommand)
        expectedFlags.insert(.maskShift)

        XCTAssertEqual(hotkey.cgEventFlags, expectedFlags)
    }

    func testHotkeyCreationWithCGEventFlags() {
        // Test the convenience initializer that takes CGEventFlags
        let hotkey = Hotkey(id: 1, keyCode: 59, flags: [.maskCommand, .maskShift], description: "Test")

        XCTAssertEqual(hotkey.id, 1)
        XCTAssertEqual(hotkey.keyCode, 59)
        XCTAssertEqual(hotkey.modifiers, UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue))
        XCTAssertEqual(hotkey.description, "Test")
    }

    func testHotkeyCodableConformance() {
        // Test that Hotkey can be encoded and decoded
        let originalHotkey = Hotkey(id: 1, keyCode: 59, flags: [.maskCommand, .maskShift], description: "Test")

        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(originalHotkey)

            let decoder = JSONDecoder()
            let decodedHotkey = try decoder.decode(Hotkey.self, from: encodedData)

            XCTAssertEqual(decodedHotkey.id, originalHotkey.id)
            XCTAssertEqual(decodedHotkey.keyCode, originalHotkey.keyCode)
            XCTAssertEqual(decodedHotkey.modifiers, originalHotkey.modifiers)
            XCTAssertEqual(decodedHotkey.description, originalHotkey.description)
        } catch {
            XCTFail("Failed to encode/decode hotkey: \(error)")
        }
    }

    func testHotkeyEquality() {
        // Test Equatable conformance
        let hotkey1 = Hotkey(id: 1, keyCode: 59, flags: [.maskCommand, .maskShift], description: "Test")
        let hotkey2 = Hotkey(id: 1, keyCode: 59, flags: [.maskCommand, .maskShift], description: "Test")
        let hotkey3 = Hotkey(id: 2, keyCode: 59, flags: [.maskCommand, .maskShift], description: "Test")

        XCTAssertEqual(hotkey1, hotkey2)
        XCTAssertNotEqual(hotkey1, hotkey3)
    }

    // MARK: - CGEventFlags Tests

    func testCGEventFlagsConstants() {
        // Test that CGEventFlags constants are available
        XCTAssertNotNil(CGEventFlags.maskCommand)
        XCTAssertNotNil(CGEventFlags.maskShift)
        XCTAssertNotNil(CGEventFlags.maskAlternate)
        XCTAssertNotNil(CGEventFlags.maskControl)
        XCTAssertNotNil(CGEventFlags.maskSecondaryFn)
    }

    func testCGEventFlagsCombination() {
        // Test combining CGEventFlags
        var flags: CGEventFlags = []
        flags.insert(.maskCommand)
        flags.insert(.maskShift)

        XCTAssertTrue(flags.contains(.maskCommand))
        XCTAssertTrue(flags.contains(.maskShift))
        XCTAssertFalse(flags.contains(.maskAlternate))
    }

    func testCGEventFlagsRawValue() {
        // Test raw value conversion
        let commandMask = CGEventFlags.maskCommand.rawValue
        let shiftMask = CGEventFlags.maskShift.rawValue

        // These should be bit masks
        XCTAssertGreaterThan(commandMask, 0)
        XCTAssertGreaterThan(shiftMask, 0)
        XCTAssertNotEqual(commandMask, shiftMask)
    }

    // MARK: - KeyCode Tests

    func testKeyCodeValidity() {
        // Test that key codes are valid numbers
        let hotkey = Hotkey.default

        // keyCode should be a reasonable value (1-127 typically)
        XCTAssertGreaterThan(hotkey.keyCode, 0)
        XCTAssertLessThan(hotkey.keyCode, 128)
    }

    // MARK: - Hotkey Matching Logic Tests

    func testHotkeyMatchingSameModifiers() {
        // Test that hotkeys with same modifiers match correctly
        let hotkey1 = Hotkey(id: 1, keyCode: 59, flags: [.maskCommand, .maskShift], description: "Test1")
        let hotkey2 = Hotkey(id: 2, keyCode: 59, flags: [.maskCommand, .maskShift], description: "Test2")

        // Both should have the same cgEventFlags
        XCTAssertEqual(hotkey1.cgEventFlags, hotkey2.cgEventFlags)
    }

    func testHotkeyDifferentModifiers() {
        // Test that hotkeys with different modifiers don't match
        let hotkey1 = Hotkey(id: 1, keyCode: 59, flags: [.maskCommand], description: "Test1")
        let hotkey2 = Hotkey(id: 2, keyCode: 59, flags: [.maskCommand, .maskShift], description: "Test2")

        XCTAssertNotEqual(hotkey1.cgEventFlags, hotkey2.cgEventFlags)
    }

    func testHotkeyDifferentKeyCodes() {
        // Test that hotkeys with different key codes don't match
        let hotkey1 = Hotkey(id: 1, keyCode: 59, flags: [.maskCommand], description: "Test1")  // F5
        let hotkey2 = Hotkey(id: 2, keyCode: 60, flags: [.maskCommand], description: "Test2")  // F6

        XCTAssertNotEqual(hotkey1.keyCode, hotkey2.keyCode)
    }

    // MARK: - Modifier Combination Tests

    func testAllModifierCombinations() {
        // Test various modifier combinations
        let testCases: [(CGEventFlags, UInt32)] = [
            ([], 0),
            ([.maskCommand], UInt32(CGEventFlags.maskCommand.rawValue)),
            ([.maskShift], UInt32(CGEventFlags.maskShift.rawValue)),
            ([.maskAlternate], UInt32(CGEventFlags.maskAlternate.rawValue)),
            ([.maskControl], UInt32(CGEventFlags.maskControl.rawValue)),
            ([.maskCommand, .maskShift], UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue)),
            ([.maskCommand, .maskAlternate], UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskAlternate.rawValue)),
            ([.maskCommand, .maskControl], UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskControl.rawValue)),
            ([.maskShift, .maskAlternate], UInt32(CGEventFlags.maskShift.rawValue | CGEventFlags.maskAlternate.rawValue)),
            ([.maskShift, .maskControl], UInt32(CGEventFlags.maskShift.rawValue | CGEventFlags.maskControl.rawValue)),
            ([.maskAlternate, .maskControl], UInt32(CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskControl.rawValue)),
            ([.maskCommand, .maskShift, .maskAlternate], UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue | CGEventFlags.maskAlternate.rawValue)),
            ([.maskCommand, .maskShift, .maskControl], UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue | CGEventFlags.maskControl.rawValue)),
            ([.maskCommand, .maskAlternate, .maskControl], UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskControl.rawValue)),
            ([.maskShift, .maskAlternate, .maskControl], UInt32(CGEventFlags.maskShift.rawValue | CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskControl.rawValue)),
            ([.maskCommand, .maskShift, .maskAlternate, .maskControl], UInt32(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue | CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskControl.rawValue))
        ]

        for (flags, expectedModifiers) in testCases {
            let hotkey = Hotkey(id: 1, keyCode: 59, flags: flags, description: "Test")
            XCTAssertEqual(hotkey.modifiers, expectedModifiers, "Failed for flags: \(flags)")
        }
    }

    // MARK: - Performance Tests

    func testHotkeyMatchingPerformance() {
        // Test the performance of hotkey matching logic
        let hotkey = Hotkey.default

        measure {
            for _ in 0..<10000 {
                let testFlags: CGEventFlags = [.maskCommand, .maskShift]
                let testKeyCode: Int64 = 59

                let matches = testKeyCode == Int64(hotkey.keyCode) && testFlags == hotkey.cgEventFlags
                _ = matches
            }
        }
    }

    // MARK: - Error Handling Tests

    func testEmptyDescription() {
        // Test hotkey with empty description
        let hotkey = Hotkey(id: 1, keyCode: 59, flags: [.maskCommand], description: "")

        // Should still work (descriptions are mainly for display)
        XCTAssertEqual(hotkey.id, 1)
        XCTAssertEqual(hotkey.keyCode, 59)
        XCTAssertGreaterThan(hotkey.modifiers, 0)
    }

    func testZeroKeyCode() {
        // Test hotkey with zero keyCode (edge case)
        let hotkey = Hotkey(id: 1, keyCode: 0, flags: [.maskCommand], description: "Zero")

        // Should be valid (though not practically useful)
        XCTAssertEqual(hotkey.id, 1)
        XCTAssertEqual(hotkey.keyCode, 0)
        XCTAssertGreaterThan(hotkey.modifiers, 0)
    }
}