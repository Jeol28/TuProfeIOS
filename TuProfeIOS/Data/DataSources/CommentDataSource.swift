import Foundation

protocol CommentDataSource {
    func getCommentById(_ id: String, currentUserId: String?) async throws -> CommentInfo
    func getCommentsByReview(_ reviewId: String) async throws -> [CommentInfo]
    func getReplies(parentId: String) async throws -> [CommentInfo]
    func createComment(_ dto: CreateCommentDto) async throws -> CommentInfo
    func updateComment(_ id: String, content: String) async throws
    func deleteComment(_ id: String) async throws
    func toggleLike(commentId: String, userId: String) async throws
    func getCommentsByUser(_ userId: String) async throws -> [CommentInfo]
}
