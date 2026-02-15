# Edge Case Analysis: MacShot Settings System

**Scope:** MacShot settings system edge case verification
**Files Analyzed:**
- MacShot/System/Settings/AppSettings.swift
- MacShot/System/SettingsStore.swift
- MacShot/System/Settings/Migrations/SettingsMigration.swift
- MacShot/Features/Settings/HotkeysSettings.swift
- MacShot/Features/Settings/ExportSettings.swift
- MacShot/System/HotkeyManager.swift

---

## 1. UserDefaults Corrupted Data on Read

**Status:** ⚠️ Partial

### ✅ Handled:
- `AppStorageDefault` property wrapper has fallback to default value if JSON decode fails
- Basic error handling with `guard let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode(T.self, from: data) else { return defaultValue }`

### ❌ Unhandled:
- No validation of decoded data structure
- No logging when corruption occurs (silent fallback)
- No recovery mechanism for partially corrupted settings
- No protection against malformed JSON that could crash the app

### ⚠️ Partial:
- Need to add data validation after decode
- Should log corruption events for debugging
- Consider implementing data repair strategies

---

## 2. Settings Migration from Incompatible Version

**Status:** ❌ Unhandled

### ✅ Handled:
- Basic versioning system with `currentVersion` constant
- Sequential migration execution (`migrate(from: version, to: version + 1)`)
- Migration reset mechanism

### ❌ Unhandled:
- No validation of migrated data integrity
- No rollback mechanism if migration fails
- No handling for invalid version numbers (could be corrupted)
- No migration error logging
- No graceful degradation if migration completely fails

### ⚠️ Partial:
- Migration system exists but lacks robust error handling
- Need to add pre/post migration validation
- Should implement migration transaction pattern

---

## 3. Invalid Hotkey Combinations (Duplicate, System Conflict)

**Status:** ❌ Unhandled

### ✅ Handled:
- Hotkey recorder requires at least one modifier (prevents plain keys)
- Basic duplicate prevention within individual hotkey recorder

### ❌ Unhandled:
- No validation for duplicate hotkeys between different capture types
- No conflict detection with system hotkeys
- No validation for reserved/modifier-only combinations
- No hotkey uniqueness enforcement across settings
- No validation against existing app shortcuts

### ⚠️ Partial:
- Hotkey model lacks validation logic
- Need comprehensive hotkey validation service
- Should implement conflict detection system

---

## 4. Invalid File Path for Output Folder

**Status:** ❌ Unhandled

### ✅ Handled:
- File picker validates folder content type
- Basic path string storage with URL conversion helper

### ❌ Unhandled:
- No validation that folder exists and is accessible
- No permissions checking for write access
- No protection against network drives that might be unavailable
- No cleanup of invalid/non-existent folders
- No fallback behavior when output folder becomes invalid

### ⚠️ Partial:
- Need path validation on app launch
- Should implement accessibility checks
- Need periodic validation of output folder

---

## 5. Color Serialization Failure (Invalid Hex/Data)

**Status:** ⚠️ Partial

### ✅ Handled:
- Color hex string parsing has basic validation (6 characters, valid hex)
- Fallback to red on failure

### ❌ Unhandled:
- No logging of color parsing failures
- No validation of RGB value ranges
- No recovery from corrupted color data
- No protection against invalid color states

### ⚠️ Partial:
- Color parsing works but lacks robustness
- Need better error handling and logging
- Should implement color state validation

---

## 6. Settings Reset During Active Operation

**Status:** ❌ Unhandled

### ✅ Handled:
- Reset method exists in SettingsStore and SettingsMigration

### ❌ Unhandled:
- No protection against accidental resets
- No confirmation dialog for destructive reset
- No warning about data loss
- No undo mechanism for accidental resets
- No state preservation during critical operations

### ⚠️ Partial:
- Reset functionality exists but lacks safety measures
- Need confirmation dialogs and warnings
- Should implement transactional reset pattern

---

## Summary Recommendations

### Critical Issues (Fix Immediately):
1. **Hotkey validation** - Add comprehensive validation service
2. **File path validation** - Implement accessibility checks
3. **Migration safety** - Add rollback mechanisms

### High Priority:
1. **Data corruption handling** - Add validation and logging
2. **Reset protection** - Add confirmation dialogs
3. **Error logging** - Add comprehensive logging for all failures

### Medium Priority:
1. **Color robustness** - Improve error handling
2. **System hotkey conflicts** - Implement conflict detection
3. **Path monitoring** - Add periodic validation

### Code Quality Improvements:
- Add enum-based error types for all settings operations
- Implement settings validation service
- Add comprehensive logging throughout settings system
- Consider using Result types for async operations

---

## Unresolved Questions

1. Should settings validation run on app launch or only when accessed?
2. How should we handle partial settings corruption (some settings valid, others not)?
3. What's the strategy for handling deprecated settings that can't be migrated?
4. Should we implement settings backup/restore functionality?