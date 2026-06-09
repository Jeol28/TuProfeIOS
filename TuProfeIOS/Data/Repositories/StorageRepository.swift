import Foundation
import FirebaseStorage

class StorageRepository {
    static let shared = StorageRepository()
    private let storage = Storage.storage()

    func getProfileImageURL(userId: String) async throws -> String? {
        let ref = storage.reference().child("profileImages/\(userId).jpg")
        do {
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            return nil
        }
    }

    func uploadProfileImage(userId: String, imageData: Data) async throws -> String {
        let ref = storage.reference().child("profileImages/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    func deleteProfileImage(userId: String) async throws {
        let ref = storage.reference().child("profileImages/\(userId).jpg")
        try await ref.delete()
    }

    func uploadReviewImages(userId: String, images: [Data]) async throws -> [String] {
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)

        return try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (index, imageData) in images.enumerated() {
                group.addTask {
                    let ref = self.storage.reference()
                        .child("reviewImages/\(userId)/\(timestamp)_\(index).jpg")
                    _ = try await ref.putDataAsync(imageData, metadata: metadata)
                    let url = try await ref.downloadURL()
                    return (index, url.absoluteString)
                }
            }
            var results: [(Int, String)] = []
            for try await pair in group { results.append(pair) }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    func uploadChatImage(userId: String, imageData: Data) async throws -> String {
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let ref = storage.reference().child("chatImages/\(userId)/\(timestamp).jpg")
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}