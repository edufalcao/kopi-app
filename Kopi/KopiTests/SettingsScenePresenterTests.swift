import AppKit
import Testing
@testable import Kopi

@Suite("SettingsScenePresenter Tests")
@MainActor
struct SettingsScenePresenterTests {
    @Test("Prefer the app menu settings callback when available")
    func prefersAppMenuSettingsCallback() {
        let menuItem = NSMenuItem(title: "Settings…", action: nil, keyEquivalent: ",")
        var actionInvocations = 0
        var selectors: [String] = []

        let presenter = SettingsScenePresenter(
            settingsMenuItem: { menuItem },
            performMenuItemAction: { item in
                #expect(item === menuItem)
                actionInvocations += 1
                return true
            },
            sendAction: { selector in
                selectors.append(NSStringFromSelector(selector))
                return false
            },
            windows: {
                Issue.record("settings windows should not be queried when the app menu callback succeeds")
                return []
            }
        )

        #expect(presenter.present())
        #expect(actionInvocations == 1)
        #expect(selectors.isEmpty)
    }

    @Test("Use the native settings scene action when available")
    func usesNativeSettingsSceneAction() {
        let window = TestSettingsSceneWindow(identifier: "com_apple_SwiftUI_Settings_window")
        var selectors: [String] = []

        let presenter = SettingsScenePresenter(
            settingsMenuItem: { nil },
            sendAction: { selector in
                selectors.append(NSStringFromSelector(selector))
                return NSStringFromSelector(selector) == "showSettingsWindow:"
            },
            windows: { [window] }
        )

        #expect(presenter.present())
        #expect(selectors == ["showSettingsWindow:"])
        #expect(window.didMakeKeyAndOrderFront)
    }

    @Test("Do not treat selector success as a real settings presentation without a settings window")
    func ignoresSelectorSuccessWithoutSettingsWindow() {
        var selectors: [String] = []

        let presenter = SettingsScenePresenter(
            settingsMenuItem: { nil },
            sendAction: { selector in
                selectors.append(NSStringFromSelector(selector))
                return NSStringFromSelector(selector) == "showSettingsWindow:"
            }
        )

        #expect(!presenter.present())
        #expect(selectors == ["showSettingsWindow:", "showPreferencesWindow:"])
    }

    @Test("Fallback to the legacy preferences action when needed")
    func fallsBackToLegacyPreferencesAction() {
        let window = TestSettingsSceneWindow(identifier: "com_apple_SwiftUI_Settings_window")
        var selectors: [String] = []

        let presenter = SettingsScenePresenter(
            settingsMenuItem: { nil },
            sendAction: { selector in
                selectors.append(NSStringFromSelector(selector))
                return NSStringFromSelector(selector) == "showPreferencesWindow:"
            },
            windows: {
                selectors.contains("showPreferencesWindow:") ? [window] : []
            }
        )

        #expect(presenter.present())
        #expect(selectors == ["showSettingsWindow:", "showPreferencesWindow:"])
        #expect(window.didMakeKeyAndOrderFront)
    }

    @Test("Reuse an existing settings window when scene actions are unavailable")
    func reusesExistingSettingsWindow() {
        let window = TestSettingsSceneWindow(identifier: "com_apple_SwiftUI_Settings_window")
        let presenter = SettingsScenePresenter(
            settingsMenuItem: { nil },
            sendAction: { _ in false },
            windows: { [window] }
        )

        #expect(presenter.present())
        #expect(window.didMakeKeyAndOrderFront)
    }

    @Test("Report failure when no native settings path is available")
    func reportsFailureWhenNoSettingsPathExists() {
        let presenter = SettingsScenePresenter(
            settingsMenuItem: { nil },
            sendAction: { _ in false },
            windows: { [] }
        )

        #expect(!presenter.present())
    }
}

private final class TestSettingsSceneWindow: NSWindow {
    private(set) var didMakeKeyAndOrderFront = false

    init(identifier: String) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        self.identifier = NSUserInterfaceItemIdentifier(identifier)
    }

    override func makeKeyAndOrderFront(_ sender: Any?) {
        didMakeKeyAndOrderFront = true
    }
}
