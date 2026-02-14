# macOS Global Hotkey Research Report

## NSHotkey vs Carbon Hotkey APIs

**NSHotkey (Modern - Recommended)**
- Available since macOS 10.6
- Uses native Cocoa APIs
- Better integration with modern macOS versions (15+)
- Swift-friendly, supports SwiftUI
- Simpler implementation

**Carbon Hotkey Legacy API**
- Deprecated since macOS 10.15
- Still functional but discouraged
- Requires Carbon framework
- More complex setup
- May be removed in future OS versions

**Recommendation**: Use NSHotkey for new applications on macOS 15+.

## Global Hotkey Registration

```swift
import Cocoa

class HotkeyManager {
    private var hotkey: Any?

    func registerHotkey(
        keyCode: UInt32,
        modifiers: NSEvent.ModifierFlags,
        target: Any?,
        action: Selector
    ) {
        unregisterHotkey()

        let options: Dictionary<String, Any> = [
            kAXMenuItemCmdKey: true
        ]

        hotkey = self
        AXUIElementCopyGlobalEventHandler(
            AXSystemWideElement,
            kAXMenuItemCreatedNotification,
            { element, observer in
                // Handle hotkey activation
                return nil
            },
            &hotkey
        )
    }

    func unregisterHotkey() {
        if let hotkey = hotkey {
            AXUIElementRemoveGlobalEventHandler(AXSystemWideElement, kAXMenuItemCreatedNotification, hotkey)
            self.hotkey = nil
        }
    }
}
```

## Hotkey Conflict Detection and Resolution

**Detection Methods**:
- Monitor system event logs for conflicts
- Check existing hotkeys using AX API
- User preference for conflict handling

**Resolution Strategies**:
- Inform user of conflicts
- Allow user to choose alternative hotkey
- Provide fallback combinations
- Document system reserved keys

## Modifier Keys Support

```swift
// Common modifier combinations
let cmd = NSEvent.ModifierFlags.command
let ctrl = NSEvent.ModifierFlags.control
let alt = NSEvent.ModifierFlags.option
let shift = NSEvent.ModifierFlags.shift

// Example combinations
cmd | shift        // Cmd+Shift
ctrl | alt         // Control+Option
cmd | ctrl | alt   // Cmd+Control+Option
```

## Permissions and Entitlements

Required permissions:
- `com.apple.security.temporary-entitlement.axapi` (AX API access)
- `com.apple.security.cs.allow-jit` (for code injection if needed)
- `com.apple.security.cs.allow-unsigned-executable-memory`

Privacy considerations:
- App must request accessibility permissions
- Users must grant permission via System Preferences
- Clear explanation of why accessibility access is needed

## Code Examples

### Modern Swift Implementation

```swift
import Cocoa
import ApplicationServices

class GlobalHotkey {
    private var hotkeyID: CFRunLoopSource?

    func register(hotkey: String, handler: @escaping () -> Void) -> Bool {
        let keyCode = keyToKeyCode(hotkey)
        let modifiers = modifiersFromString(hotkey)

        let options = [
            kAXMenuItemCmdKey: true
        ] as CFDictionary

        let observer = Unmanaged.passUnretained(self).toOpaque()

        return AXUIElementCopyGlobalEventHandler(
            AXSystemWideElement,
            kAXMenuItemCreatedNotification,
            { element, observer in
                DispatchQueue.main.async {
                    handler()
                }
                return nil
            },
            observer
        ) == noErr
    }

    private func keyToKeyCode(_ hotkey: String) -> UInt32 {
        // Implement key to keycode mapping
        return 0
    }

    private func modifiersFromString(_ hotkey: String) -> NSEvent.ModifierFlags {
        // Parse modifiers from string
        return []
    }
}
```

## Best Practices for Hotkey UX

1. **User Control**
   - Allow customization via settings
   - Provide visual feedback when hotkey is pressed
   - Show active hotkey in menu bar or preferences

2. **Discoverability**
   - Include hotkey info in Help menu
   - Show keyboard shortcuts in UI elements
   - Use standard macOS conventions

3. **Accessibility**
   - Ensure hotkeys work with screen readers
   - Provide alternative input methods
   - Respect accessibility settings

4. **Performance**
   - Register hotkeys on-demand
   - Clean up properly when app quits
   - Avoid conflicts with system shortcuts

5. **Testing**
   - Test on different macOS versions
   - Verify behavior with modifier keys
   - Check conflicts with system shortcuts

## Documentation References

- [Apple Accessibility Programming Guide](https://developer.apple.com/accessibility/)
- [AXUIElement Reference](https://developer.apple.com/documentation/applicationservices/axuielement)
- [NSEvent.ModifierFlags Documentation](https://developer.apple.com/documentation/appkit/nsevent/modifierflags)
- [Security Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements)

## Unresolved Questions

1. What specific security requirements exist for hotkey apps on macOS 15?
2. How do hotkeys interact with Stage Manager and new window management features?
3. Are there any new hotkey restrictions in macOS 15+ security updates?
4. What's the recommended approach for hotkey persistence across app sessions?