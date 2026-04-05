# Changelog

All notable changes to Kopi will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [1.0.1] - 2026-04-05

### Fixed
- Paste-from-history now ignores only Kopi's own pasteboard write, preventing real clipboard copies from being dropped immediately after a paste
- Search now returns matching image items in the quick panel and history views instead of filtering only by text content
- Pasting from the quick panel now closes the panel consistently instead of relying on focus changes
- `Open History` and `Settings...` from the menu bar now work on the first attempt instead of flashing and disappearing on first activation
- The menu bar `Settings...` action now reuses the native app settings scene and only falls back when an actual settings window is already present

### Changed
- Restored the standard macOS Settings toolbar appearance with per-tab icons
- Reorganized Settings into dedicated `General`, `Shortcuts`, `Storage`, `About`, and `Donate` tabs
- Added a `Donate` tab with a Buy Me a Coffee link
- Added regression tests for pasteboard self-write tracking, shared clipboard item search behavior, first-activation window hiding, deferred status menu actions, and native settings scene presentation
- Updated documentation and release metadata for the consolidated 1.0.1 patch release

## [1.0.0] - 2026-03-31

### Added
- Clipboard monitoring for text and images (0.5s polling via NSPasteboard)
- Quick panel with search, filter chips (All/Text/Images/Pinned), and keyboard navigation
- Global hotkey (Ctrl+Space, customizable) to toggle quick panel
- History window with NavigationSplitView, date grouping, and detail preview
- Pinning system — pinned items persist beyond auto-purge
- Image deduplication via SHA-256 hashing
- Hybrid image storage (blob for <128KB, filesystem for larger)
- Paste from history via CGEvent Cmd+V simulation
- 30-day auto-purge (configurable in Settings)
- Settings window with hotkey customization, purge duration, launch at login
- Context menu on items (Paste, Pin/Unpin, Delete)
- App icon — clipboard on blue-purple gradient
- Accessibility permission prompt on first launch
