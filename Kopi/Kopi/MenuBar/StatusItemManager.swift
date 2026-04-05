import AppKit
import SwiftUI
import SwiftData

@MainActor
final class StatusItemManager: NSObject {
    private var statusItem: NSStatusItem?
    private var panel: FloatingPanel?
    private let modelContainer: ModelContainer
    private let menuActionDispatcher: StatusMenuActionDispatcher
    private var eventMonitor: Any?

    var onOpenHistory: (() -> Void)?
    var onOpenSettings: (() -> Void)?

    init(
        modelContainer: ModelContainer,
        menuActionDispatcher: StatusMenuActionDispatcher = StatusMenuActionDispatcher()
    ) {
        self.modelContainer = modelContainer
        self.menuActionDispatcher = menuActionDispatcher
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
            rootView: QuickPanelView(
                store: store,
                pasteService: pasteService,
                onPasteCompleted: { [weak self] in
                    self?.panel?.close()
                }
            )
                .modelContainer(modelContainer)
        )
        panel = FloatingPanel(contentView: panelContent)

        // Monitor key events when our panel is key window
        setupKeyEventMonitor()
    }

    private func setupKeyEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  let panel = self.panel,
                  panel.isVisible else {
                return event
            }

            // Don't intercept if a text field is being edited
            if let responder = panel.firstResponder, responder is NSTextView {
                return event
            }

            switch event.keyCode {
            case 51: // Backspace
                NotificationCenter.default.post(name: .panelDeleteItem, object: nil)
                return nil // consume the event
            case 36: // Return
                NotificationCenter.default.post(name: .panelPasteItem, object: nil)
                return nil
            default:
                return event
            }
        }
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
        menu.items.last?.target = NSApp

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openHistory() {
        menuActionDispatcher.dispatch { [weak self] in
            self?.onOpenHistory?()
        }
    }

    @objc private func openSettings() {
        menuActionDispatcher.dispatch { [weak self] in
            self?.onOpenSettings?()
        }
    }
}
