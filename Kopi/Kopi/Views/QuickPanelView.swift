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
    @FocusState private var isListFocused: Bool

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

            // Items list (ScrollView + Buttons instead of List for reliable clicks)
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
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                Button {
                                    pasteService.paste(item)
                                    try? store.updateLastUsed(item)
                                } label: {
                                    ClipboardItemRow(item: item, imageStorage: imageStorage)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(selectedIndex == index
                                              ? Color.accentColor.opacity(0.2)
                                              : Color.clear)
                                )
                                .id(item.id)
                                .contextMenu {
                                    Button("Paste") {
                                        pasteService.paste(item)
                                        try? store.updateLastUsed(item)
                                    }
                                    Button(item.isPinned ? "Unpin" : "Pin") {
                                        try? store.togglePin(item)
                                    }
                                    Divider()
                                    Button("Delete", role: .destructive) {
                                        try? store.delete(item)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: selectedIndex) { _, newIndex in
                        if let idx = newIndex, idx < filteredItems.count {
                            withAnimation {
                                proxy.scrollTo(filteredItems[idx].id, anchor: .center)
                            }
                        }
                    }
                }
                .focusable()
                .focused($isListFocused)
                .focusEffectDisabled()
                .onKeyPress(.upArrow) {
                    moveSelection(by: -1)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    moveSelection(by: 1)
                    return .handled
                }
                .onKeyPress(.return) {
                    pasteSelectedItem()
                    return .handled
                }
                .onKeyPress(.delete) {
                    deleteSelectedItem()
                    return .handled
                }
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
        // Also listen for notifications from the NSEvent monitor (backup path)
        .onReceive(NotificationCenter.default.publisher(for: .panelDeleteItem)) { _ in
            deleteSelectedItem()
        }
        .onReceive(NotificationCenter.default.publisher(for: .panelPasteItem)) { _ in
            pasteSelectedItem()
        }
        .onAppear {
            isListFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .panelDidShow)) { _ in
            isListFocused = true
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
