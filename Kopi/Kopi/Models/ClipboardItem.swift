import Foundation
import SwiftData

enum ContentType: String, Codable, Sendable {
    case text
    case image
}

@Model
final class ClipboardItem {
    @Attribute(.unique) var id: UUID
    var contentType: ContentType
    var textContent: String?
    var imageData: Data?
    var imagePath: String?
    var imageSize: Int?
    var contentHash: String?
    var isPinned: Bool
    var createdAt: Date
    var lastUsedAt: Date

    init(
        contentType: ContentType,
        textContent: String? = nil,
        imageData: Data? = nil,
        imagePath: String? = nil,
        imageSize: Int? = nil,
        contentHash: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = UUID()
        self.contentType = contentType
        self.textContent = textContent
        self.imageData = imageData
        self.imagePath = imagePath
        self.imageSize = imageSize
        self.contentHash = contentHash
        self.isPinned = isPinned
        self.createdAt = Date()
        self.lastUsedAt = Date()
    }
}
