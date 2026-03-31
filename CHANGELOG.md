# Changelog

All notable changes to Kopi will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

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
