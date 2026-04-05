# Kopi 1.0.1 Stabilization Design

## Goal

Stabilize the 1.0.0 feature set so the implemented menu bar, clipboard history, search, paste, history, and settings flows behave consistently enough for a 1.0.1 patch release.

## Scope

- Fix clipboard self-write tracking so paste-from-history does not swallow the next real clipboard change.
- Fix quick panel and history search behavior so text, image, and pinned items behave consistently when filtering.
- Make opening Settings deterministic instead of relying on window introspection.
- Dismiss the quick panel explicitly after paste actions.
- Align obvious release metadata with the actual app target configuration where it is currently misleading.

## Non-Goals

- Redesign the UI.
- Add large new capabilities beyond the shipped 1.0.0 surface area.
- Replace the current AppKit + SwiftUI architecture.

## Design

### Clipboard self-write tracking

The current implementation uses a single Boolean to ignore the next clipboard poll after Kopi writes to the pasteboard. That is lossy because an external copy can occur before the next poll, causing a legitimate change to be skipped.

The fix is to track the exact pasteboard `changeCount` produced by Kopi's own write. The monitor should ignore only that specific count, then resume processing normally. If the user or another app changes the clipboard again before the next poll, the new `changeCount` must be processed instead of dropped.

### Search behavior

The current views duplicate filtering logic and apply the text query only to `textContent`, which makes image results disappear whenever a search term is present.

The fix is to extract shared filtering/search matching into a small helper that both views use. Text items should match against their text content. Image items should match against lightweight user-visible metadata already present in the UI, such as the display label and the generic "image" type label. This keeps the current feature set coherent without inventing unsupported metadata.

### Settings opening

The current settings flow searches existing windows by fragile heuristics. That can fail silently if the SwiftUI settings window is not currently discoverable.

The fix is to open settings through the standard application action first, with a lightweight fallback only if needed. This removes the dependency on private window type names.

### Quick panel dismissal

The current quick panel relies on focus changes to close after a paste. That is indirect and can leave the panel open unexpectedly.

The fix is to make paste actions explicitly request panel dismissal after the paste operation is triggered.

### Verification strategy

- Add regression tests for shared filtering logic and clipboard self-write tracking.
- Keep the existing storage tests green.
- Build the app in Release.
- Manually verify the menu bar flows that remain hard to automate in the current project.
