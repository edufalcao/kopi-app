import Foundation

@Observable
final class QuickPanelSelection {
    var selectedIndex: Int?

    func moveSelection(by offset: Int, itemCount: Int) {
        guard itemCount > 0 else { return }

        if let current = selectedIndex {
            selectedIndex = max(0, min(itemCount - 1, current + offset))
        } else {
            selectedIndex = offset > 0 ? 0 : itemCount - 1
        }
    }

    func hoverItem(at index: Int) {
        selectedIndex = index
    }
}
