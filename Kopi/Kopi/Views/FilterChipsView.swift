import SwiftUI

enum ClipboardFilter: String, CaseIterable {
    case all = "All"
    case text = "Text"
    case images = "Images"
    case pinned = "Pinned"
}

struct FilterChipsView: View {
    @Binding var selectedFilter: ClipboardFilter

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ClipboardFilter.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter == .pinned ? "📌 \(filter.rawValue)" : filter.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            selectedFilter == filter
                                ? Color.accentColor
                                : Color.secondary.opacity(0.2)
                        )
                        .foregroundStyle(
                            selectedFilter == filter ? .white : .secondary
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}
