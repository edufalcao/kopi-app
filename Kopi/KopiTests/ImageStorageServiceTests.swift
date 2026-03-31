import Testing
import Foundation
@testable import Kopi

@Suite("ImageStorageService Tests")
struct ImageStorageServiceTests {
    let service: ImageStorageService
    let testDir: URL

    init() throws {
        testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("KopiTests-\(UUID().uuidString)")
        service = ImageStorageService(imagesDirectory: testDir)
    }

    @Test("Small image stored as blob, not on filesystem")
    func smallImageReturnsBlob() throws {
        let smallImage = Data(repeating: 0xFF, count: 1024) // 1KB
        let result = try service.store(imageData: smallImage)

        #expect(result.blob != nil)
        #expect(result.path == nil)
        #expect(result.blob == smallImage)
    }

    @Test("Large image stored on filesystem, not as blob")
    func largeImageReturnsPath() throws {
        let largeImage = Data(repeating: 0xFF, count: 200_000) // ~200KB
        let result = try service.store(imageData: largeImage)

        #expect(result.blob == nil)
        #expect(result.path != nil)

        let savedData = try Data(contentsOf: URL(fileURLWithPath: result.path!))
        #expect(savedData == largeImage)
    }

    @Test("Retrieve image from filesystem path")
    func retrieveFromPath() throws {
        let largeImage = Data(repeating: 0xAB, count: 200_000)
        let result = try service.store(imageData: largeImage)

        let retrieved = try service.retrieve(path: result.path!)
        #expect(retrieved == largeImage)
    }

    @Test("Delete image file from filesystem")
    func deleteImageFile() throws {
        let largeImage = Data(repeating: 0xCD, count: 200_000)
        let result = try service.store(imageData: largeImage)
        let path = result.path!

        try service.deleteFile(at: path)
        #expect(!FileManager.default.fileExists(atPath: path))
    }

    @Test("SHA-256 hash computation is consistent")
    func hashConsistency() {
        let data = Data("test image data".utf8)
        let hash1 = ImageStorageService.sha256Hash(of: data)
        let hash2 = ImageStorageService.sha256Hash(of: data)

        #expect(hash1 == hash2)
        #expect(!hash1.isEmpty)
    }

    @Test("Different data produces different hashes")
    func hashUniqueness() {
        let data1 = Data("image A".utf8)
        let data2 = Data("image B".utf8)

        #expect(ImageStorageService.sha256Hash(of: data1) != ImageStorageService.sha256Hash(of: data2))
    }
}
