import Foundation

// MARK: - Date formatter (global — usado también por CommentRepository)

func formatTuProfeDate(_ raw: String?) -> String {
    guard let raw, !raw.isEmpty else { return "" }
    let input = ISO8601DateFormatter()
    input.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = input.date(from: raw) {
        let output = DateFormatter()
        output.locale = Locale(identifier: "es")
        output.dateFormat = "d 'de' MMMM 'de' yyyy"
        return output.string(from: date)
    }
    let inputFallback = ISO8601DateFormatter()
    inputFallback.formatOptions = [.withInternetDateTime]
    if let date = inputFallback.date(from: raw) {
        let output = DateFormatter()
        output.locale = Locale(identifier: "es")
        output.dateFormat = "d 'de' MMMM 'de' yyyy"
        return output.string(from: date)
    }
    return raw
}

// MARK: - ReviewRepository

class ReviewRepository {
    static let shared = ReviewRepository()
    private let dataSource: any ReviewDataSource = makeReviewDataSource()

    func getAllReviews() async throws -> [ReviewInfo] {
        try await dataSource.getAllReviews()
    }

    func listenAllReviews() -> AsyncStream<[ReviewInfo]> {
        dataSource.listenAllReviews()
    }

    func getReviewById(_ id: String, currentUserId: String? = nil) async throws -> ReviewInfo {
        try await dataSource.getReviewById(id, currentUserId: currentUserId)
    }

    func getReviewsByProfessor(_ professorId: String) async throws -> [ReviewInfo] {
        try await dataSource.getReviewsByProfessor(professorId)
    }

    func getReviewsByUser(_ userId: String) async throws -> [ReviewInfo] {
        try await dataSource.getReviewsByUser(userId)
    }

    func createReview(_ dto: CreateReviewDto) async throws -> ReviewInfo {
        try await dataSource.createReview(dto)
    }

    func updateReview(_ id: String, content: String, rating: Int, imageUrls: [String] = [], latitude: Double? = nil, longitude: Double? = nil) async throws {
        try await dataSource.updateReview(id, content: content, rating: rating, imageUrls: imageUrls, latitude: latitude, longitude: longitude)
    }

    func deleteReview(_ id: String) async throws {
        try await dataSource.deleteReview(id)
    }

    func toggleLike(reviewId: String, userId: String) async throws {
        try await dataSource.toggleLike(reviewId: reviewId, userId: userId)
    }

    func getMapMarkers() async throws -> [ReviewMapMarker] {
        try await dataSource.getMapMarkers()
    }
}
