import Foundation

protocol ChatDataSource {
    func getOrCreateChat(chatId: String, participantIds: [String]) async throws
    func listenMessages(chatId: String) -> AsyncStream<[MessageInfo]>
    func listenChats(userId: String) -> AsyncStream<[ChatInfo]>
    func sendMessage(chatId: String, senderId: String, recipientId: String, text: String, imageUrl: String?) async throws
    func markRead(chatId: String, userId: String) async throws
    func getOtherUserInfo(userId: String) async throws -> (name: String, imageUrl: String?)
}

func makeChatDataSource() -> any ChatDataSource {
    ChatFirestoreDataSource()
}
