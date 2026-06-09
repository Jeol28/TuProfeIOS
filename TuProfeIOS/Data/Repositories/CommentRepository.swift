import Foundation

// MARK: - CommentRepository

class CommentRepository {
    static let shared = CommentRepository()
    private let dataSource: any CommentDataSource = makeCommentDataSource()

    func getCommentById(_ id: String, currentUserId: String? = nil) async throws -> CommentInfo {
        try await dataSource.getCommentById(id, currentUserId: currentUserId)
    }

    func getCommentsByReview(_ reviewId: String) async throws -> [CommentInfo] {
        try await dataSource.getCommentsByReview(reviewId)
    }

    func getReplies(parentId: String) async throws -> [CommentInfo] {
        try await dataSource.getReplies(parentId: parentId)
    }

    func createComment(_ dto: CreateCommentDto) async throws -> CommentInfo {
        try await dataSource.createComment(dto)
    }

    func updateComment(_ id: String, content: String) async throws {
        try await dataSource.updateComment(id, content: content)
    }

    func deleteComment(_ id: String) async throws {
        try await dataSource.deleteComment(id)
    }

    func toggleLike(commentId: String, userId: String) async throws {
        try await dataSource.toggleLike(commentId: commentId, userId: userId)
    }

    func getCommentsByUser(_ userId: String) async throws -> [CommentInfo] {
        try await dataSource.getCommentsByUser(userId)
    }
}
