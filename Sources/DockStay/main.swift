// main.swift — DockStay menu bar app
// Minimal NSApplication with status item. No Dock icon.

import Cocoa
import ServiceManagement

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let defaults = UserDefaults.standard

    private let kEnabled = "enabled"
    private let kLaunchAtLogin = "launchAtLogin"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check accessibility permissions
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )
        if !trusted {
            let alert = NSAlert()
            alert.messageText = "DockStay needs Accessibility access"
            alert.informativeText = "Grant access in System Settings → Privacy & Security → Accessibility, then relaunch DockStay."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Quit")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            NSApp.terminate(nil)
            return
        }

        // Load preferences
        defaults.register(defaults: [kEnabled: true, kLaunchAtLogin: false])
        gEnabled = defaults.bool(forKey: kEnabled)

        // Set up screens and monitoring
        refreshScreens()
        startDisplayMonitor()

        // Set up status bar — left click toggles, right click shows menu
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()

        if let button = statusItem.button {
            button.action = #selector(statusBarClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Start event tap if enabled
        if gEnabled {
            if !startEventTap() {
                gEnabled = false
                defaults.set(false, forKey: kEnabled)
                updateIcon()
            }
        }
    }

    // MARK: - Status Bar Icon

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let name = gEnabled ? "pin.fill" : "pin.slash"
        button.image = NSImage(systemSymbolName: name, accessibilityDescription: "DockStay")
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        // Launch at login
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = defaults.bool(forKey: kLaunchAtLogin) ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit DockStay", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    @objc private func statusBarClicked(_ sender: Any?) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            // Right click: show menu
            statusItem.menu = buildMenu()
            statusItem.button?.performClick(nil)
            // Clear menu so left click works next time
            DispatchQueue.main.async { self.statusItem.menu = nil }
        } else {
            // Left click: toggle
            toggleEnabled()
        }
    }

    @objc private func toggleEnabled() {
        if gEnabled {
            stopEventTap()
            gEnabled = false
        } else {
            gEnabled = startEventTap()
        }
        defaults.set(gEnabled, forKey: kEnabled)
        updateIcon()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let current = defaults.bool(forKey: kLaunchAtLogin)
        let newValue = !current
        defaults.set(newValue, forKey: kLaunchAtLogin)

        do {
            if newValue {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Revert on failure
            defaults.set(current, forKey: kLaunchAtLogin)
        }
    }

    @objc private func quitApp() {
        stopEventTap()
        NSApp.terminate(nil)
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
