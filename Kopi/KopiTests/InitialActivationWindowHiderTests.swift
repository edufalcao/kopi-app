import Testing
@testable import Kopi

@Suite("InitialActivationWindowHider Tests")
struct InitialActivationWindowHiderTests {
    @Test("Hide launch-created windows on the first normal activation")
    func hidesWindowsOnFirstActivationByDefault() {
        var hider = InitialActivationWindowHider()

        #expect(hider.shouldHideWindowsOnActivation() == true)
        #expect(hider.shouldHideWindowsOnActivation() == false)
    }

    @Test("Do not hide windows when first activation is for an explicit window open")
    func skipsHidingWhenExplicitWindowWillOpen() {
        var hider = InitialActivationWindowHider()

        hider.prepareForExplicitWindowPresentation()

        #expect(hider.shouldHideWindowsOnActivation() == false)
        #expect(hider.shouldHideWindowsOnActivation() == false)
    }
}
