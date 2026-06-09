import SwiftUI

enum HistorialFilter: String, CaseIterable {
    case todo = "Todo"
    case resenas = "Reseñas"
    case comentarios = "Comentarios"
}

// MARK: - HistorialView (matches Android HistorialScreen)

struct HistorialView: View {
    @StateObject private var viewModel = HistorialViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    TitleHeader(title: "Mi historial")
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // Filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(HistorialFilter.allCases, id: \.self) { filter in
                                FilterPill(
                                    title: filter.rawValue,
                                    isSelected: viewModel.selectedFilter == filter,
                                    action: { viewModel.setFilter(filter) }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                    }
                }
                .background(Color.pastel.opacity(0.95))

                if viewModel.isLoading {
                    ReviewListSkeleton(count: 4)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.filteredItems.enumerated()), id: \.offset) { index, item in
                                switch item {
                                case .review(let review):
                                    HistorialReviewCard(
                                        review: review,
                                        onView: { navState.navigate(to: .detalle(reviewId: review.reviewId)) },
                                        onEdit: { navState.navigate(to: .editReview(reviewId: review.reviewId)) },
                                        onDelete: { viewModel.deleteReview(review) },
                                        onProfessorTap: { navState.navigate(to: .profe(profeId: review.profesor.profeId)) },
                                        onUserTap: { navState.navigate(to: .profile(userId: review.usuario.id)) }
                                    )
                                    .animatedListItem(index: index)

                                case .comment(let comment):
                                    HistorialCommentCard(
                                        comment: comment,
                                        onView: { navState.navigate(to: .commentDetalle(commentId: comment.commentId)) },
                                        onEdit: { navState.navigate(to: .editComment(commentId: comment.commentId)) },
                                        onDelete: { viewModel.deleteComment(comment) }
                                    )
                                    .animatedListItem(index: index)
                                }
                            }
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 110)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            TuProfeTopBarView()
        }
        .onAppear { viewModel.cargarHistorial() }
    }
}

// MARK: - Filter pill (matches Android filter chips)

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .verdetp)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.verdetp : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.verdetp, lineWidth: 1.5)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Historial review card with edit/delete

struct HistorialReviewCard: View {
    let review: ReviewInfo
    let onView: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onProfessorTap: () -> Void
    var onUserTap: (() -> Void)? = nil

    @State private var showDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            ReviewCardView(
                review: review,
                onTap: onView,
                onProfessorTap: onProfessorTap,
                onUserTap: onUserTap
            )

            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Label("Editar", systemImage: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.verdetp)
                }

                Spacer()

                Button(action: { showDeleteAlert = true }) {
                    Label("Eliminar", systemImage: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .alert("¿Eliminar reseña?", isPresented: $showDeleteAlert) {
            Button("Eliminar", role: .destructive, action: onDelete)
            Button("Cancelar", role: .cancel) {}
        }
    }
}

// MARK: - Historial comment card

struct HistorialCommentCard: View {
    let comment: CommentInfo
    let onView: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            CommentCardView(comment: comment, onTap: onView)
                .padding(.horizontal, 20)
                .padding(.top, 4)

            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Label("Editar", systemImage: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.verdetp)
                }
                Spacer()
                Button(action: { showDeleteAlert = true }) {
                    Label("Eliminar", systemImage: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .alert("¿Eliminar comentario?", isPresented: $showDeleteAlert) {
            Button("Eliminar", role: .destructive, action: onDelete)
            Button("Cancelar", role: .cancel) {}
        }
    }
}

// MARK: - HistorialViewModel

@MainActor
class HistorialViewModel: ObservableObject {
    enum HistorialItem {
        case review(ReviewInfo)
        case comment(CommentInfo)
    }

    @Published var userReviews: [ReviewInfo] = []
    @Published var userComments: [CommentInfo] = []
    @Published var selectedFilter: HistorialFilter = .todo
    @Published var isLoading = false

    var filteredItems: [HistorialItem] {
        switch selectedFilter {
        case .todo:
            let reviews = userReviews.map { HistorialItem.review($0) }
            let comments = userComments.map { HistorialItem.comment($0) }
            return reviews + comments
        case .resenas:
            return userReviews.map { .review($0) }
        case .comentarios:
            return userComments.map { .comment($0) }
        }
    }

    private let reviewRepo = ReviewRepository.shared
    private let commentRepo = CommentRepository.shared

    func cargarHistorial() {
        guard let userId = AuthRepository.shared.currentUserId else { return }
        isLoading = true
        Task {
            do {
                userReviews = try await reviewRepo.getReviewsByUser(userId)
            } catch {
                print("Error cargando reseñas: \(error.localizedDescription)")
            }
            isLoading = false
        }
        Task {
            do {
                userComments = try await commentRepo.getCommentsByUser(userId)
            } catch {
                print("Error cargando comentarios: \(error.localizedDescription)")
            }
        }
    }

    func setFilter(_ filter: HistorialFilter) {
        selectedFilter = filter
    }

    func deleteReview(_ review: ReviewInfo) {
        Task {
            try? await reviewRepo.deleteReview(review.reviewId)
            userReviews.removeAll { $0.id == review.id }
        }
    }

    func deleteComment(_ comment: CommentInfo) {
        Task {
            try? await commentRepo.deleteComment(comment.commentId)
            userComments.removeAll { $0.id == comment.id }
        }
    }
}