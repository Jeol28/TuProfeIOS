import Foundation

@MainActor
class DetalleViewModel: ObservableObject {
    @Published var selectedReview: ReviewInfo? = nil
    @Published var comments: [CommentInfo] = []
    @Published var isLoading = false
    @Published var isLoadingComments = false
    @Published var errorMessage: String? = nil
    @Published var showCommentSheet = false
    @Published var commentText = ""
    @Published var isSubmittingComment = false
    @Published var showDeleteConfirm = false
    @Published var moderationFeedback: String? = nil
    @Published var navigateBack = false

    var currentUserId: String { AuthRepository.shared.currentUserId ?? "" }

    var isOwnReview: Bool {
        guard !currentUserId.isEmpty, let review = selectedReview else { return false }
        return review.usuario.id == currentUserId
    }

    private let reviewRepo = ReviewRepository.shared
    private let commentRepo = CommentRepository.shared
    private let userRepo = UserRepository.shared
    private let moderationRepo = ModerationRepository.shared

    func cargarDetalle(reviewId: String) {
        isLoading = true
        isLoadingComments = true
        Task {
            do {
                let review = try await reviewRepo.getReviewById(
                    reviewId,
                    currentUserId: currentUserId.isEmpty ? nil : currentUserId
                )
                selectedReview = review
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
        Task {
            do {
                comments = try await commentRepo.getCommentsByReview(reviewId)
            } catch {
                print("Error cargando comentarios: \(error.localizedDescription)")
                comments = []
            }
            isLoadingComments = false
        }
    }

    func sendOrDeleteReviewLike(reviewId: String) {
        guard !currentUserId.isEmpty else { return }
        // Optimistic update
        selectedReview?.liked.toggle()
        let isNowLiked = selectedReview?.liked ?? false
        selectedReview?.likes += isNowLiked ? 1 : -1

        Task {
            do {
                try await reviewRepo.toggleLike(reviewId: reviewId, userId: currentUserId)
            } catch {
                // Revert
                selectedReview?.liked.toggle()
                let revertLiked = selectedReview?.liked ?? false
                selectedReview?.likes += revertLiked ? 1 : -1
            }
        }
    }

    func deleteReview(reviewId: String, onSuccess: @escaping () -> Void) {
        Task {
            do {
                try await reviewRepo.deleteReview(reviewId)
                onSuccess()
            } catch {
                errorMessage = "Error al eliminar la reseña"
            }
        }
    }

    func reportReview(reviewId: String, authorId: String) {
        let userId = currentUserId
        Task {
            do {
                try await moderationRepo.report(reporterId: userId, targetId: reviewId, targetType: "review")
                moderationFeedback = "Reseña reportada"
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

    func muteReview(reviewId: String) {
        let userId = currentUserId
        Task {
            do {
                try await moderationRepo.mute(userId: userId, targetId: reviewId, targetType: "review")
                navigateBack = true
            } catch {
                moderationFeedback = "Error al procesar la solicitud"
            }
        }
    }

    func clearModerationFeedback() { moderationFeedback = nil }

    func openCommentSheet() { showCommentSheet = true }
    func closeCommentSheet() { showCommentSheet = false; commentText = "" }

    func onCommentTextChange(_ text: String) { commentText = text }

    func submitComment(reviewId: String) {
        guard !commentText.isEmpty else { return }
        isSubmittingComment = true
        let userId = currentUserId
        Task {
            let currentUser = try? await userRepo.getUserById(userId, currentUserId: userId)
            let dto = CreateCommentDto(
                reviewId: reviewId,
                parentCommentId: nil,
                userId: userId,
                content: commentText,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                user: UserDto(id: userId, username: currentUser?.nombreUsu, foto: currentUser?.imageprofeUrl, perfilAnonimo: currentUser?.perfilAnonimo)
            )
            do {
                let newComment = try await commentRepo.createComment(dto)
                comments.insert(newComment, at: 0)
                selectedReview?.commentsCount += 1
                closeCommentSheet()
            } catch {
                print("Error al comentar: \(error)")
            }
            isSubmittingComment = false
        }
    }
}