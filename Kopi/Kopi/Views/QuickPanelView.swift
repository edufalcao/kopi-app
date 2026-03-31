import SwiftUI
import SwiftData

struct QuickPanelView: View {
    let store: ClipboardStore
    let pasteService: PasteService
    let imageStorage = ImageStorageService()

    @Query(sort: \ClipboardItem.createdAt, order: .reverse)
    private var allItems: [ClipboardItem]

    @State private var searchText = ""
    @State private var selectedFilter: ClipboardFilter = .all
    @State private var selectedIndex: Int?

    private var filteredItems: [ClipboardItem] {
        var items = allItems

        switch selectedFilter {
        case .all:
            break
        case .text:
            items = items.filter { $0.contentType == .text }
        case .images:
            items = items.filter { $0.contentType == .image }
        case .pinned:
            items = items.filter { $0.isPinned }
        }

        if !searchText.isEmpty {
            items = items.filter {
                $0.textContent?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search clipboard history...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Filter chips
            FilterChipsView(selectedFilter: $selectedFilter)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            Divider()

            // Items list
            if filteredItems.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "clipboard")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                    Text("No items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                    ClipboardItemRow(item: item, imageStorage: imageStorage)
                        .id(item.id)
                        .listRowInsets(EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6))
                        .listRowBackground(
                            selectedIndex == index
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                        )
                        .onTapGesture {
                            pasteService.paste(item)
                            try? store.updateLastUsed(item)
                        }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            Divider()

            // Keyboard hints
            HStack {
                Text("↑↓ Navigate")
                Spacer()
                Text("⏎ Paste")
                Spacer()
                Text("⌫ Delete")
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 340, height: 480)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // Arrow keys handled via .onKeyPress (work when List isn't focused)
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        // Delete and Paste handled via NSEvent monitor → NotificationCenter
        // (because .onKeyPress doesn't fire when List/TextField has focus)
        .onReceive(NotificationCenter.default.publisher(for: .panelDeleteItem)) { _ in
            deleteSelectedItem()
        }
        .onReceive(NotificationCenter.default.publisher(for: .panelPasteItem)) { _ in
            pasteSelectedItem()
        }
    }

    private func deleteSelectedItem() {
        if let index = selectedIndex, index < filteredItems.count {
            try? store.delete(filteredItems[index])
            selectedIndex = nil
        }
    }

    private func pasteSelectedItem() {
        if let index = selectedIndex, index < filteredItems.count {
            let item = filteredItems[index]
            pasteService.paste(item)
            try? store.updateLastUsed(item)
        }
    }

    private func moveSelection(by offset: Int) {
        let count = filteredItems.count
        guard count > 0 else { return }

        if let current = selectedIndex {
            selectedIndex = max(0, min(count - 1, current + offset))
        } else {
            selectedIndex = offset > 0 ? 0 : count - 1
        }
    }
}
