# Kopi 1.0.1 Stabilization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stabilize the shipped 1.0.0 feature set so Kopi is suitable for a 1.0.1 patch release.

**Architecture:** Keep the current AppKit + SwiftUI structure intact, but extract the unstable logic into small testable seams. Fix the regressions in shared logic first, then wire the UI to those corrected seams.

**Tech Stack:** Swift, SwiftUI, AppKit, SwiftData, Swift Testing, XCTest

---

## File Map

- Modify: `Kopi/Kopi/Services/ClipboardMonitor.swift`
- Modify: `Kopi/Kopi/Services/PasteService.swift`
- Create: `Kopi/Kopi/Services/PasteboardChangeTracker.swift`
- Create: `Kopi/Kopi/Views/ClipboardItemSearch.swift`
- Modify: `Kopi/Kopi/Views/QuickPanelView.swift`
- Modify: `Kopi/Kopi/Views/HistoryView.swift`
- Modify: `Kopi/Kopi/AppDelegate.swift`
- Modify: `README.md`
- Create: `Kopi/KopiTests/PasteboardChangeTrackerTests.swift`
- Create: `Kopi/KopiTests/ClipboardItemSearchTests.swift`

### Task 1: Fix clipboard self-write tracking

**Files:**
- Create: `Kopi/Kopi/Services/PasteboardChangeTracker.swift`
- Modify: `Kopi/Kopi/Services/ClipboardMonitor.swift`
- Modify: `Kopi/Kopi/Services/PasteService.swift`
- Test: `Kopi/KopiTests/PasteboardChangeTrackerTests.swift`

- [ ] **Step 1: Write the failing tests**
- [ ] **Step 2: Run `xcodebuild -project Kopi/Kopi.xcodeproj -scheme Kopi -destination 'platform=macOS' -only-testing KopiTests/PasteboardChangeTrackerTests test` and verify the new tests fail**
- [ ] **Step 3: Replace the Boolean self-write flag with exact `changeCount` tracking**
- [ ] **Step 4: Re-run the focused test target and verify it passes**

### Task 2: Fix shared search/filter behavior

**Files:**
- Create: `Kopi/Kopi/Views/ClipboardItemSearch.swift`
- Modify: `Kopi/Kopi/Views/QuickPanelView.swift`
- Modify: `Kopi/Kopi/Views/HistoryView.swift`
- Test: `Kopi/KopiTests/ClipboardItemSearchTests.swift`

- [ ] **Step 1: Write the failing tests for text and image search matching**
- [ ] **Step 2: Run `xcodebuild -project Kopi/Kopi.xcodeproj -scheme Kopi -destination 'platform=macOS' -only-testing KopiTests/ClipboardItemSearchTests test` and verify the new tests fail**
- [ ] **Step 3: Extract shared search logic and update both views to use it**
- [ ] **Step 4: Re-run the focused test target and verify it passes**

### Task 3: Make settings opening deterministic and close the panel explicitly after paste

**Files:**
- Modify: `Kopi/Kopi/AppDelegate.swift`
- Modify: `Kopi/Kopi/Views/QuickPanelView.swift`

- [ ] **Step 1: Add the smallest testable seam needed for the settings opening logic if extraction is required**
- [ ] **Step 2: Replace the window-lookup-first behavior with the standard settings action and keep a safe fallback only if needed**
- [ ] **Step 3: Add an explicit panel-close request after paste actions in the quick panel**
- [ ] **Step 4: Verify these flows manually because the current UI test target does not cover them**

### Task 4: Final verification and metadata cleanup

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update release-facing documentation where the implementation target/version details are currently misleading**
- [ ] **Step 2: Run `xcodebuild -project Kopi/Kopi.xcodeproj -scheme Kopi -destination 'platform=macOS' -only-testing KopiTests test`**
- [ ] **Step 3: Run `xcodebuild -project Kopi/Kopi.xcodeproj -scheme Kopi -configuration Release -destination 'platform=macOS' build`**
- [ ] **Step 4: Perform a manual checklist for copy text, copy image, search, pin/unpin, paste from panel, settings reopen, and history opening**
