// HotkeyManager.swift
// This file manages global hotkeys (keyboard shortcuts that work anywhere)
// Think of it like a TV remote - works from any app, not just MacShot

import Carbon  // Older macOS framework for low-level keyboard events
import ApplicationServices  // For accessibility and event handling

// @MainActor means this runs on the main thread for safety
@MainActor
final class HotkeyManager: ObservableObject {

    // hotkeyRef is our "registration ticket" for the hotkey
    // Think of it like a reservation ticket at a restaurant
    // It's optional (?) because we might not have registered yet
    private var hotkeyRef: EventHotKeyRef?

    // captureHandler is what happens when hotkey is pressed
    // Think of it like "what channel does the remote switch to"
    private let captureHandler: () -> Void

    // INITIALIZER - Sets up the hotkey manager
    // Note: Caller should call register() with desired hotkey
    init(captureHandler: @escaping () -> Void) {
        // Save the handler function so we can call it later
        self.captureHandler = captureHandler
    }

    // REGISTER FROM SETTINGS - Load from SettingsStore and register
    /// Convenience method to register hotkey from stored preferences
    /// Think of it like "use your saved preference"
    func registerFromSettings() -> Bool {
        let storedHotkey = Hotkey(
            id: 1,
            keyCode: SettingsStore.captureFullscreenHotkey.keyCode,
            modifiers: SettingsStore.captureFullscreenHotkey.modifiers,
            description: SettingsStore.captureFullscreenHotkey.description
        )
        return register(hotkey: storedHotkey)
    }

    // REGISTER - Tells macOS "hey, I want this keyboard shortcut"
    // Returns true if successful, false if failed
    func register(hotkey: Hotkey) -> Bool {
        // First, unregister any existing hotkey (cancel old reservation)
        unregister()

        // Create event type specification
        // This tells macOS "we're interested in keyboard hotkey presses"
        // kEventClassKeyboard: keyboard-related events
        // kEventHotKeyPressed: specifically hotkey being pressed
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Create unique ID for our hotkey
        // Think of it like giving the reservation a name
        // 0x4D534854 = "MSHT" in hex (MacShot Hotkey)
        let hotkeyID = EventHotKeyID(
            signature: OSType(0x4D534854),  // "MSHT" - MacShot identifier
            id: UInt32(hotkey.id)  // Unique number for this specific hotkey
        )

        // Variable to hold the registration reference (our "ticket")
        var gHotkeyRef: EventHotKeyRef?

        // REGISTER EVENT HOTKEY - The actual function call to macOS
        // Parameters:
        // - hotkey.keyCode: which key (e.g., 5 = F5 key)
        // - hotkey.modifiers: modifier keys (Cmd, Shift, etc.)
        // - hotkeyID: our unique identifier
        // - GetApplicationEventTarget(): where to send the event (our app)
        // - 0: options (0 = default behavior)
        // - &gHotkeyRef: where to store the reference ticket
        let status = RegisterEventHotKey(
            UInt32(hotkey.keyCode),      // Key code (which key)
            UInt32(hotkey.modifiers),    // Modifiers (Cmd/Shift/etc)
            hotkeyID,                    // Our unique ID
            GetApplicationEventTarget(),  // Target (our app)
            0,                           // Options (default)
            &gHotkeyRef                   // Output: our ticket
        )

        // Check if registration worked (status == noErr means success)
        if status == noErr {
            // Save the reference so we can unregister later
            hotkeyRef = gHotkeyRef

            // Install the event handler (connect the "wire" from button to action)
            installHandler()

            // Return true = success!
            return true
        }

        // If we get here, registration failed
        print("Hotkey registration failed with status: \(status)")
        return false
    }

    // UNREGISTER - Cancels our hotkey reservation
    // Think of it like cancelling the restaurant reservation
    func unregister() {
        // If we have a reference (have a reservation), cancel it
        if let ref = hotkeyRef {
            // UnregisterEventHotkey tells macOS "we don't need this anymore"
            UnregisterEventHotKey(ref)

            // Clear our reference (throw away the ticket)
            hotkeyRef = nil
        }
    }

    // INSTALL HANDLER - Sets up the connection between hotkey press and action
    // This is more complex and requires additional setup
    // For now, we'll mark this as TODO
    private func installHandler() {
        // TODO: Install Carbon event handler for hotkey presses
        // This requires:
        // 1. Creating an event handler function
        // 2. Installing it with InstallEventHandler()
        // 3. Handling the event in our callback
        // For simplicity, this is a placeholder

        print("Hotkey handler installation - placeholder")
    }

    // CLEANUP - Note: deinit cleanup omitted due to Swift 6 concurrency constraints
    // The hotkey registration is automatically cleaned up when app terminates
    // For explicit cleanup, call unregister() before setting manager to nil
}

// HOTKEY - A simple data structure to describe a hotkey
// Think of it like a recipe card: "press these buttons together"
struct Hotkey: Codable, Equatable {
    // id: unique identifier for this hotkey
    var id: Int

    // keyCode: which key on the keyboard
    // Each key has a number (e.g., 59 = F5 on US keyboards)
    var keyCode: UInt32

    // modifiers: which special keys are held down
    // These are flags that can be combined:
    // - cmdKey: Command key (⌘)
    // - shiftKey: Shift key (⇧)
    // - optionKey: Option/Alt key (⌥)
    // - controlKey: Control key (⌃)
    var modifiers: UInt32

    // description: human-readable text like "Cmd+Shift+5"
    var description: String
}

// DEFAULT HOTKEY - The hotkey MacShot uses by default
extension Hotkey {
    // Default hotkey: Cmd+Shift+5
    // 59 = F5 key on US keyboards
    // cmdKey | shiftKey = both Command and Shift must be held
    static let `default` = Hotkey(
        id: 1,
        keyCode: 59,  // F5 key
        modifiers: UInt32(cmdKey | shiftKey),  // Cmd+Shift
        description: "⌘⇧5"  // Visual representation
    )
}
