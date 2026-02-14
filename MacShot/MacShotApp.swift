import SwiftUI

// Main app entry point for MacShot
// Think of it like the blueprint for the whole house
@main
struct MacShotApp: App {
    // Persistent window for the app
    // NSApplicationDelegateAdaptor connects SwiftUI to AppKit lifecycle
    // Think of it like the main power switch for the house
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene for menu bar only app
        // Settings is a scene type that shows a settings window
        // EmptyView means "no main window" (we live in menu bar)
        Settings {
            EmptyView()
        }
    }
}

// App delegate for macOS lifecycle events
// Think of it like the house manager - handles all the setup and cleanup
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - System Managers (The Kitchen Appliances)

    // Capture engine - takes screenshots
    // Think of it like the camera in our kitchen
    var captureEngine: CaptureEngine?

    // Menu bar manager - shows icon in menu bar
    // Think of it like the toaster on the counter
    var menuBarManager: MenuBarManager?

    // Hotkey manager - registers global hotkeys
    // Think of it like the TV remote control
    var hotkeyManager: HotkeyManager?

    // Notification manager - shows alerts
    // Think of it like the "ding" when toast pops
    var notificationManager: NotificationManager?

    // Launch controller - handles launch at login
    // Think of it like the auto-on timer
    var launchController: LaunchController?

    // Editor window - shows screenshot editor
    var editorWindow: EditorWindow?

    // MARK: - App Launch (Plugging Everything In)

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 MacShot launching...")

        // STEP 1: Initialize capture engine first
        // Everything depends on this, so set it up first
        captureEngine = CaptureEngine()

        // Set up the callback for when capture completes
        // This is like "what happens after the photo is taken"
        captureEngine?.onCaptureComplete = { [weak self] result in
            self?.showEditor(with: result)
        }

        print("✓ Capture Engine initialized")

        // STEP 2: Initialize notification manager
        // We need this early so we can show success/error messages
        Task { @MainActor in
            notificationManager = NotificationManager()

            // Ask user for permission to show notifications
            // This shows a system dialog on first launch
            let authorized = await notificationManager?.requestAuthorization() ?? false
            print(authorized ? "✓ Notifications authorized" : "⚠ Notifications denied")
        }

        // STEP 3: Initialize hotkey manager
        // This registers the global hotkey (Cmd+Shift+5)
        hotkeyManager = HotkeyManager(captureHandler: { [weak self] in
            // When hotkey is pressed, trigger capture
            self?.handleHotkeyPress()
        })

        // Register the default hotkey
        let registered = hotkeyManager?.register(hotkey: Hotkey.default) ?? false
        print(registered ? "✓ Hotkey registered (⌘⇧5)" : "⚠ Hotkey registration failed")

        // STEP 4: Initialize launch controller
        // This checks if we're set to launch at login
        launchController = LaunchController()
        print("✓ Launch controller ready")

        // STEP 5: Initialize menu bar manager
        // This is last because it shows the icon to the user
        // We want everything ready before the user sees the app
        menuBarManager = MenuBarManager(
            captureEngine: captureEngine!,
            openSettingsHandler: { [weak self] in
                self?.openSettings()
            }
        )
        menuBarManager?.setup()
        print("✓ Menu bar icon showing")

        print("✓ MacShot fully launched!")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in menu bar
        // Think of it like "don't turn off when all windows close"
        // We live in the menu bar, not windows
        return false
    }

    // MARK: - Helper Functions

    // HANDLE HOTKEY PRESS - Called when user presses Cmd+Shift+5
    @MainActor
    private func handleHotkeyPress() {
        // Trigger region capture when hotkey pressed
        // Think of it like "remote button pressed - change channel"
        Task {
            try? await captureEngine?.captureRegion()
        }
    }

    // OPEN SETTINGS - Shows the settings window
    @MainActor
    private func openSettings() {
        // Create settings window
        // Think of it like "open the control panel"
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.center()  // Put window in center of screen
        settingsWindow.title = "MacShot Settings"

        // Create the settings view and show it
        let settingsView = SettingsView()
        settingsWindow.contentView = NSHostingView(rootView: settingsView)
        settingsWindow.makeKeyAndOrderFront(nil)  // Bring to front
    }

    // MARK: - Editor

    @MainActor
    private func showEditor(with result: CaptureResult) {
        // Close existing editor if open
        editorWindow?.close()

        // Create and show new editor window
        editorWindow = EditorWindow(captureResult: result)
    }
}
