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
