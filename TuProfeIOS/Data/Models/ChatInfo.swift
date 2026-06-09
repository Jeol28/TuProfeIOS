import Foundation

struct ChatInfo: Identifiable, Equatable {
    let id: String
    var chatId: String { id }
    let otherUserId: String
    let otherUserName: String
    let otherUserImage: String?
    let lastMessage: String
    let lastMessageAt: Date?
    let unreadCount: Int
    let lastMessageSenderId: String
}
