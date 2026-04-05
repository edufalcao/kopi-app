import AppKit

@MainActor
struct SettingsScenePresenter {
    var settingsMenuItem: () -> NSMenuItem? = {
        Self.defaultSettingsMenuItem()
    }
    var performMenuItemAction: (NSMenuItem) -> Bool = { item in
        guard let action = item.action else {
            return false
        }

        return NSApp.sendAction(action, to: item.target, from: item)
    }
    var sendAction: (Selector) -> Bool = { selector in
        NSApp.sendAction(selector, to: nil, from: nil)
    }
    var windows: () -> [NSWindow] = {
        NSApp.windows
    }

    @discardableResult
    func present() -> Bool {
        if let settingsMenuItem = settingsMenuItem(), performMenuItemAction(settingsMenuItem) {
            return true
        }

        if presentWindowUsingSelector(Selector(("showSettingsWindow:"))) {
            return true
        }

        if presentWindowUsingSelector(Selector(("showPreferencesWindow:"))) {
            return true
        }

        return focusExistingSettingsWindowIfNeeded()
    }

    private func presentWindowUsingSelector(_ selector: Selector) -> Bool {
        let _ = sendAction(selector)
        return focusExistingSettingsWindowIfNeeded()
    }

    private func focusExistingSettingsWindowIfNeeded() -> Bool {
        guard let window = windows().first(where: Self.isSettingsWindow) else {
            return false
        }

        window.makeKeyAndOrderFront(nil)
        return true
    }

    private static func defaultSettingsMenuItem() -> NSMenuItem? {
        guard let appMenu = NSApp.mainMenu?.item(at: 0)?.submenu else {
            return nil
        }

        return appMenu.items.first(where: {
            $0.keyEquivalent == "," || $0.title.localizedCaseInsensitiveContains("settings")
        })
    }

    private static func isSettingsWindow(_ window: NSWindow) -> Bool {
        let className = String(describing: type(of: window))
        let identifier = window.identifier?.rawValue ?? ""
        let autosaveName = window.frameAutosaveName

        return window.title.localizedCaseInsensitiveContains("settings") ||
            identifier.localizedCaseInsensitiveContains("settings_window") ||
            autosaveName.localizedCaseInsensitiveContains("settings_window") ||
            className.localizedCaseInsensitiveContains("settings")
    }
}
