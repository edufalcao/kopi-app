import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    var onDeleteKey: (() -> Void)?
    var onReturnKey: (() -> Void)?

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

    override func keyDown(with event: NSEvent) {
        // If a text field is being edited, let it handle the event
        if let responder = firstResponder, responder is NSTextView {
            // But intercept Return even in text field (to paste selected item)
            if event.keyCode == 36 {
                onReturnKey?()
                return
            }
            super.keyDown(with: event)
            return
        }

        switch event.keyCode {
        case 51: // Backspace
            onDeleteKey?()
        case 36: // Return
            onReturnKey?()
        default:
            super.keyDown(with: event)
        }
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
