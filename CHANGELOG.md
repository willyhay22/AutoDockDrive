# Changelog

All notable changes to this project will be documented in this file.

## [1.0] - 2026-07-07
### Added
- Initial release of AutoDockDrive.
- Background monitoring of external drives.
- Dynamic injection and removal of drives to/from the macOS Dock.
- Safely manages Dock sync using atomic `defaults import / export` architecture.
- Full Menu Bar UI with Pause, Refresh, and active drive lists.
- Settings and Preferences Window to customize Dock Appearance (Sort By, Display As, View As).
- Launch at Login functionality via macOS SMAppService API.
- Comprehensive background logging.
- Standalone `.dmg` packaging.
