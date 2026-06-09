import Foundation
import FirebaseFirestore

final class ChatFirestoreDataSource: ChatDataSource {
    private let db = Firestore.firestore()
    private var chats: CollectionReference { db.collection("chats") }

    func getOrCreateChat(chatId: String, participantIds: [String]) async throws {
        let doc = try await chats.document(chatId).getDocument()
        guard !doc.exists else { return }
        let data: [String: Any] = [
            "participantIds": participantIds,
            "lastMessage": "",
            "lastMessageAt": FieldValue.serverTimestamp(),
            "unreadCounts": Dictionary(uniqueKeysWithValues: participantIds.map { ($0, 0) })
        ]
        try await chats.document(chatId).setData(data)
    }

    func listenMessages(chatId: String) -> AsyncStream<[MessageInfo]> {
        AsyncStream { continuation in
            let listener = chats.document(chatId)
                .collection("messages")
                .order(by: "sentAt", descending: false)
                .addSnapshotListener { snapshot, _ in
                    guard let snapshot else { return }
                    let messages = snapshot.documents.compactMap { doc -> MessageInfo? in
                        let data = doc.data()
                        return MessageInfo(
                            id: doc.documentID,
                            senderId: data["senderId"] as? String ?? "",
                            text: data["text"] as? String ?? "",
                            sentAt: (data["sentAt"] as? Timestamp)?.dateValue(),
                            read: data["read"] as? Bool ?? false,
                            imageUrl: data["imageUrl"] as? String
                        )
                    }
                    continuation.yield(messages)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func listenChats(userId: String) -> AsyncStream<[ChatInfo]> {
        AsyncStream { continuation in
            // No orderBy to avoid requiring a composite Firestore index — sorted client-side
            let listener = chats
                .whereField("participantIds", arrayContains: userId)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        print("listenChats error: \(error.localizedDescription)")
                        return
                    }
                    guard let snapshot else { return }
                    let list = snapshot.documents.compactMap { doc -> ChatInfo? in
                        let data = doc.data()
                        guard let participants = data["participantIds"] as? [String],
                              let otherUserId = participants.first(where: { $0 != userId })
                        else { return nil }
                        let unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]
                        return ChatInfo(
                            id: doc.documentID,
                            otherUserId: otherUserId,
                            otherUserName: "",
                            otherUserImage: nil,
                            lastMessage: data["lastMessage"] as? String ?? "",
                            lastMessageAt: (data["lastMessageAt"] as? Timestamp)?.dateValue(),
                            unreadCount: unreadCounts[userId] ?? 0,
                            lastMessageSenderId: data["lastMessageSenderId"] as? String ?? ""
                        )
                    }
                    // Sort client-side by lastMessageAt descending
                    continuation.yield(list.sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) })
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func sendMessage(chatId: String, senderId: String, recipientId: String, text: String, imageUrl: String?) async throws {
        var messageData: [String: Any] = [
            "senderId": senderId,
            "text": text,
            "sentAt": FieldValue.serverTimestamp(),
            "read": false
        ]
        if let imageUrl { messageData["imageUrl"] = imageUrl }
        try await chats.document(chatId).collection("messages").addDocument(data: messageData)
        let lastMsg = text.isEmpty ? "📷 Imagen" : text
        try await chats.document(chatId).updateData([
            "lastMessage": lastMsg,
            "lastMessageAt": FieldValue.serverTimestamp(),
            "lastMessageSenderId": senderId,
            "unreadCounts.\(recipientId)": FieldValue.increment(Int64(1))
        ])
    }

    func markRead(chatId: String, userId: String) async throws {
        try await chats.document(chatId).updateData(["unreadCounts.\(userId)": 0])
    }

    func getOtherUserInfo(userId: String) async throws -> (name: String, imageUrl: String?) {
        let doc = try await db.collection("users").document(userId).getDocument()
        let data = doc.data() ?? [:]
        let name = data["username"] as? String ?? data["name"] as? String ?? "Usuario"
        let imageUrl = data["foto"] as? String
        return (name, imageUrl)
    }
}
