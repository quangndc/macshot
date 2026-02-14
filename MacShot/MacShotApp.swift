import SwiftUI

// Main app entry point for MacShot
@main
struct MacShotApp: App {
    // Persistent window for the app
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene for menu bar only app
        // Will be configured in later phases
        Settings {
            EmptyView()
        }
    }
}

// App delegate for macOS lifecycle events
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // TODO: Initialize menu bar and capture engine
        print("MacShot launched")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in menu bar
        return false
    }
}
