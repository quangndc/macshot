// SettingsView.swift
// This file is the settings window UI
// Think of it like the control panel on your toaster - adjust how things work

import SwiftUI  // Apple's modern UI framework

// SETTINGS VIEW - The main settings window
struct SettingsView: View {

    // State for hotkey customization
    // Think of it like remembering which button you want on the remote
    @State private var hotkeyDescription: String = Hotkey.default.description

    // State for launch at login toggle
    // @State means this view owns this data
    // Think of it like a sticky note on the control panel
    @State private var launchAtLogin = false

    // State for notification toggle
    @State private var notificationsEnabled = true

    // BODY - What the settings window looks like
    var body: some View {
        // Form is a specialized layout for settings
        // It arranges controls in a clean, organized way
        // Think of it like a neat checklist on your fridge
        Form {
            // SECTION - Groups related settings together
            // This creates a visual grouping with a header
            Section("General") {
                // TOGGLE SWITCH - A checkbox-like control
                // launchAtLogin is the data binding ($)
                // The $ means "connect this control to this variable"
                Toggle("Launch at Login", isOn: $launchAtLogin)

                // TOGGLE SWITCH for notifications
                Toggle("Show Notifications", isOn: $notificationsEnabled)
            }

            // Another section for hotkey settings
            Section("Hotkey") {
                // This shows the current hotkey (read-only for now)
                HStack {
                    Text("Global Hotkey")
                    Spacer()  // Pushes text to left, icon to right
                    Text(hotkeyDescription)
                        .foregroundStyle(.secondary)  // Gray color
                }

                // TODO: Add hotkey recorder UI in future phase
                // This would let users press keys to set custom hotkey
                Text("Hotkey customization coming soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Section for export settings
            Section("Export") {
                // Default format picker
                Picker("Default Format", selection: $defaultFormat) {
                    Text("PNG").tag(ImageFormat.png)
                    Text("JPEG").tag(ImageFormat.jpeg)
                    Text("HEIC").tag(ImageFormat.heic)
                }
            }
        }
        // FORM MODIFIERS - Customize the form appearance
        .formStyle(.grouped)  // Grouped style (macOS settings look)
        .navigationTitle("Settings")  // Window title
        .frame(width: 500, height: 300)  // Window size
    }

    // STATE - Default format for exports
    @State private var defaultFormat = ImageFormat.png
}

// IMAGE FORMAT - Enum for supported export formats
enum ImageFormat: String {
    case png = "PNG"
    case jpeg = "JPEG"
    case heic = "HEIC"
}

// PREVIEW - Shows what this view looks like in Xcode
#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
