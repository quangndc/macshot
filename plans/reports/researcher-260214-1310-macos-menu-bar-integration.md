# macOS Menu Bar Integration Research

## NSStatusItem vs NSStatusBar

**NSStatusItem** is the preferred approach for menu bar apps:
- Introduced in macOS 10.8 as the modern replacement for NSStatusBar
- Provides automatic menu management and spacing
- Supports macOS menu bar runtime protections (UserApproved)
- Required for App Store distribution

**NSStatusBar** (legacy):
- Direct access to menu bar space
- More manual positioning required
- Less protection for users

*Source: [Apple Developer - NSStatusItem](https://developer.apple.com/documentation/appkit/nsstatusitem)*

## Creating Popup Menus with NSMenu

```swift
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
let menu = NSMenu()

// Add menu items
let screenshotItem = NSMenuItem(title: "Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: "")
menu.addItem(screenshotItem)

statusItem.menu = menu
```

**Key Features:**
- NSMenu supports hierarchical submenus
- NSMenuItem actions use `@objc` methods
- Key equivalents support system shortcuts
- Separator items for visual grouping

*Source: [Apple Documentation - NSMenu Class Reference](https://developer.apple.com/documentation/appkit/nsmenu)*

## Menu Bar Icon Best Practices

### Icons:
- **SF Symbols**: Use system-provided symbols (24x24pt)
- **Templates**: Always set `isTemplate = true` for dark/light mode support
- **High Contrast**: Maintain readability at small sizes

```swift
let image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "Take Screenshot")
image.isTemplate = true
statusItem.button?.image = image
```

### Accessibility:
- Always set accessibility description
- Support dynamic type if text is present
- Provide tooltips via `button?.toolTip`

*Source: [Apple Human Interface Guidelines - Menu Bar](https://developer.apple.com/design/human-interface-guidelines/macos/menu-bars/)*

## Launch at Login

### Modern Approach (macOS 13+):
```swift
import ServiceManagement

func setupLaunchAtLogin(enabled: Bool) {
    if SMAppService.mainApp.status == .notFound {
        try? SMAppService.mainApp.register()
    }
    SMAppService.mainApp.status = enabled ? .enabled : .disabled
}
```

**SMAppService Features (2024):**
- Replaces legacy launchd plist approach
- Automatic detection vs regular launch
- Status management with `.enabled`, `.disabled`, `.notFound`
- Requires `com.apple.security.automation.apple-events` entitlement

*Source: [Apple Developer - ServiceManagement](https://developer.apple.com/documentation/servicemanagement)

## Login Item Permissions & Entitlements

### Required Entitlements:
```xml
<key>com.apple.security.automation.apple-events</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

### Permission Prompts:
- `AXIsProcessTrusted()` for accessibility permissions
- System prompt for "Control computer"
- Full Disk Access (if needed for file access)

*Source: [Apple Developer - App Sandbox Permissions](https://developer.apple.com/documentation/security/app_sandbox)*

## Code Example: Complete Implementation

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupLaunchAtLogin()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "Screenshot App")
        statusItem.button?.image?.isTemplate = true

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc func takeScreenshot() {
        // Screenshot logic
        showNotification("Screenshot captured")
    }
}
```

*Source: [Apple Developer - Status Item Programming Guide](https://developer.apple.com/documentation/appkit/nsstatusitem)*

## Notifications for Screenshot Confirmations

**UNUserNotification** (macOS 10.14+):
```swift
import UserNotifications

func showNotification(_ title: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = "Screenshot saved to desktop"

    let request = UNNotificationRequest(identifier: UUID().uuidString,
                                       content: content,
                                       trigger: nil)

    UNUserNotificationCenter.current().add(request)
}
```

**Local Notification Requirements:**
- `com.apple.security.network.client` entitlement
- User authorization via `requestAuthorization`

*Source: [Apple Documentation - UserNotifications Framework](https://developer.apple.com/documentation/usernotifications)*

---

**Unresolved Questions:**
1. Best practices for menu bar icon animation
2. Menu positioning customization options
3. Migration path from NSStatusBar to NSStatusItem for legacy apps