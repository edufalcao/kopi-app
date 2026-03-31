import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleQuickPanel = Self(
        "toggleQuickPanel",
        default: .init(.space, modifiers: .control)
    )
}

@MainActor
final class HotkeyManager {
    private var onToggle: (() -> Void)?

    func setup(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle

        KeyboardShortcuts.onKeyUp(for: .toggleQuickPanel) { [weak self] in
            Task { @MainActor in
                self?.onToggle?()
            }
        }
    }
}
