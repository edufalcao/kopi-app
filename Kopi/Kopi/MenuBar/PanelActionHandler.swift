import Foundation

/// Notification names for bridging NSPanel key events to SwiftUI views.
extension Notification.Name {
    static let panelDeleteItem = Notification.Name("panelDeleteItem")
    static let panelPasteItem = Notification.Name("panelPasteItem")
}
