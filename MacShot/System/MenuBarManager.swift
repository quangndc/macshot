// MenuBarManager.swift
// This file manages the menu bar icon (top-right corner of your screen)
// Think of it like a toaster on your kitchen counter - always there, ready to use

import AppKit  // macOS framework for UI elements like menu bar

// @MainActor means this code runs on the main thread (the main "cooking station")
// This keeps UI updates safe and smooth
@MainActor
final class MenuBarManager: ObservableObject {

    // statusItem is our "toaster" - the actual icon in the menu bar
    // It's optional (?) because it might not exist yet
    private var statusItem: NSStatusItem?

    // captureEngine is like our "kitchen" - where screenshots get captured
    // We need this so menu items can trigger captures
    private weak var captureEngine: CaptureEngine?

    // openSettingsHandler is like a "button" that opens the settings window
    // We'll get this from the app delegate
    private var openSettingsHandler: () -> Void

    // INITIALIZER - This sets up our MenuBarManager
    // Think of it like taking the toaster out of the box and plugging it in
    init(
        captureEngine: CaptureEngine,
        openSettingsHandler: @escaping () -> Void = {}
    ) {
        self.captureEngine = captureEngine
        self.openSettingsHandler = openSettingsHandler
    }

    // SETUP - This creates the menu bar icon
    // Think of it like putting the toaster on the counter
    func setup() {
        // NSStatusBar.system is the "counter" at the top of your screen
        // statusItem(withLength:) creates a slot for our icon
        // NSStatusItem.variableLength means the slot shrinks/grows based on content
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Now let's add the icon (camera symbol) to our menu bar item
        if let button = statusItem?.button {
            // SF Symbols are Apple's built-in icons (like emoji but professional)
            // "camera.fill" is a filled camera icon
            // accessibilityDescription: helps screen readers understand what the icon is
            let image = NSImage(
                systemSymbolName: "camera.fill",
                accessibilityDescription: "MacShot"
            )

            // isTemplate = true means the icon changes color based on theme
            // Light mode = black icon, Dark mode = white icon
            image?.isTemplate = true

            // Put the image on the button (put the icon on the toaster)
            button.image = image

            // toolTip is the text that appears when you hover over the icon
            // Think of it like a label on the toaster explaining what it does
            button.toolTip = "MacShot - Screenshot Tool"
        }

        // Create the dropdown menu (the menu that appears when you click)
        setupMenu()
    }

    // SETUP MENU - This creates the dropdown menu items
    // Think of it like loading bread into the toaster
    private func setupMenu() {
        // NSMenu is the dropdown list of options
        let menu = NSMenu()

        // Add "Capture Fullscreen" option
        // title: text shown in menu
        // action: what happens when you click it (#selector means "call this function")
        // keyEquivalent: keyboard shortcut (empty "" means no shortcut here)
        menu.addItem(NSMenuItem(
            title: "Capture Fullscreen",
            action: #selector(captureFullscreen),
            keyEquivalent: ""
        ))

        // Add "Capture Region" option
        menu.addItem(NSMenuItem(
            title: "Capture Region",
            action: #selector(captureRegion),
            keyEquivalent: ""
        ))

        // separator() adds a horizontal line (visual divider)
        // Think of it like the line between different sections on a restaurant menu
        menu.addItem(NSMenuItem.separator())

        // Add "Settings..." option
        // The "," is the keyboard shortcut (Cmd+, is standard for Settings)
        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))

        // Another separator before Quit
        menu.addItem(NSMenuItem.separator())

        // Add "Quit MacShot" option
        // "q" is the keyboard shortcut (Cmd+Q is standard for Quit)
        // NSApplication.terminate(_:): is the built-in quit function
        menu.addItem(NSMenuItem(
            title: "Quit MacShot",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        // Attach the menu to our status item
        // Think of it like putting the menu card next to the toaster
        statusItem?.menu = menu
    }

    // CAPTURE FULLSCREEN - What happens when you click "Capture Fullscreen"
    // @objc means this function can be called from Objective-C (older Apple language)
    // NS needs this for menu items to work
    @objc private func captureFullscreen() {
        // Trigger fullscreen capture through the capture engine
        // Think of it like pressing the "toast" button
        // Use Task to run async code from sync context
        Task {
            try? await captureEngine?.captureFullscreen()
        }
    }

    // CAPTURE REGION - What happens when you click "Capture Region"
    @objc private func captureRegion() {
        // Trigger region capture (user selects area)
        // Think of it like pressing "select slice" button
        Task {
            try? await captureEngine?.captureRegion()
        }
    }

    // OPEN SETTINGS - What happens when you click "Settings..."
    @objc private func openSettings() {
        // Call the settings handler (opens settings window)
        // Think of it like pressing the "settings" button on the toaster
        openSettingsHandler()
    }
}
