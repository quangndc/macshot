// GeneralSettings.swift - General app behavior settings
// Think of it like the main power switches - what happens when you turn things on

import SwiftUI

// GENERAL SETTINGS VIEW - Basic app behavior controls
struct GeneralSettings: View {
    // @Binding means data lives elsewhere, we just view/edit it
    // Think of it like looking at someone else's paper, you can write on it
    @Binding var settings: AppSettings

    // Access to launch controller for toggle functionality
    // We'll use the shared instance when wired up
    @State private var launchController = LaunchController()

    // BODY - What this settings tab looks like
    var body: some View {
        // FORM arranges controls neatly with labels
        // Think of it like a neatly organized checklist
        Form {
            // LAUNCH AT LOGIN - Should app start automatically?
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
                .onChange(of: settings.launchAtLogin) { oldValue, newValue in
                    // When toggle changes, tell macOS about it
                    launchController.toggle(enabled: newValue)
                }

            // MENU BAR ICON - Show or hide the menu bar icon?
            Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)

            // NOTIFICATIONS - Show alerts after taking screenshots?
            Toggle("Show notifications", isOn: $settings.showNotifications)
        }
        // PADDING adds space around edges - makes it breathe
        .padding()
    }
}

// PREVIEW - Shows what this view looks like in Xcode
#if DEBUG
struct GeneralSettings_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettings(settings: .constant(AppSettings.defaults))
    }
}
#endif
