// HotkeyRecorder.swift - Interactive hotkey recording component
// Think of it like a programmable button - click it, then press keys you want

import SwiftUI
import Carbon
import AppKit

// HOTKEY RECORDER - Record custom keyboard shortcuts
struct HotkeyRecorder: View {
    // Display label for this hotkey
    let title: String

    // @Binding to hotkey data - two-way connection
    @Binding var hotkey: Hotkey

    // Are we currently listening for key presses?
    @State private var isRecording = false

    // Track our event monitor (need to clean up when done)
    @State private var eventMonitor: Any?

    // BODY - What the recorder looks like
    var body: some View {
        // HSTACK arranges things horizontally
        HStack {
            // Label on the left
            Text(title)

            Spacer()  // Pushes label left, button right

            // Recording button or current hotkey display
            if isRecording {
                // RECORDING STATE - Show we're listening
                Text("Press keys...")
                    .foregroundStyle(.secondary)  // Gray color
                    .onDisappear {
                        // When view disappears, stop recording
                        stopRecording()
                    }
            } else {
                // NORMAL STATE - Show button with current hotkey
                Button {
                    // User clicked - start recording
                    startRecording()
                } label: {
                    // Show hotkey description like "Cmd+Shift+5"
                    Text(hotkey.description)
                        .frame(minWidth: 100)  // Ensure consistent size
                }
                .buttonStyle(.bordered)  // Bordered style looks clickable
            }
        }
    }

    // START RECORDING - Begin listening for key presses
    private func startRecording() {
        isRecording = true

        // Install event monitor to catch key presses
        // This is like putting up a "listen for keys" sign
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            _ = handleKeyEvent(event)
            return nil  // Don't process this event normally
        }
    }

    // STOP RECORDING - Stop listening for key presses
    private func stopRecording() {
        isRecording = false

        // Remove our event monitor
        // This is like taking down the "listen for keys" sign
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // HANDLE KEY EVENT - Process a key press while recording
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        // Get the key code (which physical key)
        let keyCode = event.keyCode

        // Get modifier flags (Cmd, Shift, Option, Control)
        let modifiers = event.modifierFlags

        // Extract only the modifier bits we care about
        // This filters out things like caps lock or num lock
        let modifierFlags: UInt32 = modifiers.intersection([
            .command, .shift, .option, .control
        ]).rawValue

        // Require at least one modifier (no plain keys allowed)
        // This prevents conflicts with normal typing
        guard modifierFlags != 0 else {
            // No modifier pressed - ignore this key
            return event
        }

        // Build new hotkey with captured values
        let newHotkey = Hotkey(
            id: hotkey.id,  // Keep same ID
            keyCode: UInt32(keyCode),  // New key code
            modifiers: modifierFlags,  // New modifiers
            description: describeHotkey(modifierFlags, UInt32(keyCode))  // Human-readable
        )

        // Update the binding (saves to settings)
        hotkey = newHotkey

        // Stop recording - we got what we wanted
        stopRecording()

        // Don't process this event normally (we handled it)
        return nil
    }

    // DESCRIBE HOTKEY - Create human-readable string like "Cmd+Shift+5"
    private func describeHotkey(_ modifiers: UInt32, _ keyCode: UInt32) -> String {
        // Build up description piece by piece
        var parts: [String] = []

        // Add modifier symbols in order
        if modifiers & UInt32(NSEvent.ModifierFlags.command.rawValue) != 0 {
            parts.append("⌘")  // Command symbol
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.shift.rawValue) != 0 {
            parts.append("⇧")  // Shift symbol
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.option.rawValue) != 0 {
            parts.append("⌥")  // Option/Alt symbol
        }
        if modifiers & UInt32(NSEvent.ModifierFlags.control.rawValue) != 0 {
            parts.append("⌃")  // Control symbol
        }

        // Add the key character if we can figure it out
        // This is tricky - for function keys we just show the number
        parts.append(String(format: "%d", keyCode))

        // Join with + signs: "⌘⇧5" for Cmd+Shift+5
        return parts.joined(separator: "+")
    }
}

// EXTENSION - Convert NSEvent.ModifierFlags set to raw value
extension NSEvent.ModifierFlags {
    var rawValue: UInt32 {
        UInt32(self.rawValue)
    }
}

// PREVIEW - Shows what this view looks like in Xcode
#if DEBUG
struct HotkeyRecorder_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HotkeyRecorder(
                title: "Fullscreen",
                hotkey: .constant(Hotkey(
                    id: 1,
                    keyCode: 59,
                    modifiers: UInt32(cmdKey | shiftKey),
                    description: "Cmd+Shift+5"
                ))
            )
            .padding()

            HotkeyRecorder(
                title: "Region",
                hotkey: .constant(Hotkey(
                    id: 2,
                    keyCode: 60,
                    modifiers: UInt32(cmdKey | shiftKey),
                    description: "Cmd+Shift+6"
                ))
            )
            .padding()
        }
    }
}
#endif
