import Testing
@testable import Kopi

@Suite("QuickPanelSelection Tests")
struct QuickPanelSelectionTests {
    @Test("Hover sets selected index")
    func hoverSetsIndex() {
        let selection = QuickPanelSelection()
        #expect(selection.selectedIndex == nil)

        selection.hoverItem(at: 3)
        #expect(selection.selectedIndex == 3)
    }

    @Test("Hover updates selected index to new item")
    func hoverUpdatesIndex() {
        let selection = QuickPanelSelection()
        selection.hoverItem(at: 0)
        selection.hoverItem(at: 2)
        #expect(selection.selectedIndex == 2)
    }

    @Test("Move down from nil selects first item")
    func moveDownFromNil() {
        let selection = QuickPanelSelection()
        selection.moveSelection(by: 1, itemCount: 5)
        #expect(selection.selectedIndex == 0)
    }

    @Test("Move up from nil selects last item")
    func moveUpFromNil() {
        let selection = QuickPanelSelection()
        selection.moveSelection(by: -1, itemCount: 5)
        #expect(selection.selectedIndex == 4)
    }

    @Test("Move down increments index")
    func moveDown() {
        let selection = QuickPanelSelection()
        selection.hoverItem(at: 1)
        selection.moveSelection(by: 1, itemCount: 5)
        #expect(selection.selectedIndex == 2)
    }

    @Test("Move down clamps to last item")
    func moveDownClamps() {
        let selection = QuickPanelSelection()
        selection.hoverItem(at: 4)
        selection.moveSelection(by: 1, itemCount: 5)
        #expect(selection.selectedIndex == 4)
    }

    @Test("Move up clamps to first item")
    func moveUpClamps() {
        let selection = QuickPanelSelection()
        selection.hoverItem(at: 0)
        selection.moveSelection(by: -1, itemCount: 5)
        #expect(selection.selectedIndex == 0)
    }

    @Test("Move does nothing with zero items")
    func moveWithNoItems() {
        let selection = QuickPanelSelection()
        selection.moveSelection(by: 1, itemCount: 0)
        #expect(selection.selectedIndex == nil)
    }

    @Test("Keyboard after hover continues from hovered position")
    func keyboardAfterHover() {
        let selection = QuickPanelSelection()
        selection.hoverItem(at: 2)
        selection.moveSelection(by: 1, itemCount: 5)
        #expect(selection.selectedIndex == 3)
    }
}
