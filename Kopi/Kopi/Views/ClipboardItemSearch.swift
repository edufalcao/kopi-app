import Foundation

enum ClipboardItemSearch {
    static func filter(
        _ items: [ClipboardItem],
        selectedFilter: ClipboardFilter,
        query: String
    ) -> [ClipboardItem] {
        items.filter {
            matchesFilter($0, selectedFilter: selectedFilter) &&
            matches($0, query: query)
        }
    }

    static func matches(_ item: ClipboardItem, query: String) -> Bool {
        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedQuery.isEmpty else { return true }

        return searchableTerms(for: item).contains {
            $0.localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    private static func matchesFilter(
        _ item: ClipboardItem,
        selectedFilter: ClipboardFilter
    ) -> Bool {
        switch selectedFilter {
        case .all:
            true
        case .text:
            item.contentType == .text
        case .images:
            item.contentType == .image
        case .pinned:
            item.isPinned
        }
    }

    private static func searchableTerms(for item: ClipboardItem) -> [String] {
        var terms: [String] = []

        switch item.contentType {
        case .text:
            if let textContent = item.textContent {
                terms.append(textContent)
            }
            terms.append(ContentType.text.rawValue)
        case .image:
            terms.append(imageDisplayName(for: item))
            terms.append(ContentType.image.rawValue)
        }

        if item.isPinned {
            terms.append("pinned")
        }

        return terms
    }

    private static func imageDisplayName(for item: ClipboardItem) -> String {
        if let path = item.imagePath {
            return URL(fileURLWithPath: path).lastPathComponent
        }

        return "Image"
    }
}
