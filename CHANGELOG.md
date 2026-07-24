# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-07-24

### Added
- **Menu Bar Management:** Click connected drives in the menu bar to Eject, Open in Finder, or Copy Path.
- **Excluded Drives:** Permanently exclude specific drives from being managed via the new Preferences tab.
- **Menu-Bar-Only Mode:** Ability to pause automatic Dock management while keeping menu bar functionality active.

### Changed
- Modernized the Excluded Drives UI for a cleaner, native look.

### Fixed
- Fixed a bug that incorrectly triggered the "Update Available" notification.
- Resolved higher-than-expected memory usage and reduced idle RAM footprint.
- Fixed a Preferences window sizing issue that caused excessive whitespace on shorter tabs.

## [1.0.0] - 2026-07-10

### Added
- Initial release.
- Automatically add external drives to the macOS Dock.
- Remove drives from the Dock upon ejection.
- Ignore DMG files, app installers, and Time Machine backups.
- Customizable Dock appearance (Folder vs Stack, List vs Grid).
