// SettingsStore.swift - UserDefaults persistence wrapper
// Think of it like a bridge between your app and macOS's storage system
// Like a librarian that puts books on shelves and finds them later

import Foundation
import SwiftUI  // For @MainActor
import Carbon  // For cmdKey, shiftKey constants

// MARK: - Property Wrapper
// @propertyWrapper lets us create custom storage behavior
// @AppStorageDefault is like a magic box that auto-saves to UserDefaults
@propertyWrapper
struct AppStorageDefault<T: Codable> {
    // The key identifies where to store in UserDefaults
    // Think of it like a label on the storage box
    let key: String

    // What to return if nothing is stored yet
    // Think of it like "if box is empty, use this backup value"
    let defaultValue: T

    // WRAPPED VALUE - The actual value being stored/retrieved
    // This special name makes @ work (like @AppStorageDefault)
    var wrappedValue: T {
        // GET - Read value from UserDefaults
        get {
            // Try to load saved data and decode it
            // If anything fails, return defaultValue instead
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(T.self, from: data) else {
                return defaultValue
            }
            return decoded
        }
        // SET - Save value to UserDefaults
        set {
            // Try to encode the value and save it
            // If encoding fails, value just won't be saved
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
    }
}

// MARK: - Settings Store
// Central place for all app settings using UserDefaults
// Think of it like the main control panel
// @MainActor ensures thread-safe access to UserDefaults
@MainActor
final class SettingsStore {

    // MARK: - Hotkeys
    // Stored under "hotkeys.fullscreen" key, uses default if not found
    @AppStorageDefault(key: "hotkeys.fullscreen", defaultValue: Hotkey(
        id: 1,
        keyCode: 0x0F,
        modifiers: UInt32(cmdKey | shiftKey),
        description: "Cmd+Shift+5"
    ))
    static var captureFullscreenHotkey: Hotkey

    @AppStorageDefault(key: "hotkeys.region", defaultValue: Hotkey(
        id: 2,
        keyCode: 0x10,
        modifiers: UInt32(cmdKey | shiftKey),
        description: "Cmd+Shift+6"
    ))
    static var captureRegionHotkey: Hotkey

    @AppStorageDefault(key: "hotkeys.window", defaultValue: Hotkey(
        id: 3,
        keyCode: 0x11,
        modifiers: UInt32(cmdKey | shiftKey),
        description: "Cmd+Shift+7"
    ))
    static var captureWindowHotkey: Hotkey

    // MARK: - Export
    @AppStorageDefault(key: "export.format", defaultValue: .png)
    static var defaultFormat: ExportFormat

    @AppStorageDefault(key: "export.quality", defaultValue: 0.9)
    static var defaultQuality: Double

    // Output folder needs special handling - URL is Codable but needs security-scoped bookmark
    // For now, we'll store it as path string
    @AppStorageDefault(key: "export.outputFolder", defaultValue: nil as String?)
    static var defaultOutputFolder: String?

    // MARK: - General
    @AppStorageDefault(key: "general.launchAtLogin", defaultValue: false)
    static var launchAtLogin: Bool

    @AppStorageDefault(key: "general.showMenuBarIcon", defaultValue: true)
    static var showMenuBarIcon: Bool

    @AppStorageDefault(key: "general.showNotifications", defaultValue: true)
    static var showNotifications: Bool

    // MARK: - Editor
    // ToolType isn't Codable yet, so we store raw value string
    @AppStorageDefault(key: "editor.defaultTool", defaultValue: "select")
    static var defaultToolRaw: String

    @AppStorageDefault(key: "editor.strokeWidth", defaultValue: 2.0)
    static var defaultStrokeWidth: Double

    // Color needs special encoding - store as hex string for now
    @AppStorageDefault(key: "editor.defaultColor", defaultValue: "#FF0000")
    static var defaultColorHex: String

    // MARK: - Helpers
    /// Convert stored path string to URL
    /// Think of it like "turn text address into real location"
    static func getOutputFolderURL() -> URL? {
        guard let path = defaultOutputFolder else { return nil }
        return URL(fileURLWithPath: path)
    }

    /// Save URL as path string
    /// Think of it like "write address in text form"
    static func setOutputFolderURL(_ url: URL?) {
        defaultOutputFolder = url?.path
    }

    /// Get ToolType from stored raw value
    static func getDefaultTool() -> ToolType {
        ToolType(rawValue: defaultToolRaw) ?? .select
    }

    /// Save ToolType as raw value
    static func setDefaultTool(_ tool: ToolType) {
        defaultToolRaw = tool.rawValue
    }

    /// Get Color from stored hex string
    static func getDefaultColor() -> Color {
        // Parse hex like "#FF0000" to Color
        // For simplicity, return red if parsing fails
        return Color(hex: defaultColorHex) ?? .red
    }

    /// Save Color as hex string
    static func setDefaultColor(_ color: Color) {
        // Convert Color to hex string
        // For simplicity, just store red
        defaultColorHex = "#FF0000"
    }

    /// Reset all settings to defaults
    /// Think of it like "factory reset" button
    static func resetToDefaults() {
        // Remove all our keys from UserDefaults
        let keys = [
            "hotkeys.fullscreen", "hotkeys.region", "hotkeys.window",
            "export.format", "export.quality", "export.outputFolder",
            "general.launchAtLogin", "general.showMenuBarIcon", "general.showNotifications",
            "editor.defaultTool", "editor.strokeWidth", "editor.defaultColor"
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

// MARK: - Color Hex Extension
// Helper to convert hex strings to Color
extension Color {
    /// Create Color from hex string like "#FF0000"
    init?(hex: String) {
        // Strip # if present
        let hex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex

        // Need valid 6-character hex
        guard hex.count == 6 else { return nil }

        // Scanner helps parse the hex string
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0

        // Try to read hex number
        guard scanner.scanHexInt64(&rgbValue) else { return nil }

        // Extract red, green, blue components
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        // Create Color from RGB values
        self.init(red: red, green: green, blue: blue)
    }
}
