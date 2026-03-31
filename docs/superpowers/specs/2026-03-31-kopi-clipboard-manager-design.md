# Kopi — macOS Clipboard Manager Design Spec

## Context

There is no free, open-source, lightweight clipboard manager for macOS that handles both text and images well. Existing options are either paid (Paste, CopyClip Pro), closed-source, or text-only. Kopi fills this gap as a fast, privacy-respecting clipboard manager that lives in the menu bar and supports image history — built with Swift/SwiftUI for macOS 14+.

## Overview

- **Name**: Kopi
- **License**: GPL
- **Platform**: macOS 14+ (Sonoma and newer)
- **Tech stack**: Swift, SwiftUI, AppKit (NSStatusItem, NSPanel), SwiftData
- **App style**: Menu bar icon + floating quick panel + dedicated history window
- **Bundle ID**: `com.kopi.app`
- **Project location**: `~/Projects/Personal/Repositories/kopi-app/`

## Features

### Core
- Monitor clipboard for text and image changes (0.5s polling via NSPasteboard.changeCount)
- Store clipboard history in SwiftData with 30-day auto-purge
- Pin items to persist beyond the 30-day window
- Global hotkey: Ctrl+Space (customizable) to toggle the quick panel
- Search and filter history by content, type (text/image), date, pinned status
- Image deduplication via content hashing

### Quick Panel (NSPanel)
- Floating panel anchored below menu bar icon
- Compact list layout: text items show truncated content, images show small thumbnails
- Search bar at top, filter chips (All / Text / Images / Pinned)
- Keyboard navigation: arrow keys to navigate, Enter to paste, Delete to remove
- Click menu bar icon or press Ctrl+Space to toggle

### History Window (SwiftUI Window)
- Master-detail NavigationSplitView
- Left pane: scrollable list grouped by date, with search and filters
- Right pane: full preview with metadata and actions (Pin, Copy, Delete)
- Opened from menu bar context menu or panel action

### Settings
- Customize global hotkey
- Configure purge duration (default 30 days)
- Toggle launch at login
- Clear all history

## Architecture

```
KopiApp (SwiftUI App)
├── AppDelegate
│   ├── StatusItemManager      — NSStatusItem setup, click handling
│   ├── ClipboardMonitor       — Timer-based NSPasteboard polling (0.5s)
│   └── HotkeyManager         — Ctrl+Space registration via KeyboardShortcuts
├── QuickPanel (NSPanel)
│   └── QuickPanelView         — SwiftUI content hosted via NSHostingView
├── HistoryWindow (SwiftUI Window scene)
│   └── HistoryView            — NavigationSplitView master-detail
├── SettingsWindow (SwiftUI Settings scene)
│   └── SettingsView           — Hotkey, purge, launch-at-login
└── Services
    ├── ClipboardStore         — SwiftData CRUD, purge logic, search
    └── ImageStorageService    — Hybrid blob/filesystem storage routing
```

### UI Framework Split
- **AppKit**: NSStatusItem (menu bar icon), NSPanel (quick panel container)
- **SwiftUI**: All view content inside panels/windows, settings, history window

### Clipboard Monitoring
- `Timer.scheduledTimer` fires every 0.5 seconds
- Compares `NSPasteboard.general.changeCount` against stored value
- On change: read pasteboard types, extract text or image, save to SwiftData
- Supported types: `NSPasteboard.PasteboardType.string`, `.tiff`, `.png`

### Paste from History
1. User selects item in quick panel or history window
2. App sets an internal `isWritingToPasteboard` flag
3. App writes content to `NSPasteboard.general`
4. App simulates Cmd+V via `CGEvent` to paste into the active app
5. Quick panel dismisses automatically
6. Flag is cleared after the next monitor tick (prevents self-capture loop)

### Image Deduplication (Images Only)
- Compute SHA-256 hash of image data before saving
- If hash matches an existing item in recent history, skip the save and update `lastUsedAt` on the existing item
- Prevents duplicates from repeated copies of the same screenshot/image
- Text items are not deduplicated — re-copying the same string creates a new entry (intentional re-copies are common)

## Data Model (SwiftData)

### ClipboardItem
| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `contentType` | `ContentType` | Enum: `.text`, `.image` |
| `textContent` | `String?` | Text content (for text items) |
| `imageData` | `Data?` | Image blob (for images < 128KB) |
| `imagePath` | `String?` | Filesystem path (for images >= 128KB) |
| `imageSize` | `Int?` | Original image size in bytes |
| `contentHash` | `String?` | SHA-256 hash for deduplication |
| `isPinned` | `Bool` | Pinned items skip auto-purge |
| `createdAt` | `Date` | When the item was copied |
| `lastUsedAt` | `Date` | Updated when user pastes from history |

### ContentType (Enum)
```swift
enum ContentType: String, Codable {
    case text
    case image
}
```

## Storage

### Text Items
- Stored directly in `textContent` field

### Image Items
- **< 128KB**: stored as blob in `imageData`
- **>= 128KB**: saved to `~/Library/Application Support/Kopi/Images/{uuid}.png`, path stored in `imagePath`

### Purge Logic
- Runs on app launch
- Deletes non-pinned items where `createdAt` is older than 30 days
- Deletes orphaned image files from the Images directory

## Dependencies (Swift Packages)

| Package | Purpose |
|---------|---------|
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | Global hotkey with customizable UI |
| [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) | Toggle launch at login |

## Menu Bar Icon

- Use SF Symbol `clipboard` or custom icon
- Single left-click: toggle quick panel
- Right-click: context menu (Open History, Settings, Quit)

## Permissions

- **Accessibility permission**: Required for CGEvent paste simulation (Cmd+V)
- **Non-sandboxed**: Required for global hotkey and pasteboard monitoring
- App should prompt user for Accessibility permission on first launch

## Verification Plan

1. **Clipboard monitoring**: Copy text and image in various apps, verify items appear in history
2. **Quick panel**: Press Ctrl+Space, verify panel toggles, search filters work
3. **Paste from history**: Select an item, verify it pastes into the active app
4. **Image storage**: Copy images of various sizes, verify small ones in DB and large ones on filesystem
5. **Deduplication**: Copy the same image twice, verify only one entry created
6. **Pinning**: Pin an item, advance system date past 30 days, verify it survives purge
7. **History window**: Open history, verify master-detail layout, date grouping, search
8. **Settings**: Change hotkey, verify new shortcut works
9. **Launch at login**: Enable, restart, verify app launches
