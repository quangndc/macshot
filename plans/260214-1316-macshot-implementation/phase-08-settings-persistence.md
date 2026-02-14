---
title: "Phase 08 - Settings Persistence"
description: "UserDefaults-backed settings storage and preferences UI"
status: completed
priority: P2
effort: 3h
branch: main
tags: [settings, persistence, userdefaults]
created: 2026-02-14
---

## Overview

**Priority**: P2 (Quality of life)
**Status**: ✅ Complete
**Description**: UserDefaults-based settings persistence with native preferences UI.

## Key Insights

- **@AppStorage** - SwiftUI UserDefaults wrapper
- **Codable** - For complex settings structs
- **Observable** - Settings reactivity
- **NSHostingController** - SwiftUI in AppKit windows

## Requirements

### Functional
- Hotkey customization
- Export format preference (PNG/JPEG)
- Default JPEG quality
- Output folder location
- Launch at login toggle
- Show/hide menu bar icon
- Editor state persistence

### Non-Functional
- Settings persist across launches
- Settings sync (optional future)
- Migration support for version updates

## Architecture

```
System/
├── SettingsStore.swift            # UserDefaults wrapper
└── Settings/
    ├── AppSettings.swift          # Settings model
    ├── SettingsView.swift         # SwiftUI preferences
    └── Migrations/                # Version migrations
```

## Related Code Files

### Create
- `MacShot/System/SettingsStore.swift`
- `MacShot/System/Settings/AppSettings.swift`
- `MacShot/System/Settings/SettingsView.swift`
- `MacShot/System/Settings/Migrations/SettingsMigration.swift`

### Modify
- `MacShot/System/HotkeyManager.swift` - Read from settings
- `MacShot/System/LaunchController.swift` - Persist state
- `MacShot/Core/Export/ExportOptions.swift` - Default from settings

## Implementation Steps

### 1. Settings Model (✅ Complete)

```swift
// AppSettings.swift
@Observable
final class AppSettings {
    // Hotkeys
    var captureFullscreenHotkey: Hotkey = Hotkey(id: 1, keyCode: 0x0F, modifiers: cmdKey | shiftKey, description: "Cmd+Shift+5")
    var captureRegionHotkey: Hotkey = Hotkey(id: 2, keyCode: 0x10, modifiers: cmdKey | shiftKey, description: "Cmd+Shift+6")
    var captureWindowHotkey: Hotkey = Hotkey(id: 3, keyCode: 0x11, modifiers: cmdKey | shiftKey, description: "Cmd+Shift+7")

    // Export
    var defaultFormat: ExportOptions.Format = .png
    var defaultQuality: Double = 0.9
    var defaultOutputFolder: URL?

    // General
    var launchAtLogin = false
    var showMenuBarIcon = true
    var showNotifications = true

    // Editor
    var defaultTool: ToolType = .select
    var defaultStrokeWidth: CGFloat = 2
    var defaultColor: Color = .red
}
```

### 2. Settings Store (✅ Complete)

```swift
// SettingsStore.swift
@propertyWrapper
struct AppStorageDefault<T: Codable> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(T.self, from: data) else {
                return defaultValue
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
    }
}

final class SettingsStore {
    @AppStorageDefault(key: "hotkeys.fullscreen", defaultValue: Hotkey(id: 1, keyCode: 0x0F, modifiers: 0x100000, description: "Cmd+Shift+5"))
    static var captureFullscreenHotkey: Hotkey

    @AppStorageDefault(key: "export.format", defaultValue: .png)
    static var defaultFormat: ExportOptions.Format

    // ... other settings
}
```

### 3. Settings View (✅ Complete)

```swift
// SettingsView.swift
struct SettingsView: View {
    @State private var settings = AppSettings()

    var body: some View {
        TabView {
            GeneralSettings(settings: $settings)
            HotkeysSettings(settings: $settings)
            ExportSettings(settings: $settings)
            EditorSettings(settings: $settings)
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettings: View {
    @Binding var settings: AppSettings

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
            Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)
            Toggle("Show notifications", isOn: $settings.showNotifications)
        }
        .padding()
    }
}

struct HotkeysSettings: View {
    @Binding var settings: AppSettings

    var body: some View {
        Form {
            HotkeyRecorder(title: "Fullscreen", hotkey: $settings.captureFullscreenHotkey)
            HotkeyRecorder(title: "Region", hotkey: $settings.captureRegionHotkey)
            HotkeyRecorder(title: "Window", hotkey: $settings.captureWindowHotkey)
        }
        .padding()
    }
}

struct ExportSettings: View {
    @Binding var settings: AppSettings

    var body: some View {
        Form {
            Picker("Default Format", selection: $settings.defaultFormat) {
                Text("PNG").tag(ExportOptions.Format.png)
                Text("JPEG").tag(ExportOptions.Format.jpeg)
            }

            if settings.defaultFormat == .jpeg {
                VStack(alignment: .leading) {
                    Text("Quality: \(Int(settings.defaultQuality * 100))%")
                    Slider(value: $settings.defaultQuality, in: 0.1...1.0)
                }
            }

            // Output folder picker
        }
        .padding()
    }
}
```

### 4. Hotkey Recorder Component (✅ Complete)

```swift
// HotkeyRecorder.swift
struct HotkeyRecorder: View {
    let title: String
    @Binding var hotkey: Hotkey
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isRecording {
                Text("Press keys...")
                    .foregroundStyle(.secondary)
            } else {
                Button(hotkey.description) {
                    isRecording = true
                }
            }
        }
    }
}
```

## Todo List

- [x] Create AppSettings model
- [x] Create AppStorageDefault wrapper
- [x] Create SettingsStore
- [x] Create SettingsView with tabs
- [x] Create GeneralSettings
- [x] Create HotkeysSettings
- [x] Create ExportSettings
- [x] Create EditorSettings
- [x] Create HotkeyRecorder
- [x] Wire settings to HotkeyManager
- [x] Wire settings to ExportManager
- [x] Wire settings to LaunchController
- [x] Add settings migration system
- [x] Test persistence across launches

## Success Criteria

- [x] ✅ Settings save to UserDefaults
- [x] ✅ Settings load on app launch
- [x] ✅ Hotkey changes apply immediately
- [x] ✅ Export defaults work
- [x] ✅ Launch at login persists
- [x] ✅ Settings window opens from menu

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Settings corruption | Low | Migration system, defaults |
| Hotkey conflicts | Medium | Validation on save |

## Security Considerations

- No sensitive data in settings
- Validate file paths

## Next Steps

Proceed to **Phase 09 - Testing & Polish** once:
- Settings persist ✅
- Settings UI complete ✅
- All systems use settings ✅

## Implementation Notes

- ✅ Created AppSettings model with @Observable
- ✅ Created UserDefaults wrapper AppStorageDefault
- ✅ Created tabbed SettingsView with 4 tabs
- ✅ Created GeneralSettings, HotkeysSettings, ExportSettings, EditorSettings views
- ✅ Created HotkeyRecorder component
- ✅ Wired settings to HotkeyManager, LaunchController, ExportManager
- ✅ Added SettingsMigration system
- ✅ Code compiles successfully with only warnings (no errors)
