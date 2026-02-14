// NotificationManager.swift
// This file manages notifications (those banners that slide in from top-right)
// Think of it like the "ding" when your toast pops - tells you it's done

import UserNotifications  // Apple's framework for notifications (UN = User Notifications)

// @MainActor means this runs on the main thread for safety
@MainActor
final class NotificationManager: ObservableObject {

    // REQUEST AUTHORIZATION - Ask user permission to show notifications
    // macOS requires apps to ask before showing notifications
    // Think of it like asking "can I ding when toast is ready?"
    // Returns true if user said yes, false if no
    func requestAuthorization() async -> Bool {
        // UNUserNotificationCenter.current() gets the notification center
        // Think of it like the notification manager for your Mac
        let center = UNUserNotificationCenter.current()

        do {
            // requestAuthorization() asks macOS for permission
            // .alert = show banner notification
            // .sound = play sound with notification
            try await center.requestAuthorization(options: [.alert, .sound])

            // If we get here, user said yes!
            return true

        } catch {
            // If we get here, user said no or something went wrong
            print("Notification authorization failed: \(error)")
            return false
        }
    }

    // SHOW SCREENSHOT SAVED - Show notification when screenshot exports
    // Think of it like the "ding" when toast pops
    func showScreenshotSaved(url: URL) {
        // UNMutableNotificationContent is the notification itself
        // Think of it like writing a note to show the user
        let content = UNMutableNotificationContent()

        // title is the big bold text at the top
        content.title = "Screenshot Saved"

        // body is the smaller text below the title
        // url.lastPathComponent is just the filename (not the whole path)
        // So /Users/you/Pictures/screenshot-1.png becomes "screenshot-1.png"
        content.body = "Saved to \(url.lastPathComponent)"

        // .default is the standard notification sound
        content.sound = .default

        // UNNotificationRequest is the actual request to show the notification
        // identifier: unique ID for this notification (UUID = random unique string)
        // content: what we created above
        // trigger: nil means "show immediately" (no delay)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        // add() tells macOS "show this notification now"
        UNUserNotificationCenter.current().add(request) { error in
            // This completion handler runs after macOS tries to add it
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }

    // SHOW ERROR - Show notification when something goes wrong
    func showError(message: String) {
        // Create notification content
        let content = UNMutableNotificationContent()

        // Title and body for error
        content.title = "MacShot Error"
        content.body = message

        // No sound for errors (don't want to be annoying)
        content.sound = nil

        // Create and add the request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show error notification: \(error)")
            }
        }
    }

    // CHECK AUTHORIZATION STATUS - Check if we already have permission
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        // getNotificationSettings() returns the current settings
        // .authorizationStatus tells us if we can show notifications
        let settings = await UNUserNotificationCenter.current()
            .notificationSettings()

        return settings.authorizationStatus
    }

    // INITIALIZER - Sets up the notification manager
    init() {
        // Note: We don't set delegate for now to avoid Swift 6 concurrency issues
        // Basic notification sending works without delegate
    }
}
