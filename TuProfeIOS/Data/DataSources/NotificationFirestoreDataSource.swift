import Foundation
import FirebaseFirestore

final class NotificationFirestoreDataSource {
    private let db = Firestore.firestore()

    private func userNotifs(_ userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("notifications")
    }

    func listenNotifications(userId: String) -> AsyncStream<[AppNotification]> {
        AsyncStream { continuation in
            let listener = userNotifs(userId)
                .addSnapshotListener { snapshot, _ in
                    guard let snapshot else { return }
                    let list = snapshot.documents.compactMap { doc -> AppNotification? in
                        let d = doc.data()
                        let title = d["title"] as? String ?? ""
                        guard !title.isEmpty else { return nil }
                        let type = d["type"] as? String ?? ""
                        let reviewId = d["reviewId"] as? String ?? ""
                        let commentId = d["commentId"] as? String ?? ""
                        let fromUserId = d["fromUserId"] as? String ?? ""
                        let entityId = Self.entityId(type: type, reviewId: reviewId, commentId: commentId, fromUserId: fromUserId)
                        let ts = (d["createdAt"] as? Timestamp)?.dateValue()
                            ?? (d["timestamp"] as? Timestamp)?.dateValue()
                            ?? Date(timeIntervalSince1970: 0)
                        // CF uses "read"; older client docs used "isRead"
                        let isRead = d["read"] as? Bool ?? d["isRead"] as? Bool ?? false
                        return AppNotification(
                            id: doc.documentID,
                            type: type,
                            entityId: entityId,
                            title: title,
                            body: d["body"] as? String ?? "",
                            senderId: fromUserId,
                            senderName: d["fromUsername"] as? String ?? "",
                            senderImageUrl: d["senderImageUrl"] as? String ?? "",
                            timestamp: ts,
                            isRead: isRead
                        )
                    }
                    .sorted { $0.timestamp > $1.timestamp }
                    continuation.yield(list)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func listenUnreadCount(userId: String) -> AsyncStream<Int> {
        AsyncStream { continuation in
            let listener = userNotifs(userId)
                .addSnapshotListener { snapshot, _ in
                    let count = snapshot?.documents.filter { doc in
                        let d = doc.data()
                        let title = d["title"] as? String ?? ""
                        let read = d["read"] as? Bool ?? d["isRead"] as? Bool ?? false
                        return !title.isEmpty && !read
                    }.count ?? 0
                    continuation.yield(count)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func markRead(userId: String, notifId: String) async throws {
        try await userNotifs(userId).document(notifId).updateData(["read": true])
    }

    func markAllRead(userId: String) async throws {
        let unread = try await userNotifs(userId)
            .whereField("read", isEqualTo: false)
            .getDocuments()
        guard !unread.documents.isEmpty else { return }
        let batch = db.batch()
        unread.documents.forEach { batch.updateData(["read": true], forDocument: $0.reference) }
        try await batch.commit()
    }

    private static func entityId(type: String, reviewId: String, commentId: String, fromUserId: String) -> String {
        switch type {
        case "like", "reviewDeleted": return reviewId
        case "comment", "reply": return commentId.isEmpty ? reviewId : commentId
        case "follow": return fromUserId
        default: return reviewId.isEmpty ? (commentId.isEmpty ? fromUserId : commentId) : reviewId
        }
    }
}