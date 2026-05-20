# DockStay

Pin your Mac Dock to one screen. No more Dock migration between monitors.

## What It Does

On multi-monitor Macs, the Dock moves to whichever screen your cursor touches the bottom edge of. DockStay prevents this by intercepting mouse events and nudging the cursor a few pixels away from the trigger zone on non-Dock screens. The Dock stays put. No restarts, no flicker, no system modifications.

## Install

### Homebrew

```bash
brew tap lmqferreira/dockstay
brew install dockstay
```

### Manual

```bash
git clone https://github.com/lmqferreira/dockstay.git
cd dockstay
make install
```

## Usage

Run `dockstay` — a 📌 pin icon appears in the menu bar.

- **Left click** the icon to toggle pinning on/off.
- **Right click** for Launch at Login and Quit.
- **That's it.** No settings files, no config, no daemon to manage.

## Permissions

DockStay needs **Accessibility** access to intercept mouse events.
On first launch it will prompt you. Grant access in:

**System Settings → Privacy & Security → Accessibility**

## How It Works

A `CGEventTap` intercepts mouse move and drag events. When the cursor reaches the bottom few pixels of a non-Dock screen, the y-coordinate is nudged up by 6 pixels. The Dock's trigger condition never fires. The callback runs in ~10 instructions with zero heap allocations.

Display changes, sleep/wake, and monitor connect/disconnect are handled automatically.

## Uninstall

```bash
make uninstall
# or if installed via Homebrew:
brew uninstall dockstay
```

## Requirements

- macOS 13 (Ventura) or later
- Multiple displays
- Accessibility permissions

## License

MIT
