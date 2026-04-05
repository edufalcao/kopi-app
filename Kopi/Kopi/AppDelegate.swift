import AppKit
import SwiftUI
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemManager: StatusItemManager?
    private var clipboardMonitor: ClipboardMonitor?
    private var hotkeyManager: HotkeyManager?
    private var store: ClipboardStore?
    private var historyWindow: NSWindow?

    var modelContainer: ModelContainer?
    private var hasFinishedFirstActivation = false

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
            self?.showHistoryWindow()
        }
        statusManager.onOpenSettings = { [weak self] in
            self?.showSettingsWindow()
        }
        statusItemManager = statusManager

        // Global hotkey
        let hotkey = HotkeyManager()
        hotkey.setup { [weak statusManager] in
            statusManager?.togglePanel()
        }
        hotkeyManager = hotkey

        // Check accessibility permission (needed for CGEvent paste simulation)
        checkAccessibilityPermission()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Hide any windows that SwiftUI auto-opened on launch
        // (Settings window opens by default when there's no WindowGroup)
        // Use orderOut instead of close so the window can be reopened later
        if !hasFinishedFirstActivation {
            hasFinishedFirstActivation = true
            for window in NSApp.windows {
                window.orderOut(nil)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stop()
    }

    private func showHistoryWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if let window = historyWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }

        guard let container = modelContainer else { return }
        let hostingView = NSHostingView(
            rootView: HistoryView()
                .modelContainer(container)
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Clipboard History"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        historyWindow = window
    }

    private func showSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            return
        }

        for window in NSApp.windows where window.title.contains("Settings") {
            window.makeKeyAndOrderFront(nil)
            return
        }
    }

    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            print("Kopi: Accessibility permission not granted. Paste simulation will not work until granted.")
        }
    }
}
