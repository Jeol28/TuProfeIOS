import SwiftUI
import PhotosUI

struct ChatView: View {
    let chatId: String
    let otherUserId: String

    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject var navState: NavigationState
    @State private var inputText = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var pendingImage: UIImage? = nil
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var inputFocused: Bool

    init(chatId: String, otherUserId: String) {
        self.chatId = chatId
        self.otherUserId = otherUserId
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatId: chatId, otherUserId: otherUserId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar — oculto cuando el teclado está activo
            if keyboardHeight == 0 {
                VStack(spacing: 0) {
                    TuProfeTopBarView()
                    HStack(spacing: 0) {
                        Button(action: { navState.pop() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.verdetp)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)

                        Button(action: { navState.navigate(to: .profile(userId: otherUserId)) }) {
                            HStack(spacing: 10) {
                                ProfileImageView(url: viewModel.otherUserImage, size: 34)
                                Text(viewModel.otherUserName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .background(Color.pastel)

                    Divider().foregroundStyle(Color.bordeTuProfe)
                }
            }

            // Messages
            if viewModel.isLoading {
                Spacer()
                ProgressView().tint(.verdetp)
                Spacer()
            } else if viewModel.messages.isEmpty && pendingImage == nil {
                Spacer()
                Text("Sin mensajes aún")
                    .foregroundStyle(Color.secondary)
                    .font(.system(size: 14))
                Spacer()
                    .contentShape(Rectangle())
                    .onTapGesture { inputFocused = false }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(
                                    message: message,
                                    isOwn: message.senderId == viewModel.currentUserId
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .onTapGesture { inputFocused = false }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let last = viewModel.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onAppear {
                        if let last = viewModel.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Pending image preview
            if let image = pendingImage {
                HStack {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.bordeTuProfe, lineWidth: 1))

                        Button(action: {
                            pendingImage = nil
                            selectedPhoto = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.white, Color.red)
                                .offset(x: 8, y: -8)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.pastel)
            }

            // Input bar
            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.verdetp)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .onChange(of: selectedPhoto) { item in
                    guard let item else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await MainActor.run { pendingImage = uiImage }
                        }
                    }
                }

                TextField("Escribe un mensaje...", text: $inputText, axis: .vertical)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.pastel)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.bordeTuProfe, lineWidth: 1))
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .onSubmit {
                        inputText += "\n"
                        Task { @MainActor in inputFocused = true }
                    }

                let canSend = (!inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingImage != nil) && !viewModel.isSending
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 16))
                        .frame(width: 42, height: 42)
                        .background(canSend ? Color.verdetp : Color.verdetp.opacity(0.4), in: Circle())
                }
                .disabled(!canSend)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, keyboardHeight > 0 ? 8 : (safeAreaBottomInset + 8))
            .background(Color.pastel)
        }
        .padding(.bottom, keyboardHeight)
        .background(AppBackgroundView().ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notif in
            guard let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = frame.height }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = 0 }
        }
        .onAppear { viewModel.markAsRead() }
        .onChange(of: viewModel.messages.count) { _ in viewModel.markAsRead() }
    }

    private var safeAreaBottomInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.bottom ?? 0
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageToSend = pendingImage
        inputText = ""
        pendingImage = nil
        selectedPhoto = nil
        viewModel.sendMessage(text: text, image: imageToSend)
    }
}

struct MessageBubble: View {
    let message: MessageInfo
    let isOwn: Bool
    @State private var showViewer = false

    var body: some View {
        HStack {
            if isOwn { Spacer(minLength: 60) }
            VStack(alignment: isOwn ? .trailing : .leading, spacing: 0) {
                if let imageUrl = message.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                .scaledToFit()
                                .frame(minWidth: 120, maxWidth: 220, minHeight: 80, maxHeight: 200)
                                .clipped()
                        case .failure:
                            ZStack {
                                Color.secondary.opacity(0.12)
                                Image(systemName: "photo")
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color.secondary)
                            }
                            .frame(width: 160, height: 120)
                        default:
                            ZStack {
                                Color.secondary.opacity(0.08)
                                ProgressView().tint(.verdetp)
                            }
                            .frame(width: 160, height: 120)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(6)
                    .onTapGesture { showViewer = true }
                    .fullScreenCover(isPresented: $showViewer) {
                        FullScreenImageViewer(url: imageUrl) { showViewer = false }
                    }
                }
                if !message.text.isEmpty {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(message.text)
                            .font(.system(size: 15))
                            .foregroundStyle(isOwn ? Color.white : Color.primary)
                        if let sentAt = message.sentAt {
                            Text(sentAt.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 11))
                                .foregroundStyle(isOwn ? Color.white.opacity(0.65) : Color.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, message.imageUrl != nil ? 6 : 8)
                    .padding(.bottom, 6)
                } else if let sentAt = message.sentAt {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Text(sentAt.formatted(.dateTime.hour().minute()))
                            .font(.system(size: 11))
                            .foregroundStyle(isOwn ? Color.white.opacity(0.65) : Color.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                    .padding(.bottom, 5)
                }
            }
            .background(isOwn ? Color.verdetp : Color.pastel, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(isOwn ? Color.clear : Color.bordeTuProfe, lineWidth: 1))
            if !isOwn { Spacer(minLength: 60) }
        }
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [MessageInfo] = []
    @Published var otherUserName = ""
    @Published var otherUserImage: String? = nil
    @Published var isLoading = true
    @Published var isSending = false

    let currentUserId: String
    private let chatId: String
    private let otherUserId: String
    private let chatRepo = ChatRepository.shared
    private var listenTask: Task<Void, Never>?

    init(chatId: String, otherUserId: String) {
        self.chatId = chatId
        self.otherUserId = otherUserId
        self.currentUserId = AuthRepository.shared.currentUserId ?? ""
        Task { await self.setup() }
    }

    private func setup() async {
        if let info = try? await chatRepo.getOtherUserInfo(userId: otherUserId) {
            otherUserName = info.name
            otherUserImage = info.imageUrl
        }
        try? await chatRepo.getOrCreateChat(chatId: chatId, participantIds: [currentUserId, otherUserId])
        startListening()
    }

    private func startListening() {
        listenTask?.cancel()
        listenTask = Task {
            for await msgs in chatRepo.listenMessages(chatId: chatId) {
                messages = msgs
                isLoading = false
            }
        }
    }

    func markAsRead() {
        Task { try? await chatRepo.markRead(chatId: chatId, userId: currentUserId) }
    }

    func sendMessage(text: String, image: UIImage?) {
        isSending = true
        Task {
            var imageUrl: String? = nil
            if let image,
               let data = image.jpegData(compressionQuality: 0.8) {
                imageUrl = try? await chatRepo.uploadChatImage(userId: currentUserId, imageData: data)
            }
            try? await chatRepo.sendMessage(chatId: chatId, senderId: currentUserId, recipientId: otherUserId, text: text, imageUrl: imageUrl)
            isSending = false
        }
    }

    deinit { listenTask?.cancel() }
}
