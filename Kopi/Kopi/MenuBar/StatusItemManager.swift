import AppKit
import SwiftUI
import SwiftData

@MainActor
final class StatusItemManager: NSObject {
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

        let actionHandler = PanelActionHandler()
        let panelContent = NSHostingView(
            rootView: QuickPanelView(store: store, pasteService: pasteService, actionHandler: actionHandler)
                .modelContainer(modelContainer)
        )
        let floatingPanel = FloatingPanel(contentView: panelContent)

        // Wire panel key events → action handler → SwiftUI view
        floatingPanel.onDeleteKey = { [weak actionHandler] in
            actionHandler?.onDelete?()
        }
        floatingPanel.onReturnKey = { [weak actionHandler] in
            actionHandler?.onPaste?()
        }

        panel = floatingPanel
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
