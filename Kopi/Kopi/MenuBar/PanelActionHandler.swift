import Foundation

/// Bridges key events from FloatingPanel (AppKit) to QuickPanelView (SwiftUI).
/// The panel sets action closures; the SwiftUI view provides implementations.
@MainActor
@Observable
final class PanelActionHandler {
    var onDelete: (() -> Void)?
    var onPaste: (() -> Void)?
}
