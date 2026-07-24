<div align="center">
  <img src="Assets/icon.iconset/icon_512x512.png" alt="AutoDockDrive Logo" width="128" />
  <h1>AutoDockDrive</h1>
  <p><b>A lightweight macOS app that automatically manages your external drives in the Dock.</b></p>
  
  <p>
    <a href="https://github.com/willyhay22/AutoDockDrive/releases/latest"><img src="https://img.shields.io/github/v/release/willyhay22/AutoDockDrive?style=for-the-badge&color=007AFF" alt="Latest Release"></a>
    <img src="https://img.shields.io/badge/macOS-12.0+-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 12.0+">
    <img src="https://img.shields.io/badge/Swift-5.5+-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift">
    <a href="LICENSE"><img src="https://img.shields.io/github/license/willyhay22/AutoDockDrive?style=for-the-badge&color=34C759" alt="License"></a>
  </p>
</div>

---

## Why AutoDockDrive?

AutoDockDrive was created because macOS doesn't provide a simple way to automatically place removable drives in the Dock while they're connected. 

The goal is to make external storage feel like a natural extension of your Mac without permanently cluttering your Dock. AutoDockDrive runs quietly in the menu bar. Whenever you plug in an external drive, SD card, or USB stick, it automatically adds a shortcut to the right side of your Dock. When you eject the drive, the shortcut instantly disappears.

## Features

* **Plug & Play:** Automatically pins a Dock shortcut when a drive connects.
* **Auto Cleanup:** Removes the shortcut seamlessly when the drive is ejected.
* **Smart Filtering:** Ignores `.dmg` files, app installers, and Time Machine backups so your Dock stays pristine.
* **Excluded Drives:** Permanently exclude specific drives (like your always-plugged-in backup drives) from being managed.
* **Menu Bar Manager:** Quickly Eject, Open, or Copy the path of connected drives directly from the menu bar without opening Finder.
* **Customizable:** Choose exactly how drives look in the Dock (Folder vs Stack, List vs Grid, etc.).

---

## Installation

### Option 1: Homebrew (Recommended)
You can easily install AutoDockDrive via Homebrew:
```bash
brew tap willyhay22/autodockdrive
brew trust willyhay22/autodockdrive
brew install --cask autodockdrive
```

### Option 2: Manual Download
1. Go to the [Releases page](https://github.com/willyhay22/AutoDockDrive/releases/latest) and download the latest `.dmg`.
2. Open the DMG and drag **AutoDockDrive** into your Applications folder.
3. Open it from Applications. 

> [!NOTE]  
> Because this isn't distributed via the Mac App Store, macOS may block it the first time you open it. To fix this, go to **System Settings > Privacy & Security**, scroll down, and click **Open Anyway** next to AutoDockDrive.

---

## Technical Details & Limitations

### Why does the Dock briefly restart?
macOS heavily caches the Dock state using a background process (`cfprefsd`). Writing directly to the Dock's preference files won't work instantly. AutoDockDrive uses a native `defaults export / import` workflow to safely inject the shortcut into the cache, then briefly restarts the Dock (`killall Dock`) to force the UI to refresh. This process takes a fraction of a second.

### Limitations
* **Network Drives:** Network attached storage (NAS) volumes are ignored by default.
* **Delay:** The Dock takes about 0.5 - 1.0 seconds to restart after a drive is mounted.

---

## Building from Source

If you want to build the app yourself without Xcode:

```bash
git clone https://github.com/willyhay22/AutoDockDrive.git
cd AutoDockDrive
./Scripts/build.sh
```

## Requirements
* macOS 12.0 or newer
* Apple Silicon (arm64) or Intel (x86_64)

## Uninstallation
1. Quit the app from the menu bar.
2. Delete it from your Applications folder.

## License
Released under the MIT License. See [LICENSE](LICENSE) for details.
