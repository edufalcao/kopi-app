import Testing
@testable import Kopi

@Suite("StatusMenuActionDispatcher Tests")
@MainActor
struct StatusMenuActionDispatcherTests {
    @Test("Dispatch menu action asynchronously")
    func dispatchesAsynchronously() {
        var scheduledAction: (() -> Void)?
        var didRun = false

        let dispatcher = StatusMenuActionDispatcher { action in
            scheduledAction = action
        }

        dispatcher.dispatch {
            didRun = true
        }

        #expect(!didRun)
        #expect(scheduledAction != nil)

        scheduledAction?()

        #expect(didRun)
    }
}
