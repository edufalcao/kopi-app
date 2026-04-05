import Foundation
import Testing
@testable import Kopi

@Suite("ClipboardItemSearch Tests")
@MainActor
struct ClipboardItemSearchTests {
    @Test("Text items match query by content")
    func textMatchesContent() {
        let item = ClipboardItem(contentType: .text, textContent: "Hello, world!")

        #expect(ClipboardItemSearch.matches(item, query: "world"))
        #expect(!ClipboardItemSearch.matches(item, query: "swift"))
    }

    @Test("Image items match generic image query")
    func imageMatchesGenericTypeQuery() {
        let item = ClipboardItem(contentType: .image, imageData: Data([0x01]))

        #expect(ClipboardItemSearch.matches(item, query: "image"))
    }

    @Test("Image items with a path match by display name")
    func imageMatchesDisplayNameQuery() {
        let item = ClipboardItem(
            contentType: .image,
            imagePath: "/tmp/screenshot-123.png",
            imageSize: 42
        )

        #expect(ClipboardItemSearch.matches(item, query: "screenshot"))
        #expect(!ClipboardItemSearch.matches(item, query: "invoice"))
    }

    @Test("Pinned filter keeps pinned image items")
    func pinnedFilterIncludesPinnedImages() {
        let pinnedImage = ClipboardItem(contentType: .image, imageData: Data([0x01]), isPinned: true)
        let unpinnedText = ClipboardItem(contentType: .text, textContent: "Hello")

        let results = ClipboardItemSearch.filter(
            [pinnedImage, unpinnedText],
            selectedFilter: .pinned,
            query: ""
        )

        #expect(results.count == 1)
        #expect(results[0].id == pinnedImage.id)
    }

    @Test("Image filter and query can return matching image rows")
    func imageFilterAndQueryReturnMatchingImages() {
        let image = ClipboardItem(
            contentType: .image,
            imagePath: "/tmp/screenshot-123.png",
            imageSize: 42
        )
        let text = ClipboardItem(contentType: .text, textContent: "screenshot notes")

        let results = ClipboardItemSearch.filter(
            [image, text],
            selectedFilter: .images,
            query: "screenshot"
        )

        #expect(results.count == 1)
        #expect(results[0].id == image.id)
    }
}
