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
