// HotkeyManager.swift
// This file manages global hotkeys (keyboard shortcuts that work anywhere)
// Uses CGEventTap for modern macOS event monitoring

import ApplicationServices  // For CGEventTap and accessibility handling

// Global storage for current hotkey info (accessible from callback)
// Think of it like a "bulletin board" that callback can read
private nonisolated(unsafe) var currentHotkey: (keyCode: UInt32, modifiers: UInt32, handler: @MainActor () -> Void)?

// @MainActor means this runs on the main thread for safety
@MainActor
final class HotkeyManager: ObservableObject {

    // eventTap is our "listening device" for keyboard events
    // Think of it like having a microphone that hears keyboard presses
    private var eventTap: CFMachPort?

    // runLoopSource integrates the tap with macOS's event processing
    // Think of it like connecting our microphone to the sound system
    private var runLoopSource: CFRunLoopSource?

    // captureHandler is what happens when hotkey is pressed
    // Think of it like "what channel does the remote switch to"
    private let captureHandler: @MainActor () -> Void

    // INITIALIZER - Sets up the hotkey manager
    // Note: Caller should call register() with desired hotkey
    init(captureHandler: @escaping @MainActor () -> Void) {
        self.captureHandler = captureHandler
    }

    // REGISTER FROM SETTINGS - Load from SettingsStore and register
    /// Convenience method to register hotkey from stored preferences
    /// Think of it like "use your saved preference"
    func registerFromSettings() -> Bool {
        let storedHotkey = Hotkey(
            id: 1,
            keyCode: SettingsStore.captureFullscreenHotkey.keyCode,
            flags: SettingsStore.captureFullscreenHotkey.cgEventFlags,
            description: SettingsStore.captureFullscreenHotkey.description
        )
        return register(hotkey: storedHotkey)
    }

    // REGISTER - Tells macOS "hey, I want this keyboard shortcut"
    // Returns true if successful, false if failed
    func register(hotkey: Hotkey) -> Bool {
        // First, unregister any existing hotkey (cancel old reservation)
        unregister()

        // Check Accessibility permission (required for CGEventTap)
        // Think of it like checking if we have a license to listen
        guard AXIsProcessTrusted() else {
            print("Accessibility permission not granted. Please enable in System Settings > Privacy & Security > Accessibility")
            // Prompt user to grant permission (use literal string value)
            let options: [String: Bool] = ["AXTrustedCheckOptionPrompt": true]
            _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
            return false
        }

        // Store hotkey info in global variable for callback access
        // Think of it like posting our "cheat sheet" on the bulletin board
        currentHotkey = (
            keyCode: hotkey.keyCode,
            modifiers: hotkey.modifiers,
            handler: captureHandler
        )

        // Create event tap for keydown events
        // CGEvent.tapCreate creates a "listener" for keyboard events
        // .cgSessionEventTap: Listen to all events in the current session
        // .headInsertEventTap: Insert at the front of the event tap chain
        // .defaultTap: Default behavior (no special options)
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventTapCallback,
            userInfo: nil
        ) else {
            print("Failed to create event tap - may need Accessibility permission")
            currentHotkey = nil
            return false
        }

        // Save the tap reference
        eventTap = tap

        // Create and add run loop source
        // Think of it like plugging our listener into macOS's event processing
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        self.runLoopSource = runLoopSource

        // Enable the tap (start listening)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("Hotkey registered: \(hotkey.description)")
        return true
    }

    // UNREGISTER - Cancels our hotkey reservation
    // Think of it like unplugging the microphone
    func unregister() {
        // Disable the tap first
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)

            // Remove from run loop (unplug from event processing)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(
                    CFRunLoopGetCurrent(),
                    source,
                    .commonModes
                )
            }
        }

        // Clear all references (throw away the ticket and cheat sheet)
        eventTap = nil
        runLoopSource = nil
        currentHotkey = nil
    }

    // DEINIT - Cleanup when manager is destroyed
    deinit {
        // Direct cleanup for CF objects
        currentHotkey = nil
    }
}

// EVENT TAP CALLBACK - Function called when keyboard event occurs
// @convention(c) means this uses C calling convention (required by CGEventTap)
// Think of it like "translate Swift function to C function"
private let eventTapCallback: CGEventTapCallBack = {
    (proxy: CGEventTapProxy,
     type: CGEventType,
     event: CGEvent,
     refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? in

    // Only handle keydown events (ignore keyup and others)
    // Think of it like "only care when key is pressed down"
    guard type == .keyDown else {
        return Unmanaged.passUnretained(event)
    }

    // Access current hotkey from global variable
    // Think of it like "check the bulletin board for notes"
    guard let hotkey = currentHotkey else {
        return Unmanaged.passUnretained(event)
    }

    // Get event data
    // keyCode: which key was pressed
    // flags: which modifier keys are held down
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags

    // Check if this event matches our hotkey
    if isHotkeyMatch(keyCode: keyCode, flags: flags, hotkey: hotkey) {
        // Trigger capture on main thread
        // Task { @MainActor in ... } switches to main thread safely
        // Think of it like "hand off to the main thread for UI work"
        Task { @MainActor in
            hotkey.handler()
        }
        // Return nil to consume the event (don't pass it to other apps)
        return nil
    }

    // Not our hotkey, pass event along
    return Unmanaged.passUnretained(event)
}

// IS HOTKEY MATCH - Check if event matches our hotkey
// Think of it like "compare the pressed keys to our cheat sheet"
private func isHotkeyMatch(
    keyCode: Int64,
    flags: CGEventFlags,
    hotkey: (keyCode: UInt32, modifiers: UInt32, handler: @MainActor () -> Void)
) -> Bool {
    // Check key code first
    guard keyCode == Int64(hotkey.keyCode) else {
        return false
    }

    // Convert stored modifiers to CGEventFlags for comparison
    // CGEventFlags uses different bit positions than Carbon
    var targetFlags: CGEventFlags = []
    let modifiers = hotkey.modifiers

    // Check each modifier flag and build CGEventFlags
    if modifiers & UInt32(CGEventFlags.maskCommand.rawValue) != 0 {
        targetFlags.insert(.maskCommand)
    }
    if modifiers & UInt32(CGEventFlags.maskShift.rawValue) != 0 {
        targetFlags.insert(.maskShift)
    }
    if modifiers & UInt32(CGEventFlags.maskAlternate.rawValue) != 0 {
        targetFlags.insert(.maskAlternate)
    }
    if modifiers & UInt32(CGEventFlags.maskSecondaryFn.rawValue) != 0 {
        targetFlags.insert(.maskSecondaryFn)
    }

    // Compare flags (must match exactly)
    return flags == targetFlags
}

// HOTKEY - A simple data structure to describe a hotkey
// Think of it like a recipe card: "press these buttons together"
struct Hotkey: Codable, Equatable, Sendable {
    // id: unique identifier for this hotkey
    var id: Int

    // keyCode: which key on the keyboard
    // Each key has a number (e.g., 59 = F5 on US keyboards)
    var keyCode: UInt32

    // modifiers: which special keys are held down
    // These store CGEventFlags raw values for compatibility
    var modifiers: UInt32

    // description: human-readable text like "Cmd+Shift+5"
    var description: String

    // Convert to CGEventFlags for comparison
    // Think of it like "translate our stored number to actual flags"
    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers & UInt32(CGEventFlags.maskCommand.rawValue) != 0 {
            flags.insert(.maskCommand)
        }
        if modifiers & UInt32(CGEventFlags.maskShift.rawValue) != 0 {
            flags.insert(.maskShift)
        }
        if modifiers & UInt32(CGEventFlags.maskAlternate.rawValue) != 0 {
            flags.insert(.maskAlternate)
        }
        if modifiers & UInt32(CGEventFlags.maskSecondaryFn.rawValue) != 0 {
            flags.insert(.maskSecondaryFn)
        }
        return flags
    }

    // Create from CGEventFlags (convenience for UI recording)
    init(id: Int, keyCode: UInt32, flags: CGEventFlags, description: String) {
        self.id = id
        self.keyCode = keyCode
        self.modifiers = UInt32(truncatingIfNeeded: flags.rawValue)
        self.description = description
    }
}

// DEFAULT HOTKEY - The hotkey MacShot uses by default
extension Hotkey {
    // Default hotkey: Cmd+Shift+5
    // 59 = F5 key on US keyboards
    // maskCommand | maskShift = both Command and Shift must be held
    static let `default` = Hotkey(
        id: 1,
        keyCode: 59,  // F5 key
        flags: [.maskCommand, .maskShift],
        description: "⌘⇧5"  // Visual representation
    )
}
