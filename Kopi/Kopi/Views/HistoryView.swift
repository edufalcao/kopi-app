import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardItem.createdAt, order: .reverse)
    private var allItems: [ClipboardItem]

    @State private var searchText = ""
    @State private var selectedFilter: ClipboardFilter = .all
    @State private var selectedItem: ClipboardItem?

    private let imageStorage = ImageStorageService()

    private var filteredItems: [ClipboardItem] {
        ClipboardItemSearch.filter(
            allItems,
            selectedFilter: selectedFilter,
            query: searchText
        )
    }

    private var groupedItems: [(String, [ClipboardItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredItems) { item -> String in
            if calendar.isDateInToday(item.createdAt) {
                return "Today"
            } else if calendar.isDateInYesterday(item.createdAt) {
                return "Yesterday"
            } else {
                return item.createdAt.formatted(date: .abbreviated, time: .omitted)
            }
        }

        let order = ["Today", "Yesterday"]
        return grouped.sorted { a, b in
            let aIndex = order.firstIndex(of: a.key) ?? Int.max
            let bIndex = order.firstIndex(of: b.key) ?? Int.max
            if aIndex != bIndex { return aIndex < bIndex }
            return (a.value.first?.createdAt ?? .distantPast) >
                   (b.value.first?.createdAt ?? .distantPast)
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)

                Divider()

                FilterChipsView(selectedFilter: $selectedFilter)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)

                Divider()

                List(selection: $selectedItem) {
                    ForEach(groupedItems, id: \.0) { group, items in
                        Section(group) {
                            ForEach(items) { item in
                                ClipboardItemRow(item: item, imageStorage: imageStorage)
                                    .tag(item)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 350)
        } detail: {
            if let item = selectedItem {
                HistoryDetailView(
                    item: item,
                    imageStorage: imageStorage,
                    onCopy: {
                        copyToPasteboard(item)
                    },
                    onTogglePin: {
                        item.isPinned.toggle()
                        try? modelContext.save()
                    },
                    onDelete: {
                        if let path = item.imagePath {
                            try? imageStorage.deleteFile(at: path)
                        }
                        selectedItem = nil
                        modelContext.delete(item)
                        try? modelContext.save()
                    }
                )
            } else {
                ContentUnavailableView(
                    "Select an item",
                    systemImage: "clipboard",
                    description: Text("Choose a clipboard item to see its full content.")
                )
            }
        }
    }

    private func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.contentType {
        case .text:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let data = item.imageData {
                pasteboard.setData(data, forType: .tiff)
            } else if let path = item.imagePath,
                      let data = try? imageStorage.retrieve(path: path) {
                pasteboard.setData(data, forType: .tiff)
            }
        }
    }
}
