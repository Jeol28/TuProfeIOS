import SwiftUI

// MARK: - DetalleView (matches Android DetalleScreen)

struct DetalleView: View {
    let reviewId: String
    @StateObject private var viewModel = DetalleViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            if viewModel.isLoading {
                ProgressView()
                    .tint(.verdetp)
            } else if let review = viewModel.selectedReview {
                ScrollView {
                    VStack(spacing: 0) {
                        DetalleReviewCard(
                            review: review,
                            isLiked: viewModel.selectedReview?.liked ?? false,
                            onLike: { viewModel.sendOrDeleteReviewLike(reviewId: reviewId) },
                            onComment: { viewModel.openCommentSheet() },
                            onShare: { shareReview(review) },
                            onProfessorTap: { navState.navigate(to: .profe(profeId: review.profesor.profeId)) },
                            onUserTap: { navState.navigate(to: .profile(userId: review.usuario.id)) },
                            onReport: { viewModel.reportReview(reviewId: reviewId, authorId: review.usuario.id) },
                            onBlock: { viewModel.blockUser(userId: review.usuario.id) },
                            onMute: { viewModel.muteReview(reviewId: reviewId) }
                        )
                        .padding(.top, 8)

                        Spacer().frame(height: 28)

                        // Comments header
                        CommentsHeaderView()
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)

                        // Comments list
                        if viewModel.isLoadingComments {
                            ProgressView()
                                .tint(.verdetp)
                                .padding()
                        } else {
                            ForEach(viewModel.comments) { comment in
                                CommentCardView(
                                    comment: comment,
                                    onUserTap: { navState.navigate(to: .profile(userId: comment.usuario.id)) },
                                    onTap: { navState.navigate(to: .commentDetalle(commentId: comment.commentId)) }
                                )
                                .padding(.horizontal, 20)
                            }
                        }

                        Spacer().frame(height: 110)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let error = viewModel.errorMessage {
                Text(LocalizedStringKey(error))
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .safeAreaInset(edge: .top) {
            TuProfeTopBarView()
        }
        .alert("Eliminar reseña", isPresented: $viewModel.showDeleteConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                viewModel.deleteReview(reviewId: reviewId) { navState.pop() }
            }
        } message: {
            Text("¿Estás seguro de que quieres eliminar esta reseña? Esta acción no se puede deshacer.")
        }
        .sheet(isPresented: $viewModel.showCommentSheet) {
            CommentComposeSheet(
                contextText: viewModel.selectedReview?.content ?? "",
                contextUser: viewModel.selectedReview?.usuario.nombreUsu ?? "",
                text: $viewModel.commentText,
                onDismiss: { viewModel.closeCommentSheet() },
                onSubmit: { viewModel.submitComment(reviewId: reviewId) },
                isSubmitting: viewModel.isSubmittingComment
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
        .onAppear { viewModel.cargarDetalle(reviewId: reviewId) }
    }

    private func shareReview(_ review: ReviewInfo) {
        let text = "Reseña de @\(review.usuario.nombreUsu) sobre \(review.profesor.nombreProfe) (\(review.materia.nombreMateria)) — \(review.rating)/5 ⭐\n\n\"\(review.content)\"\n\nVisto en TuProfe"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?
            .rootViewController?.present(av, animated: true)
    }
}

// MARK: - Detail review card: same look as main feed card + action bar inside

struct DetalleReviewCard: View {
    let review: ReviewInfo
    let isLiked: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    let onProfessorTap: () -> Void
    let onUserTap: () -> Void
    let onReport: () -> Void
    let onBlock: () -> Void
    let onMute: () -> Void

    @State private var likeScale: CGFloat = 1.0
    @State private var showMoreMenu = false
    @State private var showReportConfirm = false
    @State private var showBlockConfirm = false
    @State private var showMuteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeaderSection(review: review, onProfessorTap: onProfessorTap, onUserTap: onUserTap)

            StarRatingView(rating: Double(review.rating), starSize: 22)
                .padding(.leading, 2)

            CardBodySection(review: review)

            CardFooterSection(likes: review.likes, comments: review.commentsCount)

            Divider()

            HStack(spacing: 0) {
                Button(action: {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { likeScale = 1.35 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation { likeScale = 1.0 }
                    }
                    onLike()
                }) {
                    Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .foregroundColor(.verdetp)
                        .scaleEffect(likeScale)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }

                Divider().frame(height: 22)

                Button(action: onComment) {
                    Image(systemName: "bubble.left")
                        .foregroundColor(.verdetp)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }

                Divider().frame(height: 22)

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.verdetp)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }

                Divider().frame(height: 22)

                Button(action: { showMoreMenu = true }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.verdetp)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
                .confirmationDialog("Opciones", isPresented: $showMoreMenu, titleVisibility: .hidden) {
                    Button("Reportar") { showReportConfirm = true }
                    Button("Bloquear perfil", role: .destructive) { showBlockConfirm = true }
                    Button("Silenciar") { showMuteConfirm = true }
                    Button("Cancelar", role: .cancel) {}
                }
                .alert("¿Reportar esta reseña?", isPresented: $showReportConfirm) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Reportar") { onReport() }
                } message: {
                    Text("Se enviará un reporte a los administradores.")
                }
                .alert("¿Bloquear a @\(review.usuario.nombreUsu)?", isPresented: $showBlockConfirm) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Bloquear", role: .destructive) { onBlock() }
                } message: {
                    Text("Ya no verás su contenido.")
                }
                .alert("¿Silenciar esta reseña?", isPresented: $showMuteConfirm) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Silenciar") { onMute() }
                } message: {
                    Text("No aparecerá en tu feed.")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 2.5)
        )
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 18)
        .padding(.vertical, 5)
    }
}

// MARK: - Comments header (matches Android CommentsHeader)

struct CommentsHeaderView: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.verdetp)
                .frame(width: 4, height: 22)
                .clipShape(Capsule())

            Text("Comentarios más relevantes")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Comment compose sheet (matches Android CommentComposeSheet)

struct CommentComposeSheet: View {
    let contextText: String
    let contextUser: String
    @Binding var text: String
    let onDismiss: () -> Void
    let onSubmit: () -> Void
    let isSubmitting: Bool
    var submitLabel: LocalizedStringKey = "COMENTAR"

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Context preview
                if !contextText.isEmpty {
                    HStack {
                        Rectangle()
                            .fill(Color.verdetp.opacity(0.6))
                            .frame(width: 3)
                            .clipShape(Capsule())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("@\(contextUser)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.verdetp)
                            Text(contextText)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                AppTextEditor(
                    placeholder: "Escribe tu comentario...",
                    text: $text
                )

                AppButton(
                    title: submitLabel,
                    action: onSubmit,
                    isEnabled: !text.isEmpty && !isSubmitting,
                    isLoading: isSubmitting
                )

                Spacer()
            }
            .padding(.top, 8)
            .navigationTitle("Agregar comentario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: onDismiss)
                        .foregroundColor(.verdetp)
                }
            }
        }
    }
}

#Preview {
    DetalleView(reviewId: "test123")
        .environmentObject(NavigationState())
}