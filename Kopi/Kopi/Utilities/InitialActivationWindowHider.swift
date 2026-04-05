struct InitialActivationWindowHider {
    private var hasProcessedFirstActivation = false
    private var shouldHideWindowsOnFirstActivation = true

    mutating func prepareForExplicitWindowPresentation() {
        guard !hasProcessedFirstActivation else { return }
        shouldHideWindowsOnFirstActivation = false
    }

    mutating func shouldHideWindowsOnActivation() -> Bool {
        guard !hasProcessedFirstActivation else { return false }

        hasProcessedFirstActivation = true
        return shouldHideWindowsOnFirstActivation
    }
}
