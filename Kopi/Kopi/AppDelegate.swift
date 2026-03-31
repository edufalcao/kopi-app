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

        // Purge old items on launch (read user's preference)
        let purgeDays = UserDefaults.standard.integer(forKey: "purgeDays")
        let _ = try? store.purgeOldItems(olderThanDays: purgeDays > 0 ? purgeDays : 30)

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
