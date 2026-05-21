// Core.swift — DockStay engine
// Zero-abstraction, global-state design. The event tap callback is the hot path:
// no allocations, no locks, no logging. Just math on pre-computed screen rects.

import Cocoa
import CoreGraphics

// MARK: - Screen Data

struct ScreenInfo {
    let cgFrame: CGRect     // CG coordinates (top-left origin, y-down)
    let name: String
    let hasDock: Bool
    let dockEdge: DockEdge
}

enum DockEdge {
    case bottom, left, right, none
}

// MARK: - Global State

var gScreens: [ScreenInfo] = []
var gEnabled: Bool = true
var gNudgePixels: CGFloat = 6.0
private var gEventTap: CFMachPort?
private var gRunLoopSource: CFRunLoopSource?

// MARK: - Dock Preferences

/// Read Dock orientation from preferences. Falls back to .bottom.
private func dockOrientationFromPrefs() -> DockEdge {
    guard let prefs = UserDefaults(suiteName: "com.apple.dock"),
          let orient = prefs.string(forKey: "orientation") else {
        return .bottom
    }
    switch orient {
    case "left": return .left
    case "right": return .right
    default: return .bottom
    }
}

/// Check if Dock autohide is enabled
private func dockAutohideEnabled() -> Bool {
    return UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") ?? false
}

// MARK: - Screen Detection

func refreshScreens() {
    guard let primary = NSScreen.screens.first else {
        gScreens = []
        return
    }
    let pH = primary.frame.height
    let prefsEdge = dockOrientationFromPrefs()

    var foundDock = false
    gScreens = NSScreen.screens.enumerated().map { (index, screen) in
        let ns = screen.frame
        let vis = screen.visibleFrame

        // NSScreen (bottom-left origin) → CG (top-left origin)
        let cgFrame = CGRect(
            x: ns.origin.x,
            y: pH - ns.origin.y - ns.height,
            width: ns.width,
            height: ns.height
        )

        // Detect Dock edge by comparing frame vs visibleFrame.
        // The menu bar takes ~37px at top. Dock takes 50+ px when visible.
        let bottomGap = vis.origin.y - ns.origin.y
        let leftGap = vis.origin.x - ns.origin.x
        let rightGap = (ns.origin.x + ns.width) - (vis.origin.x + vis.width)

        let dockThreshold: CGFloat = 45
        var edge: DockEdge = .none
        if bottomGap > dockThreshold { edge = .bottom }
        else if leftGap > dockThreshold { edge = .left }
        else if rightGap > dockThreshold { edge = .right }

        if edge != .none { foundDock = true }

        return ScreenInfo(
            cgFrame: cgFrame,
            name: screen.localizedName,
            hasDock: edge != .none,
            dockEdge: edge
        )
    }

    // If no screen detected as having the Dock (autohide or small Dock),
    // assume main screen has it with orientation from preferences.
    if !foundDock && !gScreens.isEmpty {
        let mainIdx = NSScreen.screens.firstIndex(where: { $0 == NSScreen.main }) ?? 0
        let old = gScreens[mainIdx]
        gScreens[mainIdx] = ScreenInfo(
            cgFrame: old.cgFrame,
            name: old.name,
            hasDock: true,
            dockEdge: prefsEdge
        )
    }
}

// MARK: - Event Tap (Hot Path)

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    // Re-enable if system disabled us
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = gEventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    if !gEnabled { return Unmanaged.passUnretained(event) }

    let loc = event.location
    let nudge = gNudgePixels
    let screens = gScreens

    for screen in screens {
        guard screen.cgFrame.contains(loc) else { continue }

        // If this screen has the Dock, don't touch it
        if screen.hasDock { break }

        // Nudge away from the Dock-trigger edge.
        // Use the Dock edge from whichever screen has the Dock, default bottom.
        let dockEdge = screens.first(where: { $0.hasDock })?.dockEdge ?? .bottom

        switch dockEdge {
        case .bottom:
            let dist = screen.cgFrame.maxY - loc.y
            if dist < nudge {
                event.location = CGPoint(x: loc.x, y: screen.cgFrame.maxY - nudge)
            }
        case .left:
            let dist = loc.x - screen.cgFrame.minX
            if dist < nudge {
                event.location = CGPoint(x: screen.cgFrame.minX + nudge, y: loc.y)
            }
        case .right:
            let dist = screen.cgFrame.maxX - loc.x
            if dist < nudge {
                event.location = CGPoint(x: screen.cgFrame.maxX - nudge, y: loc.y)
            }
        case .none:
            break
        }
        break
    }

    return Unmanaged.passUnretained(event)
}

// MARK: - Event Tap Lifecycle

func startEventTap() -> Bool {
    if gEventTap != nil { return true }

    // Intercept moves AND drags — dragging to the edge can also trigger Dock migration
    let mask: CGEventMask =
        (1 << CGEventType.mouseMoved.rawValue) |
        (1 << CGEventType.leftMouseDragged.rawValue) |
        (1 << CGEventType.rightMouseDragged.rawValue) |
        (1 << CGEventType.otherMouseDragged.rawValue)

    guard let tap = CGEvent.tapCreate(
        tap: .cghidEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: mask,
        callback: eventTapCallback,
        userInfo: nil
    ) else {
        return false
    }

    let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    gEventTap = tap
    gRunLoopSource = source
    return true
}

func stopEventTap() {
    if let tap = gEventTap {
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = gRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        gEventTap = nil
        gRunLoopSource = nil
    }
}

// MARK: - Display Monitor

private func displayReconfigCallback(
    display: CGDirectDisplayID,
    flags: CGDisplayChangeSummaryFlags,
    userInfo: UnsafeMutableRawPointer?
) {
    if flags.contains(.addFlag) || flags.contains(.removeFlag) ||
       flags.contains(.movedFlag) || flags.contains(.setMainFlag) {
        DispatchQueue.main.async { refreshScreens() }
    }
}

func startDisplayMonitor() {
    CGDisplayRegisterReconfigurationCallback(displayReconfigCallback, nil)

    NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.screensDidWakeNotification,
        object: nil, queue: .main
    ) { _ in refreshScreens() }

    NotificationCenter.default.addObserver(
        forName: NSApplication.didChangeScreenParametersNotification,
        object: nil, queue: .main
    ) { _ in refreshScreens() }
}
