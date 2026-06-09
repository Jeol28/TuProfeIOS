import Foundation

// MARK: - CommentAPIDataSource (equivalente a CommentRetrofitDataSourceImpl de Android)

final class CommentAPIDataSource: CommentDataSource {
    private let api = APIClient.shared

    private struct LikeBody: Encodable {
        let userId: String
    }

    private struct UpdateBody: Encodable {
        let content: String
    }

    func getCommentById(_ id: String, currentUserId: String?) async throws -> CommentInfo {
        var query: [String: String] = [:]
        if let uid = currentUserId, !uid.isEmpty { query["currentUserId"] = uid }
        let dto: CommentDto = try await api.get("/comments/\(id)", query: query)
        guard let info = dto.toCommentInfo() else { throw APIError.noData }
        return info
    }

    // GET reviews/{reviewId}/comments
    func getCommentsByReview(_ reviewId: String) async throws -> [CommentInfo] {
        let dtos: [CommentDto] = try await api.get("/reviews/\(reviewId)/comments")
        return dtos.compactMap { $0.toCommentInfo() }.sorted { $0.time < $1.time }
    }

    // GET comments/{id}/replies
    func getReplies(parentId: String) async throws -> [CommentInfo] {
        let dtos: [CommentDto] = try await api.get("/comments/\(parentId)/replies")
        return dtos.compactMap { $0.toCommentInfo() }.sorted { $0.time < $1.time }
    }

    // POST /comments → responde { "id": "..." } — igual que Android
    func createComment(_ dto: CreateCommentDto) async throws -> CommentInfo {
        let response: [String: String] = try await api.post("/comments", body: dto)
        guard let newId = response["id"], !newId.isEmpty else { throw APIError.noData }

        let userDto = dto.user ?? UserDto(id: dto.userId)
        return CommentInfo(
            id: newId,
            reviewId: dto.reviewId,
            parentCommentId: dto.parentCommentId,
            usuario: userDto.toUsuario(),
            content: dto.content,
            time: formatTuProfeDate(dto.createdAt),
            likes: 0,
            liked: false,
            repliesCount: 0,
            editado: false
        )
    }

    // PUT /comments/{id} con body { "content": "..." } — el servidor pone updatedAt
    func updateComment(_ id: String, content: String) async throws {
        try await api.put("/comments/\(id)", body: UpdateBody(content: content))
    }

    func deleteComment(_ id: String) async throws {
        try await api.delete("/comments/\(id)")
    }

    // POST /comments/{id}/like-toggle con body { "userId": "..." }
    func toggleLike(commentId: String, userId: String) async throws {
        try await api.postVoid("/comments/\(commentId)/like-toggle", body: LikeBody(userId: userId))
    }

    func getCommentsByUser(_ userId: String) async throws -> [CommentInfo] {
        let dtos: [CommentDto] = try await api.get("/users/\(userId)/comments")
        return dtos.compactMap { $0.toCommentInfo() }.sorted { $0.time > $1.time }
    }
}
