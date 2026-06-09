import SwiftUI
import UIKit

// MARK: - CommentDetalleView (matches Android CommentDetalleScreen)

struct CommentDetalleView: View {
    let commentId: String
    @StateObject private var viewModel = CommentDetalleViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            if viewModel.isLoading {
                ProgressView().tint(.verdetp)
            } else if let comment = viewModel.comment {
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 16)

                        // Main comment card with action bar
                        CommentMainCard(
                            comment: comment,
                            onLike: { viewModel.toggleLike(commentId: comment.commentId) },
                            onReply: { viewModel.openReplySheet() },
                            onShare: { shareComment(comment) },
                            onUserTap: { navState.navigate(to: .profile(userId: comment.usuario.id)) },
                            onReport: { viewModel.reportComment(commentId: comment.commentId) },
                            onBlock: { viewModel.blockUser(userId: comment.usuario.id) },
                            onMute: { viewModel.muteComment(commentId: comment.commentId) }
                        )
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 28)

                        // Replies header
                        RespuestasHeader()
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)

                        // Reply cards
                        ForEach(viewModel.replies) { reply in
                            ReplyCard(
                                reply: reply,
                                onUserTap: { navState.navigate(to: .profile(userId: reply.usuario.id)) },
                                onTap: { navState.navigate(to: .commentDetalle(commentId: reply.commentId)) }
                            )
                            .padding(.horizontal, 20)
                        }

                        Spacer().frame(height: 110)
                    }
                }
            } else if let error = viewModel.errorMessage {
                Text(LocalizedStringKey(error))
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .safeAreaInset(edge: .top) {
            TuProfeTopBarView()
        }
        .sheet(isPresented: $viewModel.showReplySheet) {
            CommentComposeSheet(
                contextText: viewModel.comment?.content ?? "",
                contextUser: viewModel.comment?.usuario.nombreUsu ?? "",
                text: $viewModel.replyText,
                onDismiss: { viewModel.closeReplySheet() },
                onSubmit: { viewModel.submitReply(commentId: commentId) },
                isSubmitting: viewModel.isSubmittingReply,
                submitLabel: "RESPONDER"
            )
        }
        .alert(Text(LocalizedStringKey(viewModel.moderationFeedback ?? "")), isPresented: Binding(
            get: { viewModel.moderationFeedback != nil },
            set: { if !$0 { viewModel.clearModerationFeedback() } }
        ), actions: {
            Button("OK") { viewModel.clearModerationFeedback() }
        })
        .onChange(of: viewModel.navigateBack) { goBack in
            if goBack { navState.pop() }
        }
        .onAppear { viewModel.cargarComment(commentId: commentId) }
    }

    private func shareComment(_ comment: CommentInfo) {
        let text = "Comentario de @\(comment.usuario.nombreUsu):\n\n\"\(comment.content)\"\n\nVisto en TuProfe"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?
            .rootViewController?.present(av, animated: true)
    }
}

// MARK: - Comment main card with action bar (matches Android CommentMainCard)

struct CommentMainCard: View {
    let comment: CommentInfo
    let onLike: () -> Void
    let onReply: () -> Void
    let onShare: () -> Void
    let onUserTap: () -> Void
    let onReport: () -> Void
    let onBlock: () -> Void
    let onMute: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            CommentContentSection(comment: comment, onUserTap: onUserTap)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            CommentActionBar(
                isLiked: comment.liked,
                authorName: comment.usuario.nombreUsu,
                onLike: onLike,
                onReply: onReply,
                onShare: onShare,
                onReport: onReport,
                onBlock: onBlock,
                onMute: onMute
            )
        }
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 1.5)
        )
    }
}

// MARK: - Comment content (matches Android ComentarioContent)

struct CommentContentSection: View {
    let comment: CommentInfo
    let onUserTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Button(action: onUserTap) {
                    ProfileImageView(url: comment.usuario.imageprofeUrl, size: 40)
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: 2) {
                    Button(action: onUserTap) {
                        Text("@\(comment.usuario.perfilAnonimo ? "Anónimo" : comment.usuario.nombreUsu)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .buttonStyle(PlainButtonStyle())

                    HStack(spacing: 6) {
                        Text(comment.time)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        if comment.editado {
                            Text("Editado")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.verdetp)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.verdetp.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }

                Spacer()
            }

            Text(comment.content)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .padding(.leading, 2)

            HStack(spacing: 16) {
                Text("\(comment.likes) Likes")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)

                Text("\(comment.repliesCount) Respuestas")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 2)
            .padding(.top, 2)
        }
    }
}

// MARK: - Comment action bar (matches Android CommentActionBar)

struct CommentActionBar: View {
    let isLiked: Bool
    let authorName: String
    let onLike: () -> Void
    let onReply: () -> Void
    let onShare: () -> Void
    let onReport: () -> Void
    let onBlock: () -> Void
    let onMute: () -> Void

    @State private var likeScale: CGFloat = 1.0
    @State private var showMoreMenu = false
    @State private var showReportConfirm = false
    @State private var showBlockConfirm = false
    @State private var showMuteConfirm = false

    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    likeScale = 1.35
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation { likeScale = 1.0 }
                }
                onLike()
            }) {
                Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .foregroundColor(.verdetp)
                    .scaleEffect(likeScale)
            }
            .frame(width: 56, height: 44)
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: onReply) {
                Image(systemName: "bubble.left")
                    .foregroundColor(.verdetp)
            }
            .frame(width: 56, height: 44)
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.verdetp)
            }
            .frame(width: 56, height: 44)
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: { showMoreMenu = true }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.verdetp)
            }
            .frame(width: 56, height: 44)
            .buttonStyle(PlainButtonStyle())
            .confirmationDialog("Opciones", isPresented: $showMoreMenu, titleVisibility: .hidden) {
                Button("Reportar") { showReportConfirm = true }
                Button("Bloquear perfil", role: .destructive) { showBlockConfirm = true }
                Button("Silenciar") { showMuteConfirm = true }
                Button("Cancelar", role: .cancel) {}
            }
            .alert("¿Reportar este comentario?", isPresented: $showReportConfirm) {
                Button("Cancelar", role: .cancel) {}
                Button("Reportar") { onReport() }
            } message: {
                Text("Se enviará un reporte a los administradores.")
            }
            .alert("¿Bloquear a @\(authorName)?", isPresented: $showBlockConfirm) {
                Button("Cancelar", role: .cancel) {}
                Button("Bloquear", role: .destructive) { onBlock() }
            } message: {
                Text("Ya no verás su contenido.")
            }
            .alert("¿Silenciar este comentario?", isPresented: $showMuteConfirm) {
                Button("Cancelar", role: .cancel) {}
                Button("Silenciar") { onMute() }
            } message: {
                Text("No aparecerá en tu feed.")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

// MARK: - Replies header (matches Android RespuestasHeader)

private struct RespuestasHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.verdetp)
                .frame(width: 4, height: 22)
                .clipShape(Capsule())

            Text("Respuestas más relevantes")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Reply card (matches Android ReplyCard)

struct ReplyCard: View {
    let reply: CommentInfo
    let onUserTap: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            CommentContentSection(comment: reply, onUserTap: onUserTap)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.pastel)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.bordeTuProfe, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 8)
    }
}

// MARK: - ViewModel (matches Android CommentDetalleViewModel)

@MainActor
class CommentDetalleViewModel: ObservableObject {
    @Published var comment: CommentInfo? = nil
    @Published var replies: [CommentInfo] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var showReplySheet = false
    @Published var replyText = ""
    @Published var isSubmittingReply = false

    @Published var moderationFeedback: String? = nil
    @Published var navigateBack = false

    private let commentRepo = CommentRepository.shared
    private let userRepo = UserRepository.shared
    private let moderationRepo = ModerationRepository.shared
    private var currentUserId: String { AuthRepository.shared.currentUserId ?? "" }

    func cargarComment(commentId: String) {
        isLoading = true
        let userId = currentUserId
        Task {
            do {
                comment = try await commentRepo.getCommentById(commentId, currentUserId: userId.isEmpty ? nil : userId)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
        Task {
            do {
                replies = try await commentRepo.getReplies(parentId: commentId)
            } catch {
                print("Error cargando respuestas: \(error.localizedDescription)")
                replies = []
            }
        }
    }

    func toggleLike(commentId: String) {
        guard !currentUserId.isEmpty else { return }
        if let idx = replies.firstIndex(where: { $0.commentId == commentId }) {
            replies[idx].liked.toggle()
            replies[idx].likes += replies[idx].liked ? 1 : -1
        } else if comment?.commentId == commentId {
            comment?.liked.toggle()
            if let liked = comment?.liked {
                comment?.likes += liked ? 1 : -1
            }
        }
        Task {
            do {
                try await commentRepo.toggleLike(commentId: commentId, userId: currentUserId)
            } catch {
                // revert
                if let idx = replies.firstIndex(where: { $0.commentId == commentId }) {
                    replies[idx].liked.toggle()
                    replies[idx].likes += replies[idx].liked ? 1 : -1
                } else if comment?.commentId == commentId {
                    comment?.liked.toggle()
                    if let liked = comment?.liked {
                        comment?.likes += liked ? 1 : -1
                    }
                }
            }
        }
    }

    func reportComment(commentId: String) {
        let userId = currentUserId
        Task {
            do {
                try await moderationRepo.report(reporterId: userId, targetId: commentId, targetType: "comment")
                moderationFeedback = "Comentario reportado"
            } catch {
                moderationFeedback = "Error al procesar la solicitud"
            }
        }
    }

    func blockUser(userId blockedId: String) {
        let userId = currentUserId
        Task {
            do {
                try await moderationRepo.blockUser(blockerId: userId, blockedId: blockedId)
                navigateBack = true
            } catch {
                moderationFeedback = "Error al procesar la solicitud"
            }
        }
    }

    func muteComment(commentId: String) {
        let userId = currentUserId
        Task {
            do {
                try await moderationRepo.mute(userId: userId, targetId: commentId, targetType: "comment")
                navigateBack = true
            } catch {
                moderationFeedback = "Error al procesar la solicitud"
            }
        }
    }

    func clearModerationFeedback() { moderationFeedback = nil }

    func openReplySheet() {
        replyText = ""
        showReplySheet = true
    }

    func closeReplySheet() {
        showReplySheet = false
        replyText = ""
    }

    func submitReply(commentId: String) {
        guard !replyText.trimmingCharacters(in: .whitespaces).isEmpty,
              !isSubmittingReply,
              let parentComment = comment else { return }

        isSubmittingReply = true
        let content = replyText.trimmingCharacters(in: .whitespaces)
        let userId = currentUserId
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        Task {
            let currentUser = try? await userRepo.getUserById(userId, currentUserId: userId)
            let dto = CreateCommentDto(
                reviewId: parentComment.reviewId,
                parentCommentId: commentId,
                userId: userId,
                content: content,
                createdAt: fmt.string(from: Date()),
                user: UserDto(id: userId, username: currentUser?.nombreUsu, foto: currentUser?.imageprofeUrl, perfilAnonimo: currentUser?.perfilAnonimo)
            )
            do {
                let newReply = try await commentRepo.createComment(dto)
                replies.append(newReply)
                comment?.repliesCount += 1
                showReplySheet = false
                replyText = ""
            } catch {
                print("Error submitting reply: \(error)")
            }
            isSubmittingReply = false
        }
    }
}