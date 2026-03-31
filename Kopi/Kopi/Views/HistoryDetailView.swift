import SwiftUI

struct HistoryDetailView: View {
    let item: ClipboardItem
    let imageStorage: ImageStorageService
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(item.contentType == .text ? "Text" : "Image") — Copied \(item.createdAt.formatted(date: .omitted, time: .shortened))")
                        .font(.headline)
                    Text(metadataString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        onTogglePin()
                    } label: {
                        Text(item.isPinned ? "📌 Pinned" : "Pin")
                    }

                    Button("Copy") {
                        onCopy()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                }
            }
            .padding()

            Divider()

            // Preview
            ScrollView {
                contentPreview
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var metadataString: String {
        var parts: [String] = []
        if let text = item.textContent {
            parts.append("\(text.count) characters")
        }
        if let size = item.imageSize {
            parts.append(ByteCountFormatter.string(
                fromByteCount: Int64(size),
                countStyle: .file
            ))
        }
        return parts.joined(separator: " • ")
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.contentType {
        case .text:
            Text(item.textContent ?? "")
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

        case .image:
            if let data = resolveImageData(), let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ContentUnavailableView(
                    "Image not available",
                    systemImage: "photo",
                    description: Text("The image file may have been deleted.")
                )
            }
        }
    }

    private func resolveImageData() -> Data? {
        if let blob = item.imageData {
            return blob
        }
        if let path = item.imagePath {
            return try? imageStorage.retrieve(path: path)
        }
        return nil
    }
}
