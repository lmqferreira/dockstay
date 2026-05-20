// main.swift — DockStay menu bar app
// NSApplication with status item and settings window.

import Cocoa
import ServiceManagement

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private let defaults = UserDefaults.standard

    private let kEnabled = "enabled"
    private let kLaunchAtLogin = "launchAtLogin"
    private let kShowMenuBarIcon = "showMenuBarIcon"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prompt for accessibility if not already granted. Don't quit — app still works for UI,
        // event tap will just fail until permission is granted and app restarted.
        if !AXIsProcessTrusted() {
            _ = AXIsProcessTrustedWithOptions(
                [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            )
        }

        // Load preferences
        defaults.register(defaults: [kEnabled: true, kLaunchAtLogin: false, kShowMenuBarIcon: true])
        gEnabled = defaults.bool(forKey: kEnabled)

        // Set up screens and monitoring
        refreshScreens()
        startDisplayMonitor()

        // Set up menu bar icon if enabled
        if defaults.bool(forKey: kShowMenuBarIcon) {
            showMenuBarIcon()
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

    // Re-launching the app (e.g. from Spotlight) opens the settings window
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettingsWindow()
        return false
    }

    // MARK: - Menu Bar Icon

    private func showMenuBarIcon() {
        guard statusItem == nil else { return }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()
        if let button = statusItem?.button {
            button.action = #selector(statusBarClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func hideMenuBarIcon() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        let name = gEnabled ? "pin.fill" : "pin.slash"
        button.image = NSImage(systemSymbolName: name, accessibilityDescription: "DockStay")
    }

    // MARK: - Right-Click Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let hideItem = NSMenuItem(title: "Hide Icon", action: #selector(hideIconFromMenu), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettingsWindow), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit DockStay", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Settings Window

    @objc private func showSettingsWindow() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "DockStay"
        window.center()
        window.isReleasedWhenClosed = false

        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]

        var y: CGFloat = 155

        // Enabled toggle
        let enabledCheck = NSButton(checkboxWithTitle: "Dock pinning enabled", target: self, action: #selector(settingsToggleEnabled(_:)))
        enabledCheck.frame = NSRect(x: 20, y: y, width: 280, height: 20)
        enabledCheck.state = gEnabled ? .on : .off
        enabledCheck.tag = 1
        contentView.addSubview(enabledCheck)
        y -= 30

        // Launch at login
        let loginCheck = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(settingsToggleLaunchAtLogin(_:)))
        loginCheck.frame = NSRect(x: 20, y: y, width: 280, height: 20)
        loginCheck.state = defaults.bool(forKey: kLaunchAtLogin) ? .on : .off
        loginCheck.tag = 2
        contentView.addSubview(loginCheck)
        y -= 30

        // Show menu bar icon
        let iconCheck = NSButton(checkboxWithTitle: "Show menu bar icon", target: self, action: #selector(settingsToggleMenuBarIcon(_:)))
        iconCheck.frame = NSRect(x: 20, y: y, width: 280, height: 20)
        iconCheck.state = defaults.bool(forKey: kShowMenuBarIcon) ? .on : .off
        iconCheck.tag = 3
        contentView.addSubview(iconCheck)
        y -= 40

        // Info label
        let infoLabel = NSTextField(labelWithString: "Tip: Re-open DockStay from Spotlight\nto access this window when icon is hidden.")
        infoLabel.frame = NSRect(x: 20, y: y, width: 280, height: 35)
        infoLabel.font = NSFont.systemFont(ofSize: 11)
        infoLabel.textColor = .secondaryLabelColor
        contentView.addSubview(infoLabel)

        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    // MARK: - Settings Actions

    @objc private func settingsToggleEnabled(_ sender: NSButton) {
        if sender.state == .on {
            gEnabled = startEventTap()
            sender.state = gEnabled ? .on : .off
        } else {
            stopEventTap()
            gEnabled = false
        }
        defaults.set(gEnabled, forKey: kEnabled)
        updateIcon()
    }

    @objc private func settingsToggleLaunchAtLogin(_ sender: NSButton) {
        let newValue = sender.state == .on
        defaults.set(newValue, forKey: kLaunchAtLogin)
        do {
            if newValue {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            defaults.set(!newValue, forKey: kLaunchAtLogin)
            sender.state = newValue ? .off : .on
        }
    }

    @objc private func settingsToggleMenuBarIcon(_ sender: NSButton) {
        let show = sender.state == .on
        defaults.set(show, forKey: kShowMenuBarIcon)
        if show {
            showMenuBarIcon()
        } else {
            hideMenuBarIcon()
        }
    }

    // MARK: - Status Bar Actions

    @objc private func statusBarClicked(_ sender: Any?) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            statusItem?.menu = buildMenu()
            statusItem?.button?.performClick(nil)
            DispatchQueue.main.async { self.statusItem?.menu = nil }
        } else {
            toggleEnabled()
        }
    }

    @objc private func toggleEnabled() {
        if gEnabled {
            stopEventTap()
            gEnabled = false
        } else {
            gEnabled = startEventTap()
            // If event tap failed (no accessibility), show alert
            if !gEnabled {
                let alert = NSAlert()
                alert.messageText = "Cannot enable Dock pinning"
                alert.informativeText = "Accessibility permissions are required. Grant access in System Settings, then try again."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
        defaults.set(gEnabled, forKey: kEnabled)
        updateIcon()
        // Update settings window checkbox if open
        if let contentView = settingsWindow?.contentView,
           let checkbox = contentView.viewWithTag(1) as? NSButton {
            checkbox.state = gEnabled ? .on : .off
        }
    }

    @objc private func hideIconFromMenu() {
        defaults.set(false, forKey: kShowMenuBarIcon)
        hideMenuBarIcon()
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
