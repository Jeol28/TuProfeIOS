import Foundation

class ChatRepository {
    static let shared = ChatRepository()
    private let dataSource: any ChatDataSource = makeChatDataSource()

    static func chatId(for uid1: String, uid2: String) -> String {
        [uid1, uid2].sorted().joined(separator: "_")
    }

    func getOrCreateChat(chatId: String, participantIds: [String]) async throws {
        try await dataSource.getOrCreateChat(chatId: chatId, participantIds: participantIds)
    }

    func listenMessages(chatId: String) -> AsyncStream<[MessageInfo]> {
        dataSource.listenMessages(chatId: chatId)
    }

    func listenChats(userId: String) -> AsyncStream<[ChatInfo]> {
        dataSource.listenChats(userId: userId)
    }

    func sendMessage(chatId: String, senderId: String, recipientId: String, text: String, imageUrl: String? = nil) async throws {
        try await dataSource.sendMessage(chatId: chatId, senderId: senderId, recipientId: recipientId, text: text, imageUrl: imageUrl)
    }

    func uploadChatImage(userId: String, imageData: Data) async throws -> String {
        try await StorageRepository.shared.uploadChatImage(userId: userId, imageData: imageData)
    }

    func markRead(chatId: String, userId: String) async throws {
        try await dataSource.markRead(chatId: chatId, userId: userId)
    }

    func getOtherUserInfo(userId: String) async throws -> (name: String, imageUrl: String?) {
        try await dataSource.getOtherUserInfo(userId: userId)
    }
}
