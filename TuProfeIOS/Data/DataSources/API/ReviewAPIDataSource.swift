import Foundation

// MARK: - ReviewAPIDataSource (equivalente a ReviewRetrofitDataSourceImpl de Android)

final class ReviewAPIDataSource: ReviewDataSource {
    private let api = APIClient.shared

    private struct UpdateReviewBody: Encodable {
        let content: String
        let rating: Int
        let updatedAt: String
        let imageUrls: [String]
        let latitude: Double?
        let longitude: Double?
    }

    private struct LikeBody: Encodable {
        let userId: String
    }

    func getAllReviews() async throws -> [ReviewInfo] {
        let dtos: [ReviewDto] = try await api.get("/reviews")
        return dtos.compactMap { $0.toReviewInfo() }
    }

    // Express no tiene soporte real-time — emite una vez (igual que Android)
    func listenAllReviews() -> AsyncStream<[ReviewInfo]> {
        AsyncStream { continuation in
            Task {
                if let reviews = try? await getAllReviews() {
                    continuation.yield(reviews)
                }
                continuation.finish()
            }
        }
    }

    func getReviewById(_ id: String, currentUserId: String?) async throws -> ReviewInfo {
        var query: [String: String] = [:]
        if let uid = currentUserId { query["currentUserId"] = uid }
        let dto: ReviewDto = try await api.get("/reviews/\(id)", query: query)
        guard let info = dto.toReviewInfo() else { throw APIError.noData }
        return info
    }

    // No existe endpoint directo — filtra desde todos (mismo enfoque que Android en markers)
    func getReviewsByProfessor(_ professorId: String) async throws -> [ReviewInfo] {
        let all: [ReviewDto] = try await api.get("/reviews")
        return all
            .filter { ($0.professor?.id ?? $0.professorId) == professorId }
            .compactMap { $0.toReviewInfo() }
            .sorted { $0.time > $1.time }
    }

    func getReviewsByUser(_ userId: String) async throws -> [ReviewInfo] {
        let dtos: [ReviewDto] = try await api.get("/users/\(userId)/reviews")
        return dtos.compactMap { $0.toReviewInfo() }.sorted { $0.time > $1.time }
    }

    func createReview(_ dto: CreateReviewDto) async throws -> ReviewInfo {
        let result: ReviewDto = try await api.post("/reviews", body: dto)
        guard let info = result.toReviewInfo() else { throw APIError.noData }
        return info
    }

    func updateReview(_ id: String, content: String, rating: Int, imageUrls: [String], latitude: Double?, longitude: Double?) async throws {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let body = UpdateReviewBody(content: content, rating: rating, updatedAt: fmt.string(from: Date()), imageUrls: imageUrls, latitude: latitude, longitude: longitude)
        try await api.put("/reviews/\(id)", body: body)
    }

    func deleteReview(_ id: String) async throws {
        try await api.delete("/reviews/\(id)")
    }

    func toggleLike(reviewId: String, userId: String) async throws {
        try await api.postVoid("/reviews/\(reviewId)/like-toggle", body: LikeBody(userId: userId))
    }

    func getMapMarkers() async throws -> [ReviewMapMarker] {
        let dtos: [ReviewDto] = try await api.get("/reviews")
        return dtos.compactMap { $0.toReviewMapMarker() }
    }
}
