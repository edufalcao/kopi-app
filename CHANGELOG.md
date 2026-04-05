# Changelog

All notable changes to Kopi will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [1.0.2] - 2026-04-05

### Fixed
- `Open History` and `Settings...` from the menu bar now work on the first attempt instead of flashing and disappearing on first activation
- The menu bar Settings action now reuses the real native macOS Settings scene instead of falling back to a plain window presentation
- Settings reopening now follows the app menu callback first, then only falls back to selector-based reopening when an actual settings window is present

### Changed
- Added regression tests for first-activation window hiding, status menu action dispatch timing, and native settings scene presentation
- Restored the standard macOS Settings toolbar appearance with per-tab icons

## [1.0.1] - 2026-04-05

### Fixed
- Paste-from-history now ignores only Kopi's own pasteboard write, preventing real clipboard copies from being dropped immediately after a paste
- Search now returns matching image items in the quick panel and history views instead of filtering only by text content
- Pasting from the quick panel now closes the panel consistently instead of relying on focus changes
- The menu bar `Settings...` action now uses the standard app settings route instead of a fragile window lookup

### Changed
- Added regression tests for pasteboard self-write tracking and shared clipboard item search behavior
- Updated documentation and release metadata for the 1.0.1 patch release

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
