import Testing
import Foundation
import SwiftData
@testable import Kopi

@Suite("ClipboardStore Tests", .serialized)
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
        items[0].createdAt = Calendar.current.date(
            byAdding: .day, value: -31, to: Date()
        )!

        try store.saveText("Recent item")
        try store.saveText("Pinned old")
        let allItems = try store.fetchAll()
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
