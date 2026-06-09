import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                BackButtonHeader(action: { navState.pop() })

                Text("Chats")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.verdetp)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                if viewModel.isLoading {
                    ProgressView().tint(.verdetp).frame(maxHeight: .infinity)
                } else if viewModel.chats.isEmpty {
                    VStack {
                        Spacer()
                        Text("Sin mensajes aún")
                            .foregroundStyle(Color.secondary)
                            .font(.system(size: 15))
                        Spacer()
                    }
                } else {
                    List(viewModel.chats) { chat in
                        Button(action: {
                            navState.navigate(to: .chat(chatId: chat.chatId, otherUserId: chat.otherUserId))
                        }) {
                            ChatListRow(chat: chat, currentUserId: viewModel.currentUserId)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Color.bordeTuProfe)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear { viewModel.startListening() }
    }
}

struct ChatListRow: View {
    let chat: ChatInfo
    let currentUserId: String

    private var isUnread: Bool { chat.unreadCount > 0 }

    var body: some View {
        HStack(spacing: 12) {
            ProfileImageView(url: chat.otherUserImage, size: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(chat.otherUserName.isEmpty ? chat.otherUserId : chat.otherUserName)
                    .font(.system(size: 15, weight: isUnread ? .bold : .semibold))
                lastMessageText
                    .font(.system(size: 13))
                    .foregroundStyle(isUnread ? Color.primary : Color.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let date = chat.lastMessageAt {
                    Text(date.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 11, weight: isUnread ? .semibold : .regular))
                        .foregroundStyle(isUnread ? Color.verdetp : Color.secondary)
                }
                if isUnread {
                    Text("\(chat.unreadCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.verdetp, in: Capsule())
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(isUnread ? Color.verdetp.opacity(0.07) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var lastMessageText: Text {
        if chat.lastMessage.isEmpty {
            return Text("Sin mensajes aún")
        } else if chat.lastMessageSenderId == currentUserId {
            let prefixWeight: Font.Weight = isUnread ? .bold : .semibold
            let msgWeight: Font.Weight = isUnread ? .semibold : .regular
            return Text("Tú: ").fontWeight(prefixWeight) + Text(chat.lastMessage).fontWeight(msgWeight)
        } else {
            return isUnread ? Text(chat.lastMessage).fontWeight(.semibold) : Text(chat.lastMessage)
        }
    }
}

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var chats: [ChatInfo] = []
    @Published var isLoading = true

    private let chatRepo = ChatRepository.shared
    var currentUserId: String { AuthRepository.shared.currentUserId ?? "" }
    private var listenTask: Task<Void, Never>?

    func startListening() {
        let uid = currentUserId
        guard !uid.isEmpty else { isLoading = false; return }
        listenTask?.cancel()
        listenTask = Task {
            for await rawChats in chatRepo.listenChats(userId: uid) {
                var enriched: [ChatInfo] = []
                for chat in rawChats {
                    if chat.otherUserName.isEmpty {
                        let info = try? await chatRepo.getOtherUserInfo(userId: chat.otherUserId)
                        enriched.append(ChatInfo(
                            id: chat.id,
                            otherUserId: chat.otherUserId,
                            otherUserName: info?.name ?? chat.otherUserId,
                            otherUserImage: info?.imageUrl,
                            lastMessage: chat.lastMessage,
                            lastMessageAt: chat.lastMessageAt,
                            unreadCount: chat.unreadCount,
                            lastMessageSenderId: chat.lastMessageSenderId
                        ))
                    } else {
                        enriched.append(chat)
                    }
                }
                chats = enriched
                isLoading = false
            }
        }
    }

    deinit { listenTask?.cancel() }
}
