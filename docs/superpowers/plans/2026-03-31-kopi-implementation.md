# Kopi — Clipboard Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Kopi, a macOS clipboard manager with text + image history, pinning, global hotkey, and smart search — living in the menu bar with a floating quick panel and a full history window.

**Architecture:** Hybrid AppKit + SwiftUI. NSStatusItem for menu bar, NSPanel for floating quick panel, SwiftUI for all view content and the history window. SwiftData for persistence with hybrid image storage (blob for small, filesystem for large). Timer-based NSPasteboard polling at 0.5s intervals.

**Tech Stack:** Swift, SwiftUI, AppKit, SwiftData, KeyboardShortcuts, LaunchAtLogin, macOS 14+

**Spec:** `docs/superpowers/specs/2026-03-31-kopi-clipboard-manager-design.md`

---

## File Structure

```
kopi-app/
├── Kopi/
│   ├── KopiApp.swift                    — App entry, scenes, ModelContainer
│   ├── AppDelegate.swift                — Service init, menu bar, lifecycle
│   ├── Models/
│   │   └── ClipboardItem.swift          — SwiftData model + ContentType enum
│   ├── Services/
│   │   ├── ClipboardMonitor.swift       — NSPasteboard polling, dedup
│   │   ├── ClipboardStore.swift         — CRUD, search, purge
│   │   ├── ImageStorageService.swift    — Hybrid blob/filesystem routing
│   │   └── PasteService.swift           — Write to pasteboard + CGEvent
│   ├── MenuBar/
│   │   ├── StatusItemManager.swift      — NSStatusItem, click handling
│   │   └── FloatingPanel.swift          — NSPanel subclass
│   ├── Views/
│   │   ├── QuickPanelView.swift         — Panel SwiftUI content
│   │   ├── ClipboardItemRow.swift       — Reusable row for item lists
│   │   ├── FilterChipsView.swift        — All/Text/Images/Pinned chips
│   │   ├── HistoryView.swift            — NavigationSplitView master-detail
│   │   ├── HistoryDetailView.swift      — Right pane preview + actions
│   │   └── SettingsView.swift           — Settings window content
│   └── Utilities/
│       └── HotkeyManager.swift          — KeyboardShortcuts integration
├── KopiTests/
│   ├── ClipboardStoreTests.swift        — CRUD, search, purge tests
│   └── ImageStorageServiceTests.swift   — Blob vs filesystem tests
├── docs/
└── .gitignore
```

---

## Task 1: Xcode Project Setup

**Files:**
- Create: Xcode project `Kopi.xcodeproj`
- Create: `Kopi/KopiApp.swift` (skeleton)
- Create: `.gitignore`

- [ ] **Step 1: Create new Xcode project**

Open Xcode → File → New → Project → macOS → App

Configure:
- Product Name: `Kopi`
- Team: (your personal team or None)
- Organization Identifier: `com.kopi`
- Bundle Identifier: `com.kopi.app`
- Interface: SwiftUI
- Language: Swift
- Storage: None (we'll add SwiftData manually)
- Testing System: Swift Testing
- Save to: `~/Projects/Personal/Repositories/kopi-app/`

Make sure Xcode creates the project _inside_ the existing `kopi-app/` directory (uncheck "Create Git repository" since we already have one).

- [ ] **Step 2: Configure project settings**

In Xcode → Project → Kopi target → General:
- Minimum Deployments: macOS 14.0
- App Category: Utilities

In Signing & Capabilities:
- Uncheck "App Sandbox" (remove the sandbox capability entirely)
- The app needs to be non-sandboxed for global hotkey and pasteboard monitoring

In Info tab, add:
- `LSUIElement` = `YES` (Boolean) — this makes the app a menu bar agent with no Dock icon

- [ ] **Step 3: Add Swift Package dependencies**

In Xcode → Project → Package Dependencies → Add (+):

1. `https://github.com/sindresorhus/KeyboardShortcuts` → Up to Next Major Version → 2.0.0
2. `https://github.com/sindresorhus/LaunchAtLogin-Modern` → Up to Next Major Version → 1.0.0

In target → General → Frameworks, Libraries, and Embedded Content, make sure both `KeyboardShortcuts` and `LaunchAtLogin` are listed.

- [ ] **Step 4: Create folder structure**

In Xcode's Project Navigator, create groups under `Kopi/`:
- `Models`
- `Services`
- `MenuBar`
- `Views`
- `Utilities`

- [ ] **Step 5: Replace KopiApp.swift with skeleton**

Replace the generated `KopiApp.swift` with:

```swift
import SwiftUI
import SwiftData

@main
struct KopiApp: App {
    var body: some Scene {
        // Scenes will be added as we build each component
        Settings {
            Text("Kopi Settings")
                .frame(width: 300, height: 200)
        }
    }
}
```

- [ ] **Step 6: Create .gitignore**

Create `.gitignore` at the project root (`kopi-app/.gitignore`):

```
# Xcode
*.xcodeproj/project.xcworkspace/
*.xcodeproj/xcuserdata/
xcuserdata/
DerivedData/
*.moved-aside
*.xcuserstate

# Swift Package Manager
.build/
.swiftpm/

# macOS
.DS_Store
.superpowers/

# Build
build/
```

- [ ] **Step 7: Build and verify**

Run: Cmd+B in Xcode
Expected: Build succeeds with no errors. App launches but does nothing visible (LSUIElement hides Dock icon).

- [ ] **Step 8: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add -A
git commit -m "feat: initial Xcode project setup with dependencies"
```

---

## Task 2: SwiftData Model

**Files:**
- Create: `Kopi/Models/ClipboardItem.swift`
- Modify: `Kopi/KopiApp.swift` (add ModelContainer)

- [ ] **Step 1: Create ClipboardItem model**

Create `Kopi/Models/ClipboardItem.swift`:

```swift
import Foundation
import SwiftData

enum ContentType: String, Codable {
    case text
    case image
}

@Model
final class ClipboardItem {
    var id: UUID
    var contentType: ContentType
    var textContent: String?
    var imageData: Data?
    var imagePath: String?
    var imageSize: Int?
    var contentHash: String?
    var isPinned: Bool
    var createdAt: Date
    var lastUsedAt: Date

    init(
        contentType: ContentType,
        textContent: String? = nil,
        imageData: Data? = nil,
        imagePath: String? = nil,
        imageSize: Int? = nil,
        contentHash: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = UUID()
        self.contentType = contentType
        self.textContent = textContent
        self.imageData = imageData
        self.imagePath = imagePath
        self.imageSize = imageSize
        self.contentHash = contentHash
        self.isPinned = isPinned
        self.createdAt = Date()
        self.lastUsedAt = Date()
    }
}
```

- [ ] **Step 2: Add ModelContainer to KopiApp**

Update `Kopi/KopiApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct KopiApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([ClipboardItem.self])
            let config = ModelConfiguration(
                "KopiStore",
                schema: schema
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        Settings {
            Text("Kopi Settings")
                .frame(width: 300, height: 200)
        }
        .modelContainer(modelContainer)
    }
}
```

- [ ] **Step 3: Build and verify**

Run: Cmd+B in Xcode
Expected: Build succeeds. SwiftData model compiles without errors.

- [ ] **Step 4: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/Models/ClipboardItem.swift Kopi/KopiApp.swift
git commit -m "feat: add ClipboardItem SwiftData model and ModelContainer"
```

---

## Task 3: ImageStorageService

**Files:**
- Create: `Kopi/Services/ImageStorageService.swift`
- Create: `KopiTests/ImageStorageServiceTests.swift`

- [ ] **Step 1: Write failing tests**

Create `KopiTests/ImageStorageServiceTests.swift`:

```swift
import Testing
import Foundation
@testable import Kopi

@Suite("ImageStorageService Tests")
struct ImageStorageServiceTests {
    let service: ImageStorageService
    let testDir: URL

    init() throws {
        testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("KopiTests-\(UUID().uuidString)")
        service = ImageStorageService(imagesDirectory: testDir)
    }

    @Test("Small image stored as blob, not on filesystem")
    func smallImageReturnsBlob() throws {
        let smallImage = Data(repeating: 0xFF, count: 1024) // 1KB
        let result = try service.store(imageData: smallImage)

        #expect(result.blob != nil)
        #expect(result.path == nil)
        #expect(result.blob == smallImage)
    }

    @Test("Large image stored on filesystem, not as blob")
    func largeImageReturnsPath() throws {
        let largeImage = Data(repeating: 0xFF, count: 200_000) // ~200KB
        let result = try service.store(imageData: largeImage)

        #expect(result.blob == nil)
        #expect(result.path != nil)

        let savedData = try Data(contentsOf: URL(fileURLWithPath: result.path!))
        #expect(savedData == largeImage)
    }

    @Test("Retrieve image from filesystem path")
    func retrieveFromPath() throws {
        let largeImage = Data(repeating: 0xAB, count: 200_000)
        let result = try service.store(imageData: largeImage)

        let retrieved = try service.retrieve(path: result.path!)
        #expect(retrieved == largeImage)
    }

    @Test("Delete image file from filesystem")
    func deleteImageFile() throws {
        let largeImage = Data(repeating: 0xCD, count: 200_000)
        let result = try service.store(imageData: largeImage)
        let path = result.path!

        try service.deleteFile(at: path)
        #expect(!FileManager.default.fileExists(atPath: path))
    }

    @Test("SHA-256 hash computation is consistent")
    func hashConsistency() {
        let data = Data("test image data".utf8)
        let hash1 = ImageStorageService.sha256Hash(of: data)
        let hash2 = ImageStorageService.sha256Hash(of: data)

        #expect(hash1 == hash2)
        #expect(!hash1.isEmpty)
    }

    @Test("Different data produces different hashes")
    func hashUniqueness() {
        let data1 = Data("image A".utf8)
        let data2 = Data("image B".utf8)

        #expect(ImageStorageService.sha256Hash(of: data1) != ImageStorageService.sha256Hash(of: data2))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: Cmd+U in Xcode (or Product → Test)
Expected: Compilation error — `ImageStorageService` does not exist yet.

- [ ] **Step 3: Implement ImageStorageService**

Create `Kopi/Services/ImageStorageService.swift`:

```swift
import Foundation
import CryptoKit

struct ImageStoreResult {
    let blob: Data?
    let path: String?
}

final class ImageStorageService {
    private static let blobThreshold = 128 * 1024 // 128KB
    private let imagesDirectory: URL

    init(imagesDirectory: URL? = nil) {
        if let dir = imagesDirectory {
            self.imagesDirectory = dir
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            self.imagesDirectory = appSupport
                .appendingPathComponent("Kopi")
                .appendingPathComponent("Images")
        }
    }

    func store(imageData: Data) throws -> ImageStoreResult {
        if imageData.count < Self.blobThreshold {
            return ImageStoreResult(blob: imageData, path: nil)
        }

        try FileManager.default.createDirectory(
            at: imagesDirectory,
            withIntermediateDirectories: true
        )

        let filename = "\(UUID().uuidString).png"
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        try imageData.write(to: fileURL)

        return ImageStoreResult(blob: nil, path: fileURL.path)
    }

    func retrieve(path: String) throws -> Data {
        try Data(contentsOf: URL(fileURLWithPath: path))
    }

    func deleteFile(at path: String) throws {
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    func deleteOrphanedFiles(validPaths: Set<String>) throws {
        guard FileManager.default.fileExists(atPath: imagesDirectory.path) else {
            return
        }

        let contents = try FileManager.default.contentsOfDirectory(
            at: imagesDirectory,
            includingPropertiesForKeys: nil
        )

        for fileURL in contents {
            if !validPaths.contains(fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    static func sha256Hash(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: Cmd+U in Xcode
Expected: All 6 tests pass.

- [ ] **Step 5: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/Services/ImageStorageService.swift KopiTests/ImageStorageServiceTests.swift
git commit -m "feat: add ImageStorageService with hybrid blob/filesystem storage"
```

---

## Task 4: ClipboardStore

**Files:**
- Create: `Kopi/Services/ClipboardStore.swift`
- Create: `KopiTests/ClipboardStoreTests.swift`

- [ ] **Step 1: Write failing tests**

Create `KopiTests/ClipboardStoreTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import Kopi

@Suite("ClipboardStore Tests")
@MainActor
struct ClipboardStoreTests {
    let store: ClipboardStore
    let container: ModelContainer

    init() throws {
        let schema = Schema([ClipboardItem.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        store = ClipboardStore(modelContext: container.mainContext)
    }

    @Test("Save and fetch text item")
    func saveAndFetchText() throws {
        try store.saveText("Hello, world!")
        let items = try store.fetchAll()

        #expect(items.count == 1)
        #expect(items[0].contentType == .text)
        #expect(items[0].textContent == "Hello, world!")
    }

    @Test("Save and fetch image item as blob")
    func saveAndFetchImageBlob() throws {
        let data = Data(repeating: 0xFF, count: 1024)
        try store.saveImage(data: data, size: 1024, hash: "abc123")
        let items = try store.fetchAll()

        #expect(items.count == 1)
        #expect(items[0].contentType == .image)
        #expect(items[0].imageData == data)
        #expect(items[0].contentHash == "abc123")
    }

    @Test("Save image with filesystem path")
    func saveImageWithPath() throws {
        try store.saveImage(data: nil, path: "/tmp/test.png", size: 200_000, hash: "def456")
        let items = try store.fetchAll()

        #expect(items.count == 1)
        #expect(items[0].imagePath == "/tmp/test.png")
        #expect(items[0].imageData == nil)
    }

    @Test("Items sorted by createdAt descending")
    func sortOrder() throws {
        try store.saveText("First")
        try store.saveText("Second")
        try store.saveText("Third")
        let items = try store.fetchAll()

        #expect(items.count == 3)
        #expect(items[0].textContent == "Third")
        #expect(items[2].textContent == "First")
    }

    @Test("Search filters text items by content")
    func searchText() throws {
        try store.saveText("Hello, world!")
        try store.saveText("Goodbye, world!")
        try store.saveText("Swift is great")

        let results = try store.search(query: "world")
        #expect(results.count == 2)
    }

    @Test("Filter by content type")
    func filterByType() throws {
        try store.saveText("Some text")
        try store.saveImage(data: Data(repeating: 0, count: 10), size: 10, hash: "h1")

        let textOnly = try store.fetch(contentType: .text)
        let imageOnly = try store.fetch(contentType: .image)

        #expect(textOnly.count == 1)
        #expect(imageOnly.count == 1)
    }

    @Test("Filter pinned items only")
    func filterPinned() throws {
        try store.saveText("Unpinned")
        try store.saveText("Pinned")
        let items = try store.fetchAll()
        try store.togglePin(items[0]) // Pin "Pinned" (most recent, index 0)

        let pinned = try store.fetchPinned()
        #expect(pinned.count == 1)
        #expect(pinned[0].textContent == "Pinned")
    }

    @Test("Toggle pin on and off")
    func togglePin() throws {
        try store.saveText("Test")
        let item = try store.fetchAll()[0]

        #expect(item.isPinned == false)
        try store.togglePin(item)
        #expect(item.isPinned == true)
        try store.togglePin(item)
        #expect(item.isPinned == false)
    }

    @Test("Purge deletes old non-pinned items")
    func purgeOldItems() throws {
        try store.saveText("Old item")
        let items = try store.fetchAll()
        // Manually backdate the item
        items[0].createdAt = Calendar.current.date(
            byAdding: .day, value: -31, to: Date()
        )!

        try store.saveText("Recent item")
        try store.saveText("Pinned old")
        let allItems = try store.fetchAll()
        // Pin the "Pinned old" item and backdate it
        allItems[0].createdAt = Calendar.current.date(
            byAdding: .day, value: -31, to: Date()
        )!
        try store.togglePin(allItems[0])

        let deleted = try store.purgeOldItems(olderThanDays: 30)

        #expect(deleted.count == 1)
        #expect(deleted[0].textContent == "Old item")

        let remaining = try store.fetchAll()
        #expect(remaining.count == 2)
    }

    @Test("Delete specific item")
    func deleteItem() throws {
        try store.saveText("To delete")
        try store.saveText("To keep")
        let items = try store.fetchAll()

        try store.delete(items[1]) // Delete "To delete"
        let remaining = try store.fetchAll()

        #expect(remaining.count == 1)
        #expect(remaining[0].textContent == "To keep")
    }

    @Test("Find existing image by hash")
    func findByHash() throws {
        try store.saveImage(data: Data(repeating: 0, count: 10), size: 10, hash: "unique_hash")
        let found = try store.findByHash("unique_hash")
        #expect(found != nil)

        let notFound = try store.findByHash("nonexistent")
        #expect(notFound == nil)
    }

    @Test("Clear all history deletes everything")
    func clearAll() throws {
        try store.saveText("One")
        try store.saveText("Two")
        try store.saveText("Three")

        try store.clearAll()
        let items = try store.fetchAll()

        #expect(items.count == 0)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: Cmd+U in Xcode
Expected: Compilation error — `ClipboardStore` does not exist yet.

- [ ] **Step 3: Implement ClipboardStore**

Create `Kopi/Services/ClipboardStore.swift`:

```swift
import Foundation
import SwiftData

@MainActor
final class ClipboardStore {
    private let modelContext: ModelContext
    private let imageStorage: ImageStorageService

    init(
        modelContext: ModelContext,
        imageStorage: ImageStorageService = ImageStorageService()
    ) {
        self.modelContext = modelContext
        self.imageStorage = imageStorage
    }

    // MARK: - Save

    func saveText(_ text: String) throws {
        let item = ClipboardItem(contentType: .text, textContent: text)
        modelContext.insert(item)
        try modelContext.save()
    }

    func saveImage(data: Data?, path: String? = nil, size: Int, hash: String) throws {
        let item = ClipboardItem(
            contentType: .image,
            imageData: data,
            imagePath: path,
            imageSize: size,
            contentHash: hash
        )
        modelContext.insert(item)
        try modelContext.save()
    }

    // MARK: - Fetch

    func fetchAll() throws -> [ClipboardItem] {
        let descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(contentType: ContentType) throws -> [ClipboardItem] {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { $0.contentType == contentType },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchPinned() throws -> [ClipboardItem] {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { $0.isPinned == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func search(query: String) throws -> [ClipboardItem] {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate {
                $0.textContent?.localizedStandardContains(query) == true
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func findByHash(_ hash: String) throws -> ClipboardItem? {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { $0.contentHash == hash }
        )
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Update

    func togglePin(_ item: ClipboardItem) throws {
        item.isPinned.toggle()
        try modelContext.save()
    }

    func updateLastUsed(_ item: ClipboardItem) throws {
        item.lastUsedAt = Date()
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(_ item: ClipboardItem) throws {
        if let path = item.imagePath {
            try? imageStorage.deleteFile(at: path)
        }
        modelContext.delete(item)
        try modelContext.save()
    }

    func clearAll() throws {
        let items = try fetchAll()
        for item in items {
            if let path = item.imagePath {
                try? imageStorage.deleteFile(at: path)
            }
            modelContext.delete(item)
        }
        try modelContext.save()
    }

    /// Returns deleted items (so caller can clean up filesystem if needed)
    func purgeOldItems(olderThanDays days: Int = 30) throws -> [ClipboardItem] {
        let cutoff = Calendar.current.date(
            byAdding: .day, value: -days, to: Date()
        )!
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate {
                $0.isPinned == false && $0.createdAt < cutoff
            }
        )
        let oldItems = try modelContext.fetch(descriptor)
        var deleted: [ClipboardItem] = []

        for item in oldItems {
            if let path = item.imagePath {
                try? imageStorage.deleteFile(at: path)
            }
            deleted.append(item)
            modelContext.delete(item)
        }

        try modelContext.save()
        return deleted
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: Cmd+U in Xcode
Expected: All 12 tests pass.

- [ ] **Step 5: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/Services/ClipboardStore.swift KopiTests/ClipboardStoreTests.swift
git commit -m "feat: add ClipboardStore with CRUD, search, purge, and pinning"
```

---

## Task 5: ClipboardMonitor

**Files:**
- Create: `Kopi/Services/ClipboardMonitor.swift`

- [ ] **Step 1: Implement ClipboardMonitor**

Create `Kopi/Services/ClipboardMonitor.swift`:

```swift
import AppKit
import SwiftData

@MainActor
final class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let store: ClipboardStore
    private let imageStorage: ImageStorageService
    var isWritingToPasteboard = false

    init(store: ClipboardStore, imageStorage: ImageStorageService = ImageStorageService()) {
        self.store = store
        self.imageStorage = imageStorage
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkForChanges()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Skip if we wrote to the pasteboard ourselves (paste-from-history)
        if isWritingToPasteboard {
            isWritingToPasteboard = false
            return
        }

        do {
            try processClipboardContent(pasteboard)
        } catch {
            print("Kopi: Failed to process clipboard: \(error)")
        }
    }

    private func processClipboardContent(_ pasteboard: NSPasteboard) throws {
        // Check for image first (some apps put both image and text)
        if let imageData = extractImageData(from: pasteboard) {
            try saveImage(imageData)
            return
        }

        // Check for text
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            try store.saveText(text)
        }
    }

    private func extractImageData(from pasteboard: NSPasteboard) -> Data? {
        let imageTypes: [NSPasteboard.PasteboardType] = [.tiff, .png]
        for type in imageTypes {
            if let data = pasteboard.data(forType: type) {
                return data
            }
        }
        return nil
    }

    private func saveImage(_ imageData: Data) throws {
        // Deduplication: check if this image already exists
        let hash = ImageStorageService.sha256Hash(of: imageData)
        if let existing = try store.findByHash(hash) {
            try store.updateLastUsed(existing)
            return
        }

        // Store via ImageStorageService (handles blob vs filesystem)
        let result = try imageStorage.store(imageData: imageData)
        try store.saveImage(
            data: result.blob,
            path: result.path,
            size: imageData.count,
            hash: hash
        )
    }
}
```

- [ ] **Step 2: Build and verify**

Run: Cmd+B in Xcode
Expected: Build succeeds. ClipboardMonitor compiles cleanly.

- [ ] **Step 3: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/Services/ClipboardMonitor.swift
git commit -m "feat: add ClipboardMonitor with polling, dedup, and self-capture prevention"
```

---

## Task 6: PasteService

**Files:**
- Create: `Kopi/Services/PasteService.swift`

- [ ] **Step 1: Implement PasteService**

Create `Kopi/Services/PasteService.swift`:

```swift
import AppKit

@MainActor
final class PasteService {
    private let monitor: ClipboardMonitor
    private let imageStorage: ImageStorageService

    init(monitor: ClipboardMonitor, imageStorage: ImageStorageService = ImageStorageService()) {
        self.monitor = monitor
        self.imageStorage = imageStorage
    }

    func paste(_ item: ClipboardItem) {
        monitor.isWritingToPasteboard = true
        writeToPasteboard(item)
        simulateCmdV()
    }

    private func writeToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.contentType {
        case .text:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let data = resolveImageData(item) {
                pasteboard.setData(data, forType: .tiff)
            }
        }
    }

    private func resolveImageData(_ item: ClipboardItem) -> Data? {
        if let blob = item.imageData {
            return blob
        }
        if let path = item.imagePath {
            return try? imageStorage.retrieve(path: path)
        }
        return nil
    }

    private func simulateCmdV() {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)  // 0x09 = 'v'
        keyDown?.flags = .maskCommand

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
```

- [ ] **Step 2: Build and verify**

Run: Cmd+B in Xcode
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/Services/PasteService.swift
git commit -m "feat: add PasteService with pasteboard write and CGEvent Cmd+V simulation"
```

---

## Task 7: StatusItemManager + FloatingPanel

**Files:**
- Create: `Kopi/MenuBar/StatusItemManager.swift`
- Create: `Kopi/MenuBar/FloatingPanel.swift`

- [ ] **Step 1: Create FloatingPanel**

Create `Kopi/MenuBar/FloatingPanel.swift`:

```swift
import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 480),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false

        self.contentView = contentView
    }

    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        close()
    }

    func show(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonFrame = buttonWindow.frame

        let panelWidth = frame.width
        let panelHeight = frame.height

        let x = buttonFrame.midX - (panelWidth / 2)
        let y = buttonFrame.minY - panelHeight - 4

        setFrameOrigin(NSPoint(x: x, y: y))
        makeKeyAndOrderFront(nil)
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if isVisible {
            close()
        } else {
            show(relativeTo: button)
        }
    }
}
```

- [ ] **Step 2: Create StatusItemManager**

Create `Kopi/MenuBar/StatusItemManager.swift`:

```swift
import AppKit
import SwiftUI
import SwiftData

@MainActor
final class StatusItemManager {
    private var statusItem: NSStatusItem?
    private var panel: FloatingPanel?
    private let modelContainer: ModelContainer

    var onOpenHistory: (() -> Void)?
    var onOpenSettings: (() -> Void)?

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func setup(
        store: ClipboardStore,
        pasteService: PasteService
    ) {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "clipboard",
                accessibilityDescription: "Kopi Clipboard Manager"
            )
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let panelContent = NSHostingView(
            rootView: QuickPanelView(store: store, pasteService: pasteService)
                .modelContainer(modelContainer)
        )
        panel = FloatingPanel(contentView: panelContent)
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    func togglePanel() {
        guard let button = statusItem?.button else { return }
        panel?.toggle(relativeTo: button)
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(
                title: "Open History",
                action: #selector(openHistory),
                keyEquivalent: ""
            )
        )
        menu.addItem(
            NSMenuItem(
                title: "Settings...",
                action: #selector(openSettings),
                keyEquivalent: ","
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit Kopi",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        for item in menu.items {
            item.target = self
        }
        // Fix: Quit should target NSApp
        menu.items.last?.target = NSApp

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil // Reset so left-click works next time
    }

    @objc private func openHistory() {
        onOpenHistory?()
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }
}
```

- [ ] **Step 3: Build and verify**

Run: Cmd+B in Xcode
Expected: Build may fail because `QuickPanelView` doesn't exist yet. That's expected — it will be created in Task 8.

Create a temporary placeholder to unblock the build. Add to `Kopi/Views/QuickPanelView.swift`:

```swift
import SwiftUI

struct QuickPanelView: View {
    let store: ClipboardStore
    let pasteService: PasteService

    var body: some View {
        Text("Quick Panel — Coming Soon")
            .frame(width: 340, height: 480)
    }
}
```

Run: Cmd+B in Xcode
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/MenuBar/FloatingPanel.swift Kopi/MenuBar/StatusItemManager.swift Kopi/Views/QuickPanelView.swift
git commit -m "feat: add StatusItemManager, FloatingPanel, and QuickPanelView placeholder"
```

---

## Task 8: QuickPanelView

**Files:**
- Modify: `Kopi/Views/QuickPanelView.swift`
- Create: `Kopi/Views/ClipboardItemRow.swift`
- Create: `Kopi/Views/FilterChipsView.swift`

- [ ] **Step 1: Create FilterChipsView**

Create `Kopi/Views/FilterChipsView.swift`:

```swift
import SwiftUI

enum ClipboardFilter: String, CaseIterable {
    case all = "All"
    case text = "Text"
    case images = "Images"
    case pinned = "Pinned"
}

struct FilterChipsView: View {
    @Binding var selectedFilter: ClipboardFilter

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ClipboardFilter.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter == .pinned ? "📌 \(filter.rawValue)" : filter.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            selectedFilter == filter
                                ? Color.accentColor
                                : Color.secondary.opacity(0.2)
                        )
                        .foregroundStyle(
                            selectedFilter == filter ? .white : .secondary
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}
```

- [ ] **Step 2: Create ClipboardItemRow**

Create `Kopi/Views/ClipboardItemRow.swift`:

```swift
import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let imageStorage: ImageStorageService

    var body: some View {
        HStack(spacing: 8) {
            if item.isPinned {
                Text("📌")
                    .font(.caption2)
            }

            if item.contentType == .image {
                imagePreview
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            VStack(alignment: .leading, spacing: 2) {
                contentPreview
                    .font(.system(size: 12))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(item.createdAt.formatted(.relative(presentation: .named)))
                    Text("•")
                    Text(item.contentType == .text ? "Text" : "Image")
                    if let size = item.imageSize {
                        Text("•")
                        Text(ByteCountFormatter.string(
                            fromByteCount: Int64(size),
                            countStyle: .file
                        ))
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.contentType {
        case .text:
            Text(item.textContent ?? "")
                .foregroundStyle(.primary)
        case .image:
            Text(imageName)
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let data = resolveImageData(), let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
        }
    }

    private var imageName: String {
        if let path = item.imagePath {
            return URL(fileURLWithPath: path).lastPathComponent
        }
        return "Image"
    }

    private func resolveImageData() -> Data? {
        if let blob = item.imageData {
            return blob
        }
        if let path = item.imagePath {
            return try? imageStorage.retrieve(path: path)
        }
        return nil
    }
}
```

- [ ] **Step 3: Implement full QuickPanelView**

Replace `Kopi/Views/QuickPanelView.swift`:

```swift
import SwiftUI
import SwiftData

struct QuickPanelView: View {
    let store: ClipboardStore
    let pasteService: PasteService
    let imageStorage = ImageStorageService()

    @Query(sort: \ClipboardItem.createdAt, order: .reverse)
    private var allItems: [ClipboardItem]

    @State private var searchText = ""
    @State private var selectedFilter: ClipboardFilter = .all
    @State private var selectedIndex: Int?

    private var filteredItems: [ClipboardItem] {
        var items = allItems

        switch selectedFilter {
        case .all:
            break
        case .text:
            items = items.filter { $0.contentType == .text }
        case .images:
            items = items.filter { $0.contentType == .image }
        case .pinned:
            items = items.filter { $0.isPinned }
        }

        if !searchText.isEmpty {
            items = items.filter {
                $0.textContent?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search clipboard history...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Filter chips
            FilterChipsView(selectedFilter: $selectedFilter)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            Divider()

            // Items list
            if filteredItems.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "clipboard")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                    Text("No items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    List(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemRow(item: item, imageStorage: imageStorage)
                            .id(item.id)
                            .listRowInsets(EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6))
                            .listRowBackground(
                                selectedIndex == index
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.clear
                            )
                            .onTapGesture {
                                pasteService.paste(item)
                                try? store.updateLastUsed(item)
                            }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }

            Divider()

            // Keyboard hints
            HStack {
                Text("↑↓ Navigate")
                Spacer()
                Text("⏎ Paste")
                Spacer()
                Text("⌫ Delete")
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 340, height: 480)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.return) {
            if let index = selectedIndex, index < filteredItems.count {
                let item = filteredItems[index]
                pasteService.paste(item)
                try? store.updateLastUsed(item)
            }
            return .handled
        }
        .onKeyPress(.delete) {
            if let index = selectedIndex, index < filteredItems.count {
                try? store.delete(filteredItems[index])
                selectedIndex = nil
            }
            return .handled
        }
    }

    private func moveSelection(by offset: Int) {
        let count = filteredItems.count
        guard count > 0 else { return }

        if let current = selectedIndex {
            selectedIndex = max(0, min(count - 1, current + offset))
        } else {
            selectedIndex = offset > 0 ? 0 : count - 1
        }
    }
}
```

- [ ] **Step 4: Build and verify**

Run: Cmd+B in Xcode
Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/Views/QuickPanelView.swift Kopi/Views/ClipboardItemRow.swift Kopi/Views/FilterChipsView.swift
git commit -m "feat: add QuickPanelView with search, filters, keyboard nav, and item rows"
```

---

## Task 9: HotkeyManager

**Files:**
- Create: `Kopi/Utilities/HotkeyManager.swift`

- [ ] **Step 1: Implement HotkeyManager**

Create `Kopi/Utilities/HotkeyManager.swift`:

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleQuickPanel = Self(
        "toggleQuickPanel",
        default: .init(.space, modifiers: .control)
    )
}

@MainActor
final class HotkeyManager {
    private var onToggle: (() -> Void)?

    func setup(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle

        KeyboardShortcuts.onKeyUp(for: .toggleQuickPanel) { [weak self] in
            Task { @MainActor in
                self?.onToggle?()
            }
        }
    }
}
```

- [ ] **Step 2: Build and verify**

Run: Cmd+B in Xcode
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/Utilities/HotkeyManager.swift
git commit -m "feat: add HotkeyManager with Ctrl+Space global shortcut"
```

---

## Task 10: AppDelegate

**Files:**
- Create: `Kopi/AppDelegate.swift`
- Modify: `Kopi/KopiApp.swift`

- [ ] **Step 1: Create AppDelegate**

Create `Kopi/AppDelegate.swift`:

```swift
import AppKit
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemManager: StatusItemManager?
    private var clipboardMonitor: ClipboardMonitor?
    private var hotkeyManager: HotkeyManager?
    private var store: ClipboardStore?

    var modelContainer: ModelContainer?
    var onOpenHistory: (() -> Void)?
    var onOpenSettings: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let container = modelContainer else {
            fatalError("ModelContainer not set before app launch")
        }

        let context = container.mainContext
        let imageStorage = ImageStorageService()
        let store = ClipboardStore(modelContext: context, imageStorage: imageStorage)
        self.store = store

        // Purge old items on launch
        let _ = try? store.purgeOldItems()

        // Clipboard monitor
        let monitor = ClipboardMonitor(store: store, imageStorage: imageStorage)
        monitor.start()
        clipboardMonitor = monitor

        // Paste service
        let pasteService = PasteService(monitor: monitor, imageStorage: imageStorage)

        // Menu bar
        let statusManager = StatusItemManager(modelContainer: container)
        statusManager.setup(store: store, pasteService: pasteService)
        statusManager.onOpenHistory = { [weak self] in
            self?.onOpenHistory?()
        }
        statusManager.onOpenSettings = { [weak self] in
            self?.onOpenSettings?()
        }
        statusItemManager = statusManager

        // Global hotkey
        let hotkey = HotkeyManager()
        hotkey.setup { [weak statusManager] in
            statusManager?.togglePanel()
        }
        hotkeyManager = hotkey
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stop()
    }
}
```

- [ ] **Step 2: Update KopiApp to use AppDelegate**

Replace `Kopi/KopiApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct KopiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([ClipboardItem.self])
            let config = ModelConfiguration("KopiStore", schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .modelContainer(modelContainer)
        }

        Window("Clipboard History", id: "history") {
            HistoryView()
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 700, height: 500)
    }
}
```

Note: This will fail to build because `SettingsView` and `HistoryView` don't exist yet. Create temporary placeholders.

Create `Kopi/Views/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Text("Settings — Coming Soon")
            .frame(width: 400, height: 300)
    }
}
```

Create `Kopi/Views/HistoryView.swift`:

```swift
import SwiftUI

struct HistoryView: View {
    var body: some View {
        Text("History — Coming Soon")
            .frame(width: 700, height: 500)
    }
}
```

- [ ] **Step 3: Wire ModelContainer to AppDelegate**

The AppDelegate needs the ModelContainer before `applicationDidFinishLaunching`. Update `KopiApp.init()` to pass it:

Replace the `init()` in `KopiApp.swift`:

```swift
    init() {
        do {
            let schema = Schema([ClipboardItem.self])
            let config = ModelConfiguration("KopiStore", schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Pass container to AppDelegate (will be set before applicationDidFinishLaunching)
        appDelegate.modelContainer = modelContainer
    }
```

Note: `@NSApplicationDelegateAdaptor` creates the delegate before `init()` runs, so `appDelegate` is accessible in `init()`.

- [ ] **Step 4: Build and run**

Run: Cmd+R in Xcode
Expected: App launches with a menu bar icon (clipboard). Left-clicking toggles the quick panel. Right-clicking shows context menu. Ctrl+Space toggles the panel. The clipboard monitor is running — copy some text and check the panel shows it.

- [ ] **Step 5: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/AppDelegate.swift Kopi/KopiApp.swift Kopi/Views/SettingsView.swift Kopi/Views/HistoryView.swift
git commit -m "feat: add AppDelegate wiring all services, menu bar, and hotkey"
```

---

## Task 11: History Window

**Files:**
- Modify: `Kopi/Views/HistoryView.swift`
- Create: `Kopi/Views/HistoryDetailView.swift`

- [ ] **Step 1: Create HistoryDetailView**

Create `Kopi/Views/HistoryDetailView.swift`:

```swift
import SwiftUI

struct HistoryDetailView: View {
    let item: ClipboardItem
    let imageStorage: ImageStorageService
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(item.contentType == .text ? "Text" : "Image") — Copied \(item.createdAt.formatted(date: .omitted, time: .shortened))")
                        .font(.headline)
                    Text(metadataString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        onTogglePin()
                    } label: {
                        Text(item.isPinned ? "📌 Pinned" : "Pin")
                    }

                    Button("Copy") {
                        onCopy()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                }
            }
            .padding()

            Divider()

            // Preview
            ScrollView {
                contentPreview
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var metadataString: String {
        var parts: [String] = []
        if let text = item.textContent {
            parts.append("\(text.count) characters")
        }
        if let size = item.imageSize {
            parts.append(ByteCountFormatter.string(
                fromByteCount: Int64(size),
                countStyle: .file
            ))
        }
        return parts.joined(separator: " • ")
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.contentType {
        case .text:
            Text(item.textContent ?? "")
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

        case .image:
            if let data = resolveImageData(), let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ContentUnavailableView(
                    "Image not available",
                    systemImage: "photo",
                    description: Text("The image file may have been deleted.")
                )
            }
        }
    }

    private func resolveImageData() -> Data? {
        if let blob = item.imageData {
            return blob
        }
        if let path = item.imagePath {
            return try? imageStorage.retrieve(path: path)
        }
        return nil
    }
}
```

- [ ] **Step 2: Implement full HistoryView**

Replace `Kopi/Views/HistoryView.swift`:

```swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardItem.createdAt, order: .reverse)
    private var allItems: [ClipboardItem]

    @State private var searchText = ""
    @State private var selectedFilter: ClipboardFilter = .all
    @State private var selectedItem: ClipboardItem?

    private let imageStorage = ImageStorageService()

    private var filteredItems: [ClipboardItem] {
        var items = allItems

        switch selectedFilter {
        case .all: break
        case .text: items = items.filter { $0.contentType == .text }
        case .images: items = items.filter { $0.contentType == .image }
        case .pinned: items = items.filter { $0.isPinned }
        }

        if !searchText.isEmpty {
            items = items.filter {
                $0.textContent?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return items
    }

    private var groupedItems: [(String, [ClipboardItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredItems) { item -> String in
            if calendar.isDateInToday(item.createdAt) {
                return "Today"
            } else if calendar.isDateInYesterday(item.createdAt) {
                return "Yesterday"
            } else {
                return item.createdAt.formatted(date: .abbreviated, time: .omitted)
            }
        }

        let order = ["Today", "Yesterday"]
        return grouped.sorted { a, b in
            let aIndex = order.firstIndex(of: a.key) ?? Int.max
            let bIndex = order.firstIndex(of: b.key) ?? Int.max
            if aIndex != bIndex { return aIndex < bIndex }
            return (a.value.first?.createdAt ?? .distantPast) >
                   (b.value.first?.createdAt ?? .distantPast)
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)

                Divider()

                FilterChipsView(selectedFilter: $selectedFilter)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)

                Divider()

                List(selection: $selectedItem) {
                    ForEach(groupedItems, id: \.0) { group, items in
                        Section(group) {
                            ForEach(items) { item in
                                ClipboardItemRow(item: item, imageStorage: imageStorage)
                                    .tag(item)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 350)
        } detail: {
            if let item = selectedItem {
                HistoryDetailView(
                    item: item,
                    imageStorage: imageStorage,
                    onCopy: {
                        copyToPasteboard(item)
                    },
                    onTogglePin: {
                        item.isPinned.toggle()
                        try? modelContext.save()
                    },
                    onDelete: {
                        if let path = item.imagePath {
                            try? imageStorage.deleteFile(at: path)
                        }
                        selectedItem = nil
                        modelContext.delete(item)
                        try? modelContext.save()
                    }
                )
            } else {
                ContentUnavailableView(
                    "Select an item",
                    systemImage: "clipboard",
                    description: Text("Choose a clipboard item to see its full content.")
                )
            }
        }
    }

    private func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.contentType {
        case .text:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let data = item.imageData {
                pasteboard.setData(data, forType: .tiff)
            } else if let path = item.imagePath,
                      let data = try? imageStorage.retrieve(path: path) {
                pasteboard.setData(data, forType: .tiff)
            }
        }
    }
}
```

- [ ] **Step 3: Build and run**

Run: Cmd+R in Xcode
Expected: Right-click menu bar icon → "Open History" opens the history window with NavigationSplitView. Items grouped by date on the left, detail preview on the right.

- [ ] **Step 4: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/Views/HistoryView.swift Kopi/Views/HistoryDetailView.swift
git commit -m "feat: add HistoryView with NavigationSplitView, date grouping, and detail pane"
```

---

## Task 12: Settings Window

**Files:**
- Modify: `Kopi/Views/SettingsView.swift`

- [ ] **Step 1: Implement full SettingsView**

Replace `Kopi/Views/SettingsView.swift`:

```swift
import SwiftUI
import SwiftData
import KeyboardShortcuts
import LaunchAtLogin

struct SettingsView: View {
    @AppStorage("purgeDays") private var purgeDays: Int = 30
    @Environment(\.modelContext) private var modelContext
    @State private var showClearConfirmation = false

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            shortcutsTab
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            storageTab
                .tabItem {
                    Label("Storage", systemImage: "internaldrive")
                }
        }
        .frame(width: 420, height: 260)
    }

    private var generalTab: some View {
        Form {
            LaunchAtLogin.Toggle("Launch at login")

            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var shortcutsTab: some View {
        Form {
            Section("Global Shortcut") {
                LabeledContent("Toggle Quick Panel") {
                    KeyboardShortcuts.Recorder(for: .toggleQuickPanel)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var storageTab: some View {
        Form {
            Section("Auto-Purge") {
                Picker("Delete items older than", selection: $purgeDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                    Text("60 days").tag(60)
                    Text("90 days").tag(90)
                }
            }

            Section("Danger Zone") {
                Button("Clear All History", role: .destructive) {
                    showClearConfirmation = true
                }
                .confirmationDialog(
                    "Clear all clipboard history?",
                    isPresented: $showClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear All", role: .destructive) {
                        clearAllHistory()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will delete all clipboard history including pinned items. This cannot be undone.")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func clearAllHistory() {
        let imageStorage = ImageStorageService()
        let store = ClipboardStore(modelContext: modelContext, imageStorage: imageStorage)
        try? store.clearAll()
    }
}
```

- [ ] **Step 2: Build and run**

Run: Cmd+R in Xcode
Expected: Right-click menu bar icon → "Settings..." opens settings with three tabs: General (launch at login), Shortcuts (recorder for Ctrl+Space), Storage (purge days, clear all).

- [ ] **Step 3: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/Views/SettingsView.swift
git commit -m "feat: add SettingsView with hotkey customization, purge, and launch-at-login"
```

---

## Task 13: Wire History + Settings Windows from Menu Bar

**Files:**
- Modify: `Kopi/AppDelegate.swift`
- Modify: `Kopi/KopiApp.swift`

- [ ] **Step 1: Update AppDelegate with direct window opening**

The `openWindow` environment is only available inside SwiftUI views, not in `init()`. Instead, use `NSApp` directly to manage windows from AppDelegate.

Update `Kopi/AppDelegate.swift` — replace `onOpenHistory` and `onOpenSettings` closures in `applicationDidFinishLaunching`:

```swift
        statusManager.onOpenHistory = {
            // Activate app and open/focus the history window
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "history" }) {
                window.makeKeyAndOrderFront(nil)
            } else {
                // Trigger SwiftUI to open the window via environment action
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenHistoryWindow"),
                    object: nil
                )
            }
        }
        statusManager.onOpenSettings = {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
```

- [ ] **Step 2: Update KopiApp to listen for history window notification**

Replace `Kopi/KopiApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct KopiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([ClipboardItem.self])
            let config = ModelConfiguration("KopiStore", schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        appDelegate.modelContainer = modelContainer
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .modelContainer(modelContainer)
        }

        Window("Clipboard History", id: "history") {
            HistoryView()
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 700, height: 500)
        .handlesExternalEvents(matching: ["history"])
    }
}
```

Note: The `handlesExternalEvents` modifier allows the window to be opened via deep links. The notification-based approach in AppDelegate is a fallback — in practice, most users will find the window already exists (SwiftUI creates it on first reference) and just needs `makeKeyAndOrderFront`.

- [ ] **Step 3: Update AppDelegate to read purgeDays setting**

In `Kopi/AppDelegate.swift`, update the purge call in `applicationDidFinishLaunching`:

```swift
        // Purge old items on launch (read user's preference)
        let purgeDays = UserDefaults.standard.integer(forKey: "purgeDays")
        let _ = try? store.purgeOldItems(olderThanDays: purgeDays > 0 ? purgeDays : 30)
```

- [ ] **Step 4: Build and run full integration test**

Run: Cmd+R in Xcode

Test manually:
1. App launches with clipboard icon in menu bar
2. Copy some text in any app → appears in quick panel
3. Copy an image (e.g., screenshot with Cmd+Shift+4) → appears in quick panel with thumbnail
4. Press Ctrl+Space → panel toggles
5. Click an item → pastes into active app
6. Right-click menu bar icon → "Open History" → history window opens
7. Right-click → "Settings..." → settings window opens
8. In settings, change hotkey → new shortcut works
9. Pin an item → stays pinned across app restart

- [ ] **Step 5: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/KopiApp.swift Kopi/AppDelegate.swift
git commit -m "feat: wire history and settings windows to menu bar, add purge setting"
```

---

## Task 14: Accessibility Permission Prompt

**Files:**
- Modify: `Kopi/AppDelegate.swift`

- [ ] **Step 1: Add accessibility permission check**

Add to `AppDelegate.swift`, at the end of `applicationDidFinishLaunching`:

```swift
        // Check accessibility permission (needed for CGEvent paste simulation)
        checkAccessibilityPermission()
```

Add the method to `AppDelegate`:

```swift
    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            print("Kopi: Accessibility permission not granted. Paste simulation will not work until granted.")
        }
    }
```

- [ ] **Step 2: Build and run**

Run: Cmd+R in Xcode
Expected: On first launch, macOS shows accessibility permission dialog. After granting, paste simulation (Cmd+V) works.

- [ ] **Step 3: Commit**

```bash
cd ~/Projects/Personal/Repositories/kopi-app
git add Kopi/AppDelegate.swift
git commit -m "feat: add accessibility permission prompt on first launch"
```

---

## Verification Checklist

After completing all tasks, verify end-to-end:

- [ ] Copy text in Safari → appears in Kopi quick panel
- [ ] Copy text in Terminal → appears in Kopi quick panel
- [ ] Take a screenshot (Cmd+Shift+4) → image appears with thumbnail
- [ ] Copy a large image (>128KB) → check `~/Library/Application Support/Kopi/Images/` has the file
- [ ] Copy the same image twice → only one entry (dedup works)
- [ ] Click an item in quick panel → pastes into active app
- [ ] Press Ctrl+Space → panel toggles open/closed
- [ ] Pin an item → survives app restart
- [ ] Search for text → filters results
- [ ] Filter by Images → shows only images
- [ ] Open History window → NavigationSplitView with date groups
- [ ] Detail pane shows full preview for text and images
- [ ] Settings: change hotkey → new shortcut works
- [ ] Settings: toggle launch at login
- [ ] Settings: clear all history → everything deleted
- [ ] Run tests: Cmd+U → all pass
