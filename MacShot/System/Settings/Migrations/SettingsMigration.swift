// SettingsMigration.swift - Settings version migration system
// Think of it like upgrading your phone - moves your stuff to new format safely
// When we add new settings or change structure, this moves old data to new format

import Foundation
import SwiftUI

// SETTINGS MIGRATION - Handles version upgrades
// Settings may change between app versions - this moves data safely
@MainActor
enum SettingsMigration {

    // Current version of settings format
    // Increment this when settings structure changes
    // Think of it like version number: 1, 2, 3...
    static let currentVersion: Int = 1

    // Key for storing version in UserDefaults
    // Think of it like a label on the storage box
    private static let versionKey = "settings.version"

    // MARK: - Migration

    /// Run any needed migrations on app launch
    /// Think of it like "check if upgrade needed, do it if so"
    static func migrateIfNeeded() {
        // Get stored version, or 0 if never set
        let storedVersion = UserDefaults.standard.integer(forKey: versionKey)

        // If stored version is older than current, run migrations
        // Think of it like "if old version, run upgrades"
        if storedVersion < currentVersion {
            print("Settings: migrating from v\(storedVersion) to v\(currentVersion)")

            // Run each migration in order
            // v0 to v1, v1 to v2, etc.
            for version in storedVersion..<(currentVersion) {
                migrate(from: version, to: version + 1)
            }

            // Save new version so we don't migrate again
            // Think of it like marking "upgrade complete"
            UserDefaults.standard.set(currentVersion, forKey: versionKey)
        }
    }

    /// Migrate from one version to next
    /// Think of it like "step-by-step upgrade instructions"
    private static func migrate(from: Int, to: Int) {
        switch (from, to) {
        case (0, 1):
            migrate_v0_to_v1()
        default:
            // No migration needed for this version
            break
        }
    }

    // MARK: - Version Migrations

    /// Version 0 to 1 migration
    /// Example: Adding new settings or restructuring
    /// Think of it like "original to first proper format"
    private static func migrate_v0_to_v1() {
        // Example migration tasks:
        // - Add new setting with default value
        // - Rename setting keys
        // - Convert data formats

        // For now, v1 is initial version, no migration needed
        // This is placeholder for future migrations
        print("Settings: v0 -> v1 migration complete")
    }

    // MARK: - Reset

    /// Reset settings to current version defaults
    /// Think of it like "factory reset" button
    /// WARNING: This deletes all user preferences!
    static func resetToDefaults() {
        // Remove all settings
        SettingsStore.resetToDefaults()

        // Reset version to current
        UserDefaults.standard.set(currentVersion, forKey: versionKey)

        print("Settings: reset to defaults, version \(currentVersion)")
    }

    // MARK: - Validation

    /// Check if settings are valid for current version
    /// Think of it like "make sure nothing is broken"
    static func validate() -> Bool {
        // Check required settings exist
        // If migration failed or corruption, return false

        // For v1, all settings have defaults, so always valid
        return true
    }
}
