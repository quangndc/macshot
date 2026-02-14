// HotkeysSettings.swift - Keyboard shortcut customization
// Think of it like programming your remote control - which buttons do what

import SwiftUI

// HOTKEYS SETTINGS VIEW - Customize capture hotkeys
struct HotkeysSettings: View {
    // @Binding connects to settings data from parent
    // Think of it like a two-way radio - changes go both ways
    @Binding var settings: AppSettings

    // BODY - What this settings tab looks like
    var body: some View {
        // FORM arranges controls in clean rows
        Form {
            // FULLSCREEN HOTKEY - Shortcut to capture whole screen
            HotkeyRecorder(
                title: "Fullscreen",
                hotkey: $settings.captureFullscreenHotkey
            )

            // REGION HOTKEY - Shortcut to select and capture area
            HotkeyRecorder(
                title: "Region",
                hotkey: $settings.captureRegionHotkey
            )

            // WINDOW HOTKEY - Shortcut to capture one window
            HotkeyRecorder(
                title: "Window",
                hotkey: $settings.captureWindowHotkey
            )

            // Helpful tip for users
            Text("Click a hotkey, then press your desired key combination.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// PREVIEW - Shows what this view looks like in Xcode
#if DEBUG
struct HotkeysSettings_Previews: PreviewProvider {
    static var previews: some View {
        HotkeysSettings(settings: .constant(AppSettings.defaults))
    }
}
#endif
