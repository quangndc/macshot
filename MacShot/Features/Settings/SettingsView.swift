// SettingsView.swift - Main settings window with tabbed interface
// Think of it like a filing cabinet with different drawers for different settings
// Each tab is like a drawer labeled with its category

import SwiftUI

// SETTINGS VIEW - The main settings window
struct SettingsView: View {
    // State holds the current settings values
    // Think of it like a working copy of your settings
    @State private var settings = AppSettings.defaults

    // BODY - What the settings window looks like
    var body: some View {
        // TAB VIEW - Creates tabbed interface like System Settings
        // Each tab is a different category of settings
        TabView {
            // General tab - basic app behavior
            GeneralSettings(settings: $settings)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            // Hotkeys tab - keyboard shortcuts
            HotkeysSettings(settings: $settings)
                .tabItem {
                    Label("Hotkeys", systemImage: "command")
                }

            // Export tab - file output settings
            ExportSettings(settings: $settings)
                .tabItem {
                    Label("Export", systemImage: "square.and.arrow.up")
                }

            // Editor tab - annotation defaults
            EditorSettings(settings: $settings)
                .tabItem {
                    Label("Editor", systemImage: "pencil")
                }
        }
        // Window size - big enough for content, small enough to be tidy
        .frame(width: 500, height: 400)
        .onAppear {
            syncToStore()
        }
        .onChange(of: settings) { _, _ in
            syncToStore()
        }
    }

    // SYNC TO STORE - Save current settings to SettingsStore
    private func syncToStore() {
        SettingsStore.captureFullscreenHotkey = settings.captureFullscreenHotkey
        SettingsStore.captureRegionHotkey = settings.captureRegionHotkey
        SettingsStore.captureWindowHotkey = settings.captureWindowHotkey
        SettingsStore.defaultFormat = settings.defaultFormat
        SettingsStore.defaultQuality = settings.defaultQuality
        SettingsStore.setOutputFolderURL(settings.defaultOutputFolder)
        SettingsStore.launchAtLogin = settings.launchAtLogin
        SettingsStore.showMenuBarIcon = settings.showMenuBarIcon
        SettingsStore.showNotifications = settings.showNotifications
        SettingsStore.setDefaultTool(settings.defaultTool)
        SettingsStore.defaultStrokeWidth = settings.defaultStrokeWidth
        SettingsStore.setDefaultColor(settings.defaultColor)
    }
}

// PREVIEW - Shows what this view looks like in Xcode
#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
