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
        statusManager.onOpenHistory = {
            // Activate app and open/focus the history window
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "history" }) {
                window.makeKeyAndOrderFront(nil)
            } else {
                // The SwiftUI Window scene should create it automatically
                // Force the app to activate so SwiftUI processes the scene
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        statusManager.onOpenSettings = {
            NSApp.activate(ignoringOtherApps: true)
            // Find the Settings window (orderOut'd on first launch) and show it
            if let settingsWindow = NSApp.windows.first(where: {
                $0.frameAutosaveName.contains("Settings") ||
                $0.title.contains("Settings") ||
                String(describing: type(of: $0)).contains("Settings")
            }) {
                settingsWindow.makeKeyAndOrderFront(nil)
            }
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

    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            print("Kopi: Accessibility permission not granted. Paste simulation will not work until granted.")
        }
    }
}
