struct PasteboardChangeTracker {
    private var ownWriteChangeCount: Int?

    mutating func markOwnWrite(changeCount: Int) {
        ownWriteChangeCount = changeCount
    }

    mutating func shouldIgnore(changeCount: Int) -> Bool {
        guard let ownWriteChangeCount else { return false }

        if changeCount == ownWriteChangeCount {
            self.ownWriteChangeCount = nil
            return true
        }

        if changeCount > ownWriteChangeCount {
            self.ownWriteChangeCount = nil
        }

        return false
    }
}
