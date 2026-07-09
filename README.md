# AutoDockDrive

AutoDockDrive is a native, lightweight macOS background utility that automatically manages your external storage devices within your Dock. It functions invisibly, dynamically adding your external hard drives, SD cards, and USB thumb drives to your Dock as soon as they are connected, and removing them perfectly when ejected.

## Features

- **Instant Recognition:** Automatically identifies removable volumes and adds a shortcut to the right side of your Dock.
- **Auto Cleanup:** Automatically removes the shortcut from the Dock immediately upon eject/unmount to prevent clutter.
- **Dock Appearance Preferences:** By default, it sets up drives to view as a Folder, sort by Date Modified, and open as a List. All of these preferences can be adjusted!
- **Menu Bar Integration:** A completely unobtrusive menu bar app (`externaldrive.fill.badge.plus`) gives you quick access to pause management, change preferences, and open currently managed drives.
- **Launch at Login:** Seamlessly integrates with macOS `SMAppService` to start silently in the background when you log in.
- **No Fragile Hacks:** Modifies `com.apple.dock.plist` using safe `defaults import / export` architecture to guarantee atomicity and sync with macOS's `cfprefsd`. 

## Installation

1. Download the `AutoDockDrive-1.0.dmg` file.
2. Open the DMG.
3. Drag the `AutoDockDrive.app` into the `Applications` folder shortcut.
4. Launch `AutoDockDrive` from your Applications folder.
5. Click on the AutoDockDrive menu bar icon and select **Start at Login**.

*Note: Since this application is not distributed via the Mac App Store or officially notarized by a paid Apple Developer Account, macOS Gatekeeper may block the first launch. Simply Right-Click (or Control-Click) the application and select **Open** to bypass Gatekeeper safely.*

## Building from Source

To build this app yourself without Xcode:

```bash
cd AutoDockDrive
./build.sh
```

The script will compile the Swift files, generate the `.app` bundle, sign it (ad-hoc), and package it into a standard `.dmg` inside the `build/` directory.

## Requirements

- macOS 12.0 Monterey or later.
- Apple Silicon (M1/M2/M3) or Intel processor (Universal Binary).

## Uninstallation

To completely remove AutoDockDrive:
1. Quit the application from the menu bar.
2. Delete `AutoDockDrive.app` from `/Applications`.
3. (Optional) Run `defaults delete com.wihay.AutoDockDrive` in Terminal to clear your preferences.
4. (Optional) Delete the log file at `~/Library/Logs/AutoDockDrive.log`.

## License

MIT License. See `LICENSE` for details.
