# Kopi - Claude Code Context

## Project
Kopi is a macOS clipboard manager (menu bar app) that tracks text and image clipboard history with pinning, search, and a global hotkey.

## Tech Stack
- Swift / SwiftUI + AppKit hybrid
- SwiftData for persistence
- macOS 14+ deployment target (built with Xcode 16+)
- KeyboardShortcuts and LaunchAtLogin-Modern (SPM dependencies)
- Non-sandboxed, LSUIElement (no Dock icon)

## Architecture
- **AppKit**: NSStatusItem (menu bar), NSPanel (floating quick panel), NSWindow (history)
- **SwiftUI**: All view content, settings window
- **Services**: ClipboardMonitor (0.5s polling), ClipboardStore (SwiftData CRUD), ImageStorageService (hybrid blob/filesystem), PasteService (CGEvent Cmd+V)

## Key Paths
- Xcode project: `Kopi/Kopi.xcodeproj`
- App source: `Kopi/Kopi/` (Models, Services, MenuBar, Views, Utilities)
- Tests: `Kopi/KopiTests/` (19 tests)
- Xcode auto-discovers files via PBXFileSystemSynchronizedRootGroup — just create files on disk

## Build & Test
```bash
xcodebuild -project Kopi/Kopi.xcodeproj -scheme Kopi -destination 'platform=macOS' build
xcodebuild -project Kopi/Kopi.xcodeproj -scheme Kopi -destination 'platform=macOS' -only-testing KopiTests test
```

## Release
Use the `kopi-release` skill (`.claude/skills/kopi-release/SKILL.md`). Tag-triggered GitHub Actions workflow builds DMG automatically.

## Known Patterns
- SwiftData enum predicates crash on macOS 14 — `fetch(contentType:)` uses in-memory filtering as workaround
- FloatingPanel must NOT override `keyDown` — it breaks SwiftUI event delivery. Key events use NSEvent.addLocalMonitorForEvents in StatusItemManager
- Settings window is `orderOut`'d on first launch (not `close()`'d) to keep it reopenable
- SourceKit shows false positive errors for cross-file types — ignore if xcodebuild succeeds
