import Foundation
import CryptoKit

struct ImageStoreResult {
    let blob: Data?
    let path: String?
}

final class ImageStorageService {
    private static let blobThreshold = 128 * 1024 // 128KB
    private let imagesDirectory: URL

    init(imagesDirectory: URL? = nil) {
        if let dir = imagesDirectory {
            self.imagesDirectory = dir
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            self.imagesDirectory = appSupport
                .appendingPathComponent("Kopi")
                .appendingPathComponent("Images")
        }
    }

    func store(imageData: Data) throws -> ImageStoreResult {
        if imageData.count < Self.blobThreshold {
            return ImageStoreResult(blob: imageData, path: nil)
        }

        try FileManager.default.createDirectory(
            at: imagesDirectory,
            withIntermediateDirectories: true
        )

        let filename = "\(UUID().uuidString).png"
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        try imageData.write(to: fileURL)

        return ImageStoreResult(blob: nil, path: fileURL.path)
    }

    func retrieve(path: String) throws -> Data {
        try Data(contentsOf: URL(fileURLWithPath: path))
    }

    func deleteFile(at path: String) throws {
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    func deleteOrphanedFiles(validPaths: Set<String>) throws {
        guard FileManager.default.fileExists(atPath: imagesDirectory.path) else {
            return
        }

        let contents = try FileManager.default.contentsOfDirectory(
            at: imagesDirectory,
            includingPropertiesForKeys: nil
        )

        for fileURL in contents {
            if !validPaths.contains(fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    static func sha256Hash(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
