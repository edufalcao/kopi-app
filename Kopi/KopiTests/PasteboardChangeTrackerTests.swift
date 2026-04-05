import Testing
@testable import Kopi

@Suite("PasteboardChangeTracker Tests")
struct PasteboardChangeTrackerTests {
    @Test("Ignore only the exact self-written change count once")
    func ignoresMarkedChangeCountOnce() {
        var tracker = PasteboardChangeTracker()

        tracker.markOwnWrite(changeCount: 5)

        #expect(tracker.shouldIgnore(changeCount: 5) == true)
        #expect(tracker.shouldIgnore(changeCount: 5) == false)
    }

    @Test("Do not ignore a newer external clipboard change")
    func doesNotIgnoreNewerExternalChange() {
        var tracker = PasteboardChangeTracker()

        tracker.markOwnWrite(changeCount: 5)

        #expect(tracker.shouldIgnore(changeCount: 6) == false)
        #expect(tracker.shouldIgnore(changeCount: 5) == false)
    }

    @Test("Unmarked changes are processed normally")
    func unmarkedChangesAreNotIgnored() {
        var tracker = PasteboardChangeTracker()

        #expect(tracker.shouldIgnore(changeCount: 1) == false)
    }
}
