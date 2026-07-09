<div align="center">
  <img src="Assets/icon.iconset/icon_512x512.png" alt="AutoDockDrive Logo" width="128" />
  <h1>AutoDockDrive</h1>
  <p><b>A small macOS app that automatically manages your external drives in the Dock.</b></p>
</div>

---

AutoDockDrive runs quietly in the menu bar. Whenever you plug in an external drive, SD card, or USB stick, it automatically adds a shortcut to the right side of your Dock. When you eject the drive, the shortcut disappears. It's that simple!

## Features

* **Plug & Play:** Automatically adds a Dock shortcut when a drive connects.
* **Auto Cleanup:** Removes the shortcut when the drive is ejected.
* **Smart Filtering:** Ignores DMG files, app installers, and Time Machine backups so your Dock stays clean.
* **Customizable:** Choose how drives look in the Dock (Folder vs Stack, List vs Grid, etc.).
* **Launch at Login:** Can be set to start automatically when you turn on your Mac.

## Installation

1. Go to the [Releases page](../../releases/latest) and download `AutoDockDrive-1.0.dmg`.
2. Open the DMG and drag **AutoDockDrive** into your Applications folder.
3. Open it from Applications. 

*(Note: Because this isn't from the App Store, macOS will likely block it the first time you open it. To fix this, go to **System Settings > Privacy & Security**, scroll down, and click **Open Anyway** next to AutoDockDrive.)*

## Building from Source

If you want to build the app yourself without Xcode:

```bash
git clone https://github.com/willyhay22/AutoDockDrive.git
cd AutoDockDrive
./build.sh
```

## Requirements
* macOS 12.0 or newer
* Apple Silicon or Intel

## Uninstallation
1. Quit the app from the menu bar.
2. Delete it from your Applications folder.
