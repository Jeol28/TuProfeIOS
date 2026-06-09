import Foundation
import FirebaseFirestore

// MARK: - ModerationCache

extension NSNotification.Name {
    static let moderationUpdated = NSNotification.Name("TuProfe.ModerationUpdated")
}

final class ModerationCache {
    static let shared = ModerationCache()
    private init() {}

    var blockedUserIds: Set<String> = []
    var blockedByUserIds: Set<String> = []
    var mutedReviewIds: Set<String> = []
    var mutedCommentIds: Set<String> = []

    func blockUser(_ userId: String) {
        blockedUserIds.insert(userId)
        NotificationCenter.default.post(name: .moderationUpdated, object: nil)
    }

    func unblockUser(_ userId: String) {
        blockedUserIds.remove(userId)
        NotificationCenter.default.post(name: .moderationUpdated, object: nil)
    }

    func muteReview(_ reviewId: String) {
        mutedReviewIds.insert(reviewId)
        NotificationCenter.default.post(name: .moderationUpdated, object: nil)
    }

    func muteComment(_ commentId: String) {
        mutedCommentIds.insert(commentId)
        NotificationCenter.default.post(name: .moderationUpdated, object: nil)
    }

    func load(blocked: Set<String>, blockedBy: Set<String>, mutedReviews: Set<String>, mutedComments: Set<String>) {
        blockedUserIds = blocked
        blockedByUserIds = blockedBy
        mutedReviewIds = mutedReviews
        mutedCommentIds = mutedComments
        NotificationCenter.default.post(name: .moderationUpdated, object: nil)
    }
}

extension Array where Element == ReviewInfo {
    func applyModerationFilter() -> [ReviewInfo] {
        let cache = ModerationCache.shared
        return filter {
            !cache.blockedUserIds.contains($0.usuario.id) &&
            !cache.blockedByUserIds.contains($0.usuario.id) &&
            !cache.mutedReviewIds.contains($0.id)
        }
    }
}

extension Array where Element == ReviewMapMarker {
    func applyModerationFilter() -> [ReviewMapMarker] {
        let cache = ModerationCache.shared
        return filter {
            !cache.blockedUserIds.contains($0.authorUserId) &&
            !cache.blockedByUserIds.contains($0.authorUserId) &&
            !cache.mutedReviewIds.contains($0.id)
        }
    }
}

// MARK: - BlockedUser

struct BlockedUser: Identifiable {
    let id: String
    let username: String
    let fotoPerfil: String?
}

// MARK: - ModerationRepository

class ModerationRepository {
    static let shared = ModerationRepository()
    private let db = Firestore.firestore()

    func loadCacheForUser(userId: String) async {
        do {
            async let blocksDocs = db.collection("blocks")
                .whereField("blockerId", isEqualTo: userId)
                .getDocuments()
            async let blockedByDocs = db.collection("blocks")
                .whereField("blockedId", isEqualTo: userId)
                .getDocuments()
            async let mutesDocs = db.collection("mutes")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            let (blocksSnap, blockedBySnap, mutesSnap) = try await (blocksDocs, blockedByDocs, mutesDocs)

            let blocks = blocksSnap.documents.compactMap { $0.data()["blockedId"] as? String }
            let blockedBy = blockedBySnap.documents.compactMap { $0.data()["blockerId"] as? String }
            let muteDocs = mutesSnap.documents

            let mutedReviews = muteDocs
                .filter { $0.data()["targetType"] as? String == "review" }
                .compactMap { $0.data()["targetId"] as? String }
            let mutedComments = muteDocs
                .filter { $0.data()["targetType"] as? String == "comment" }
                .compactMap { $0.data()["targetId"] as? String }

            await MainActor.run {
                ModerationCache.shared.load(
                    blocked: Set(blocks),
                    blockedBy: Set(blockedBy),
                    mutedReviews: Set(mutedReviews),
                    mutedComments: Set(mutedComments)
                )
            }
        } catch {
            // Silent fail — cache stays empty
        }
    }

    func report(reporterId: String, targetId: String, targetType: String) async throws {
        try await db.collection("reports").addDocument(data: [
            "reporterId": reporterId,
            "targetId": targetId,
            "targetType": targetType,
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ])
        await MainActor.run {
            if targetType == "review" {
                ModerationCache.shared.muteReview(targetId)
            } else if targetType == "comment" {
                ModerationCache.shared.muteComment(targetId)
            }
        }
    }

    func getBlockedUsers(userId: String) async throws -> [BlockedUser] {
        let docs = try await db.collection("blocks")
            .whereField("blockerId", isEqualTo: userId)
            .getDocuments().documents

        var result: [BlockedUser] = []
        for doc in docs {
            guard let blockedId = doc.data()["blockedId"] as? String else { continue }
            let userDoc = try await db.collection("users").document(blockedId).getDocument()
            guard userDoc.exists, let data = userDoc.data() else { continue }
            result.append(BlockedUser(
                id: blockedId,
                username: data["username"] as? String ?? blockedId,
                fotoPerfil: data["fotoPerfil"] as? String
            ))
        }
        return result
    }

    func unblockUser(blockerId: String, blockedId: String) async throws {
        try await db.collection("blocks").document("\(blockerId)_\(blockedId)").delete()
        await MainActor.run { ModerationCache.shared.unblockUser(blockedId) }
    }

    func blockUser(blockerId: String, blockedId: String) async throws {
        try await db.collection("blocks").document("\(blockerId)_\(blockedId)").setData([
            "blockerId": blockerId,
            "blockedId": blockedId,
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ])
        await MainActor.run { ModerationCache.shared.blockUser(blockedId) }
    }

    func mute(userId: String, targetId: String, targetType: String) async throws {
        try await db.collection("mutes").addDocument(data: [
            "userId": userId,
            "targetId": targetId,
            "targetType": targetType,
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ])
        await MainActor.run {
            if targetType == "review" {
                ModerationCache.shared.muteReview(targetId)
            } else {
                ModerationCache.shared.muteComment(targetId)
            }
        }
    }
}
