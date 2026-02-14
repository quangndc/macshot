---
title: "Phase 06 - System Integration"
description: "Menu bar icon, global hotkeys, auto-start, and notifications"
status: pending
priority: P1
effort: 4h
branch: main
tags: [menu-bar, hotkey, notification]
created: 2026-02-14
---

## Context Links

- [Menu Bar Integration Research](../reports/researcher-260214-1310-macos-menu-bar-integration.md) - Complete NSStatusItem guide
- [Global Hotkey Research](../reports/researcher-260214-1310-macos-global-hotkey-research.md) - Hotkey registration
- [Launch at Login](../reports/researcher-260214-1310-macos-menu-bar-integration.md#launch-at-login)
- [Notifications](../reports/researcher-260214-1310-macos-menu-bar-integration.md#notifications-for-screenshot-confirmations)

## Overview

**Priority**: P1 (System integration)
**Status**: Not Started
**Description**: Menu bar icon, global hotkey registration, login item setup, and user notifications.

## Key Insights

From research:
- **NSStatusItem** - Modern menu bar API
- **SF Symbols** - Native icons with isTemplate
- **Carbon Hotkey** - Global hotkey registration (may need alternative)
- **SMAppService** - Login items (macOS 13+)
- **UNUserNotification** - Local notifications
- **AXIsProcessTrusted** - Accessibility check

## Requirements

### Functional
- Menu bar icon (camera symbol)
- Dropdown menu (Capture, Settings, Quit)
- Global hotkey (Cmd+Shift+5 default)
- Hotkey customization
- Launch at login toggle
- Export confirmation notifications
- Accessibility permission handling

### Non-Functional
- Native macOS appearance
- Responsive menu
- Proper permission prompts

## Architecture

```
System/
├── MenuBarManager.swift          # NSStatusItem setup
├── HotkeyManager.swift           # Global hotkey registration
├── NotificationManager.swift    # UNUserNotification
└── LaunchController.swift        # SMAppService login
```

### Data Flow

```
App Launch → MenuBarManager → Show status item
            → HotkeyManager → Register global hotkeys
            → LaunchController → Check login status
            → NotificationManager → Request auth

Hotkey Press → HotkeyManager → CaptureEngine → EditorWindow
```

## Related Code Files

### Create
- `MacShot/System/MenuBarManager.swift`
- `MacShot/System/HotkeyManager.swift`
- `MacShot/System/NotificationManager.swift`
- `MacShot/System/LaunchController.swift`
- `MacShot/Features/Settings/SettingsView.swift`
- `MacShot/Features/Settings/HotkeyRecorder.swift`

### Modify
- `MacShot/MacShotApp.swift` - Initialize system managers
- `MacShot/AppDelegate.swift` - Handle events

## Implementation Steps

### 1. Menu Bar Manager (1h)

```swift
// MenuBarManager.swift
import AppKit

@MainActor
final class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            let image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "MacShot")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "MacShot - Screenshot Tool"
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Capture Fullscreen", action: #selector(captureFullscreen), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Capture Region", action: #selector(captureRegion), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MacShot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc private func captureFullscreen() {
        // Trigger fullscreen capture
    }

    @objc private func captureRegion() {
        // Trigger region capture
    }

    @objc private func openSettings() {
        // Open settings window
    }
}
```

### 2. Hotkey Manager (1.5h)

```swift
// HotkeyManager.swift
import Carbon
import ApplicationServices

@MainActor
final class HotkeyManager: ObservableObject {
    private var hotkeyRef: EventHotKeyRef?
    private let captureHandler: () -> Void

    init(captureHandler: @escaping () -> Void) {
        self.captureHandler = captureHandler
    }

    func register(hotkey: Hotkey) -> Bool {
        unregister()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let hotkeyID = EventHotKeyID(signature: OSType(0x4D534854), id: UInt32(hotkey.id))

        var gHotkeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(hotkey.keyCode),
            UInt32(hotkey.modifiers),
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &gHotkeyRef
        )

        if status == noErr {
            hotkeyRef = gHotkeyRef
            installHandler()
            return true
        }

        return false
    }

    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
    }

    private func installHandler() {
        // Install event handler for hotkey
        // This requires more complex Carbon setup
    }
}

struct Hotkey: Codable {
    var id: Int
    var keyCode: UInt32
    var modifiers: UInt32
    var description: String
}
```

### 3. Notification Manager (0.5h)

```swift
// NotificationManager.swift
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            try await center.requestAuthorization(options: [.alert, .sound])
            return true
        } catch {
            return false
        }
    }

    func showScreenshotSaved(url: URL) {
        let content = UNMutableNotificationContent()
        content.title = "Screenshot Saved"
        content.body = "Saved to \(url.lastPathComponent)"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
```

### 4. Launch Controller (1h)

```swift
// LaunchController.swift
import ServiceManagement

@MainActor
final class LaunchController: ObservableObject {
    @Published var launchAtLogin = false

    func checkStatus() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func toggle(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .notFound {
                    try SMAppService.mainApp.register()
                }
                SMAppService.mainApp.status = .enabled
            } else {
                SMAppService.mainApp.status = .disabled
            }
            launchAtLogin = enabled
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }
}
```

## Todo List

- [ ] Create MenuBarManager
- [ ] Add menu item actions
- [ ] Create HotkeyManager
- [ ] Implement hotkey registration
- [ ] Create NotificationManager
- [ ] Request notification auth on first launch
- [ ] Create LaunchController
- [ ] Add launch at login toggle in settings
- [ ] Create HotkeyRecorder UI for customization
- [ ] Test Cmd+Shift+5
- [ ] Test menu bar icon in dark/light mode
- [ ] Test notifications
- [ ] Test launch at login
- [ ] Handle permission denials gracefully

## Success Criteria

- [ ] Menu bar icon visible
- [ ] Menu items trigger capture
- [ ] Global hotkey triggers capture
- [ ] Hotkey customizable in settings
- [ ] Launch at login works
- [ ] Notifications display
- [ ] Permissions requested properly

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Carbon API deprecation | Medium | Consider CGEventTap alternative |
| Permission denial | High | Graceful fallback, clear messaging |
| Hotkey conflicts | Low | Allow user to customize |

## Security Considerations

- Accessibility permission required
- Explain why permission needed
- Handle denial gracefully
- No sensitive data in notifications

## Next Steps

Proceed to **Phase 07 - Settings Persistence** once:
- Menu bar functional
- Hotkey registered
- Notifications working
- Launch at login works
