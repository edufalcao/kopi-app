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
        // SwiftData #Predicate with enum comparisons can crash on macOS 14/15;
        // fetch all and filter in memory instead.
        let all = try fetchAll()
        return all.filter { $0.contentType == contentType }
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
