import SwiftUI

// Main app entry point for MacShot
@main
struct MacShotApp: App {
    // Persistent window for the app
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene for menu bar only app
        Settings {
            EmptyView()
        }
    }
}

// App delegate for macOS lifecycle events
class AppDelegate: NSObject, NSApplicationDelegate {
    // Capture engine instance
    var captureEngine: CaptureEngine?
    var editorWindow: EditorWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize capture engine
        captureEngine = CaptureEngine()
        captureEngine?.onCaptureComplete = { [weak self] result in
            self?.showEditor(with: result)
        }

        print("MacShot launched - Capture Engine initialized")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in menu bar
        return false
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
