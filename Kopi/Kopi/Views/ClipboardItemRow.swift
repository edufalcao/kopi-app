import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let imageStorage: ImageStorageService

    var body: some View {
        HStack(spacing: 8) {
            if item.isPinned {
                Text("📌")
                    .font(.caption2)
            }

            if item.contentType == .image {
                imagePreview
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            VStack(alignment: .leading, spacing: 2) {
                contentPreview
                    .font(.system(size: 12))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(item.createdAt.formatted(.relative(presentation: .named)))
                    Text("•")
                    Text(item.contentType == .text ? "Text" : "Image")
                    if let size = item.imageSize {
                        Text("•")
                        Text(ByteCountFormatter.string(
                            fromByteCount: Int64(size),
                            countStyle: .file
                        ))
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.contentType {
        case .text:
            Text(item.textContent ?? "")
                .foregroundStyle(.primary)
        case .image:
            Text(imageName)
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let data = resolveImageData(), let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
        }
    }

    private var imageName: String {
        if let path = item.imagePath {
            return URL(fileURLWithPath: path).lastPathComponent
        }
        return "Image"
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
