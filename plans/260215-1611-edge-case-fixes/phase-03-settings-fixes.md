# Phase 03: Settings System Validation

**Priority:** HIGH
**Status:** Pending
**Estimated Complexity:** Medium

---

## Overview

Fix settings system edge cases related to data validation, migration recovery, and user safety. These fixes ensure user preferences are reliable and recoverable.

---

## Issues to Fix

### 1. Settings Migration Rollback

**Problem:** No rollback mechanism for failed migrations
**Location:** `System/Settings/Migrations/SettingsMigration.swift`

**Impact:**
- Users left with invalid settings
- No recovery from migration errors
- Data loss potential

**Solution:**
```swift
// Add to SettingsMigration.swift
enum SettingsMigration {
    static let currentVersion: Int = 1

    static func migrateIfNeeded() throws {
        let storedVersion = UserDefaults.standard.integer(forKey: "settings.version")

        guard storedVersion < currentVersion else {
            return // Already at current version
        }

        // Backup current settings before migration
        let backup = createBackup()

        do {
            // Run migrations in sequence
            for version in storedVersion..<currentVersion {
                try migrate(from: version, to: version + 1)
            }

            // Update version on success
            UserDefaults.standard.set(currentVersion, forKey: "settings.version")

        } catch {
            // Rollback on failure
            restoreFromBackup(backup)
            throw MigrationError.failed(rollback: true)
        }
    }

    private static func createBackup() -> [String: Any] {
        var backup: [String: Any] = [:]

        // Backup all settings keys
        let keys = [
            "hotkeys.fullscreen", "hotkeys.region", "hotkeys.window",
            "export.format", "export.quality", "export.outputFolder",
            "launchAtLogin", "showMenuBarIcon", "showNotifications",
            "editor.defaultTool", "editor.defaultStrokeWidth", "editor.defaultColor"
        ]

        for key in keys {
            backup[key] = UserDefaults.standard.object(forKey: key)
        }

        return backup
    }

    private static func restoreFromBackup(_ backup: [String: Any]) {
        for (key, value) in backup {
            UserDefaults.standard.set(value, forKey: key)
        }
    }
}

enum MigrationError: Error, LocalizedError {
    case failed(rollback: Bool)

    var errorDescription: String? {
        "Settings migration failed and was rolled back."
    }
}
```

**Files:**
- MODIFY: `MacShot/System/Settings/Migrations/SettingsMigration.swift`

**Testing:**
- Corrupted settings data
- Migration failure scenarios
- Backup restoration verification

---

### 2. Duplicate Hotkey Detection

**Problem:** No validation for duplicate hotkey combinations
**Location:** `Features/Settings/HotkeysSettings.swift`

**Impact:**
- Users can set same hotkey for different actions
- Unpredictable behavior
- Confusing user experience

**Solution:**
```swift
// Add to AppSettings.swift
@Observable
final class AppSettings: Equatable {
    var captureFullscreenHotkey: Hotkey
    var captureRegionHotkey: Hotkey
    var captureWindowHotkey: Hotkey

    // NEW: Validation method
    func validateHotkeys() throws {
        let hotkeys = [
            ("fullscreen", captureFullscreenHotkey),
            ("region", captureRegionHotkey),
            ("window", captureWindowHotkey)
        ]

        // Check for duplicates
        var seen: [Hotkey: String] = [:]
        for (name, hotkey) in hotkeys {
            if let existing = seen[hotkey] {
                throw SettingsError.duplicateHotkey(
                    hotkey: hotkey,
                    actions: [existing, name]
                )
            }
            seen[hotkey] = name
        }
    }
}

enum SettingsError: Error, LocalizedError {
    case duplicateHotkey(hotkey: Hotkey, actions: [String])

    var errorDescription: String? {
        if case let .duplicateHotkey(hotkey, actions) = self {
            "Hotkey '\(hotkey.description)' is assigned to multiple actions: \(actions.joined(separator: " and "))"
        }
        return nil
    }
}

// Update HotkeysSettings.swift
struct HotkeysSettings: View {
    @Binding var settings: AppSettings

    var body: some View {
        Form {
            HotkeyRow(title: "Fullscreen Capture", hotkey: $settings.captureFullscreenHotkey)
            HotkeyRow(title: "Region Capture", hotkey: $settings.captureRegionHotkey)
            HotkeyRow(title: "Window Capture", hotkey: $settings.captureWindowHotkey)
        }
        .onChange(of: settings.captureFullscreenHotkey) { _, _ in
            validateAndSave()
        }
        .onChange(of: settings.captureRegionHotkey) { _, _ in
            validateAndSave()
        }
        .onChange(of: settings.captureWindowHotkey) { _, _ in
            validateAndSave()
        }
    }

    private func validateAndSave() {
        do {
            try settings.validateHotkeys()
            // Save to store
            SettingsStore.sync(from: settings)
        } catch let error as SettingsError {
            // Show error alert
            showError(error)
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/System/Settings/AppSettings.swift`
- MODIFY: `MacShot/Features/Settings/HotkeysSettings.swift`

**Testing:**
- Set same hotkey for different actions
- Modify existing hotkeys
- Validation error display

---

### 3. Invalid File Path Validation

**Problem:** No validation for output folder accessibility
**Location:** `Features/Settings/ExportSettings.swift`

**Impact:**
- Can set inaccessible folder
- Export fails with cryptic error
- Poor user experience

**Solution:**
```swift
// Add to SettingsStore.swift
@MainActor
final class SettingsStore {
    static func validateOutputFolder(_ url: URL) throws {
        let manager = FileManager.default

        // Check if path exists
        var isDirectory: ObjCBool = false
        if !manager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            throw SettingsError.folderNotAccessible(url)
        }

        // Check if it's a directory
        guard isDirectory else {
            throw SettingsError.notADirectory(url)
        }

        // Check if writable
        if !manager.isWritableFile(atPath: url.path) {
            throw SettingsError.folderNotWritable(url)
        }

        // Check available space (at least 100MB)
        if let values = try? manager.valuesOfItem(atPath: url.path).resourceValues,
           let available = values.volumeAvailableCapacityForImportantUsage,
           available < 100_000_000 {
            throw SettingsError.insufficientDiskSpace(url, available: available)
        }
    }
}

enum SettingsError: Error, LocalizedError {
    case folderNotAccessible(URL)
    case notADirectory(URL)
    case folderNotWritable(URL)
    case insufficientDiskSpace(URL, available: Int64)

    var errorDescription: String? {
        switch self {
        case .folderNotAccessible(let url):
            "Folder not accessible: \(url.path)"
        case .notADirectory(let url):
            "Not a directory: \(url.path)"
        case .folderNotWritable(let url):
            "Folder not writable: \(url.path)"
        case .insufficientDiskSpace(let url, let available):
            "Insufficient disk space (\(available / 1_000_000)MB available)"
        }
    }
}

// Update ExportSettings.swift
struct ExportSettings: View {
    @Binding var settings: AppSettings
    @State private var showFolderPicker = false

    var body: some View {
        Form {
            // Output folder selection
            Button("Select Output Folder") {
                showFolderPicker = true
            }

            if let folder = settings.defaultOutputFolder {
                Text(folder.path)
                    .foregroundStyle(.secondary)
            }
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsOtherContentTypes: false
        ) { result in
            switch result {
            case .success(let url):
                validateAndSetFolder(url)
            case .failure:
                break
            }
        }
    }

    private func validateAndSetFolder(_ url: URL) {
        do {
            // Validate before setting
            try SettingsStore.validateOutputFolder(url)

            // Set the validated URL
            settings.defaultOutputFolder = url

            // Save to store
            SettingsStore.sync(from: settings)

        } catch let error as SettingsError {
            showError(error)
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/System/SettingsStore.swift`
- MODIFY: `MacShot/Features/Settings/ExportSettings.swift`

**Testing:**
- Select non-existent folder
- Select file instead of folder
- Select read-only folder
- Select folder with insufficient space

---

### 4. Color Serialization Error Handling

**Problem:** Basic hex parsing fallback without error logging
**Location:** `SettingsStore.swift`

**Impact:**
- Silent failures on invalid colors
- No recovery information
- Debugging difficulty

**Solution:**
```swift
// Enhance color handling in SettingsStore.swift
extension Color: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hexString = try container.decode(String.self)

        guard let data = Data(hexString: hexString) else {
            // Log the error for debugging
            os_log(.fault, log: OSLog.default, "Invalid color hex string: %{public}@", hexString)

            // Use fallback and note it
            self = .red
            throw DecodingError.invalidColor(hexString, fallback: "red")
        }

        // Parse color...
    }
}

enum DecodingError: Error, LocalizedError {
    case invalidColor(String, fallback: String)

    var errorDescription: String? {
        if case let .invalidColor(hex, fallback) = self {
            "Invalid color '\(hex)', using '\(fallback)' instead"
        }
        return nil
    }
}

// Add error logging to settings sync
@MainActor
final class SettingsStore {
    static func sync(from settings: AppSettings) {
        do {
            // Encode and save settings
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            UserDefaults.standard.set(data, forKey: "settings.data")
        } catch {
            os_log(.error, log: OSLog.default, "Settings sync failed: %{public}@", error.localizedDescription)
        }
    }
}
```

**Files:**
- MODIFY: `MacShot/System/SettingsStore.swift`

**Testing:**
- Invalid hex color values
- Truncated color data
- Encoding failure scenarios

---

### 5. Settings Reset Safety

**Problem:** No confirmation or undo for settings reset
**Location:** `AppSettings.swift`, Settings UI files

**Impact:**
- Accidental data loss
- User frustration
- No recovery mechanism

**Solution:**
```swift
// Add to AppSettings.swift
@Observable
final class AppSettings: Equatable {
    // NEW: Create backup before reset
    func createBackup() -> Data {
        let encoder = JSONEncoder()
        return (try? encoder.encode(self)) ?? Data()
    }

    static func restoreFromBackup(_ data: Data) -> AppSettings? {
        let decoder = JSONDecoder()
        return try? decoder.decode(AppSettings.self, from: data)
    }
}

// Add to GeneralSettings.swift
struct GeneralSettings: View {
    @Binding var settings: AppSettings
    @State private var showResetConfirmation = false
    @State private var lastBackup: Data?
    @State private var canUndoReset = false

    var body: some View {
        Form {
            // ... other settings ...

            Section {
                Button("Reset All Settings", role: .destructive) {
                    showResetConfirmation = true
                }
                .disabled(canUndoReset)

                if canUndoReset {
                    Button("Undo Reset") {
                        undoReset()
                    }
                }
            }
        }
        .alert("Reset All Settings", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                performReset()
            }
        } message: {
            Text("This will reset all settings to defaults. Your current settings will be backed up and can be restored.")
        }
    }

    private func performReset() {
        // Create backup before reset
        lastBackup = settings.createBackup()

        // Reset to defaults
        settings = AppSettings.defaults

        // Enable undo
        canUndoReset = true

        // Save
        SettingsStore.sync(from: settings)
    }

    private func undoReset() {
        guard let backup = lastBackup,
              let restored = AppSettings.restoreFromBackup(backup) else {
            return
        }

        settings = restored
        canUndoReset = false
        lastBackup = nil

        // Save
        SettingsStore.sync(from: settings)
    }
}
```

**Files:**
- MODIFY: `MacShot/System/Settings/AppSettings.swift`
- MODIFY: `MacShot/Features/Settings/GeneralSettings.swift`

**Testing:**
- Reset settings
- Undo reset
- Backup/restore verification

---

## Success Criteria

- [ ] Settings migration can rollback on failure
- [ ] Duplicate hotkeys detected and prevented
- [ ] Output folder validated before saving
- [ ] Color errors logged and handled gracefully
- [ ] Settings reset has confirmation and undo
- [ ] All settings edge cases tested

---

## Next Steps

After completing this phase:
1. Move to [Phase 04: Hotkey System Improvements](./phase-04-hotkey-fixes.md)
2. Update settings tests
3. Test migration scenarios

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Backup data size | Low | Only backup critical keys |
| Validation false positives | Medium | Test with various folder states |
| Rollback failure | Medium | Test rollback extensively |
