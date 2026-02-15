// AppSettings.swift - Application settings model
// Think of it like a container for all user preferences
// Like a recipe card box holding all your cooking preferences

import SwiftUI
import Foundation
import ApplicationServices  // For CGEventFlags

// @OBSERVABLE - Makes this class work with SwiftUI
// When properties change, any view using this updates automatically
// Think of it like a smart display that shows current values
@Observable
final class AppSettings: Equatable {

    // Equatable conformance for onChange(of:) in SwiftUI
    // Two settings are equal if all their properties are equal
    static func == (lhs: AppSettings, rhs: AppSettings) -> Bool {
        lhs.captureFullscreenHotkey == rhs.captureFullscreenHotkey &&
        lhs.captureRegionHotkey == rhs.captureRegionHotkey &&
        lhs.captureWindowHotkey == rhs.captureWindowHotkey &&
        lhs.defaultFormat == rhs.defaultFormat &&
        lhs.defaultQuality == rhs.defaultQuality &&
        lhs.defaultOutputFolder == rhs.defaultOutputFolder &&
        lhs.launchAtLogin == rhs.launchAtLogin &&
        lhs.showMenuBarIcon == rhs.showMenuBarIcon &&
        lhs.showNotifications == rhs.showNotifications &&
        lhs.defaultTool == rhs.defaultTool &&
        lhs.defaultStrokeWidth == rhs.defaultStrokeWidth
    }

    // MARK: - Hotkeys
    // Global keyboard shortcuts for different capture types
    // Each hotkey has an ID, key code, modifiers, and description

    /// Fullscreen capture hotkey (default: Cmd+Shift+5)
    /// Think of it like "this button takes picture of whole screen"
    var captureFullscreenHotkey: Hotkey

    /// Region capture hotkey (default: Cmd+Shift+6)
    /// Think of it like "this button lets you select part of screen"
    var captureRegionHotkey: Hotkey

    /// Window capture hotkey (default: Cmd+Shift+7)
    /// Think of it like "this button captures one window"
    var captureWindowHotkey: Hotkey

    // MARK: - Export
    // Default settings for exporting screenshots

    /// Default export format (PNG or JPEG)
    /// PNG = no quality loss, JPEG = smaller file size
    var defaultFormat: ExportFormat

    /// Default JPEG quality (0.1 to 1.0)
    /// Only used when defaultFormat is .jpeg
    /// Higher = better quality, bigger file
    var defaultQuality: Double

    /// Where to save screenshots by default (nil = ask user each time)
    /// Think of it like "which folder do you want pictures in"
    var defaultOutputFolder: URL?

    // MARK: - General
    // App-wide behavior settings

    /// Should app start automatically when you log in?
    /// Think of it like "does coffee maker turn on by itself in morning"
    var launchAtLogin: Bool

    /// Should the menu bar icon be visible?
    /// Think of it like "show the app icon in top-right menu bar"
    var showMenuBarIcon: Bool

    /// Should notifications show after capture?
    /// Think of it like "does app say 'Screenshot saved!' after taking picture"
    var showNotifications: Bool

    // MARK: - Editor
    // Default settings for annotation editor

    /// Which tool is selected when editor opens
    /// Think of it like "which utensil is in your hand first"
    var defaultTool: ToolType

    /// How thick are the lines you draw (in points)
    /// Think of it like "thin pen or thick marker"
    var defaultStrokeWidth: Double

    /// What color are new shapes/lines
    /// Think of it like "red pen, blue pen, etc."
    var defaultColor: Color

    /// INITIALIZER - Creates settings with default values
    /// Think of it like "start with all knobs at default positions"
    init(
        captureFullscreenHotkey: Hotkey = Hotkey(
            id: 1,
            keyCode: 0x0F,
            flags: [.maskCommand, .maskShift],
            description: "Cmd+Shift+5"
        ),
        captureRegionHotkey: Hotkey = Hotkey(
            id: 2,
            keyCode: 0x10,
            flags: [.maskCommand, .maskShift],
            description: "Cmd+Shift+6"
        ),
        captureWindowHotkey: Hotkey = Hotkey(
            id: 3,
            keyCode: 0x11,
            flags: [.maskCommand, .maskShift],
            description: "Cmd+Shift+7"
        ),
        defaultFormat: ExportFormat = .png,
        defaultQuality: Double = 0.9,
        defaultOutputFolder: URL? = nil,
        launchAtLogin: Bool = false,
        showMenuBarIcon: Bool = true,
        showNotifications: Bool = true,
        defaultTool: ToolType = .select,
        defaultStrokeWidth: Double = 2.0,
        defaultColor: Color = .red
    ) {
        // Save all the values we were given
        self.captureFullscreenHotkey = captureFullscreenHotkey
        self.captureRegionHotkey = captureRegionHotkey
        self.captureWindowHotkey = captureWindowHotkey
        self.defaultFormat = defaultFormat
        self.defaultQuality = defaultQuality
        self.defaultOutputFolder = defaultOutputFolder
        self.launchAtLogin = launchAtLogin
        self.showMenuBarIcon = showMenuBarIcon
        self.showNotifications = showNotifications
        self.defaultTool = defaultTool
        self.defaultStrokeWidth = defaultStrokeWidth
        self.defaultColor = defaultColor
    }
}

// MARK: - Default Factory
// Extension to easily create default settings
extension AppSettings {

    /// Creates settings with all safe defaults
    /// Think of it like "factory settings" on a device
    static var defaults: AppSettings {
        AppSettings()
    }
}
