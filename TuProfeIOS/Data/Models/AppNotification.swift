import Foundation

struct AppNotification: Identifiable {
    let id: String
    let type: String          // "like", "comment", "follow", "review"
    let entityId: String      // reviewId, commentId, or userId depending on type
    let title: String
    let body: String
    let senderId: String
    let senderName: String
    let senderImageUrl: String
    let timestamp: Date
    let isRead: Bool
}
