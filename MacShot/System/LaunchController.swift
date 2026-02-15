// LaunchController.swift
// This file manages "launch at login" - auto-start when you log in
// Think of it like a coffee maker with a timer - turns on by itself when you wake up

import ServiceManagement  // Apple framework for login items (SM = Service Management)

// @MainActor means this runs on the main thread for safety
@MainActor
final class LaunchController: ObservableObject {

    // @Published means SwiftUI views can watch this property for changes
    // When this changes, any view using it updates automatically
    // launchAtLogin = true means "app starts when I log in"
    @Published var launchAtLogin = false

    // CHECK STATUS - Check if app is currently set to launch at login
    // Think of it like checking if the coffee maker timer is set
    func checkStatus() {
        // SMAppService.mainApp represents our app in the login items list
        // .status tells us if it's enabled or not
        // .enabled = will launch at login
        // .notFound = not in the list at all
        // .disabled = in list but turned off
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // TOGGLE - Turn launch at login on or off
    // enabled: true = turn on, false = turn off
    func toggle(enabled: Bool) {
        do {
            if enabled {
                // USER WANTS IT ON - Add to login items

                // First check if it exists in the list
                // .notFound means it's not there yet
                if SMAppService.mainApp.status == .notFound {
                    // register() adds our app to the login items list
                    // Think of it like writing "MacShot" on your shopping list
                    try SMAppService.mainApp.register()
                }

                // Note: In macOS 13+, status is read-only
                // Use unregister to disable
                // The enabled state is managed by registration
            } else {
                // USER WANTS IT OFF - Remove from login items

                // unregister() removes the app from login items
                // Think of it like erasing from the shopping list
                try SMAppService.mainApp.unregister()
            }

            // Update our published property so UI updates
            launchAtLogin = enabled

        } catch {
            // Something went wrong
            print("Failed to toggle launch at login: \(error)")
        }
    }

    // IS AVAILABLE - Check if this macOS version supports SMAppService
    // SMAppService requires macOS 13.0 or later
    // Think of it like checking if your coffee maker has a timer feature
    func isAvailable() -> Bool {
        // SMAppService is available on macOS 13.0+
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }

    // INITIALIZER - Sets up the launch controller
    init() {
        // Check the actual macOS login items status
        // Think of it like "see what macOS thinks is set"
        checkStatus()
    }

    // LOAD FROM SETTINGS - Sync with SettingsStore
    /// Call this to load saved preference and sync with macOS
    /// Think of it like "check what we saved, make it match reality"
    func loadFromSettings() {
        // Use the saved preference
        launchAtLogin = SettingsStore.launchAtLogin

        // Make sure macOS matches what we want
        if launchAtLogin {
            toggle(enabled: true)
        } else {
            toggle(enabled: false)
        }
    }
}

// EXTENSION - Add macOS version check helper
extension LaunchController {

    // MAC OS VERSION - Get the current macOS version
    // Returns something like "13.0.0" or "14.2.1"
    func getmacOSVersion() -> String {
        // ProcessInfo is info about the current process (our app)
        // operatingSystemVersion is the macOS version
        let version = ProcessInfo.processInfo.operatingSystemVersion

        // String format: "major.minor.patch" like "13.0.0"
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    // REQUIREMENTS CHECK - Verify we meet the minimum requirements
    func meetsRequirements() -> Bool {
        // Parse the version string
        let version = ProcessInfo.processInfo.operatingSystemVersion

        // macOS 13.0 = major version 13
        // We need at least version 13 for SMAppService
        return version.majorVersion >= 13
    }
}
