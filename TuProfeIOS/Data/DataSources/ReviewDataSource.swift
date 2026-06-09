import Foundation

protocol ReviewDataSource {
    func getAllReviews() async throws -> [ReviewInfo]
    func listenAllReviews() -> AsyncStream<[ReviewInfo]>
    func getReviewById(_ id: String, currentUserId: String?) async throws -> ReviewInfo
    func getReviewsByProfessor(_ professorId: String) async throws -> [ReviewInfo]
    func getReviewsByUser(_ userId: String) async throws -> [ReviewInfo]
    func createReview(_ dto: CreateReviewDto) async throws -> ReviewInfo
    func updateReview(_ id: String, content: String, rating: Int, imageUrls: [String], latitude: Double?, longitude: Double?) async throws
    func deleteReview(_ id: String) async throws
    func toggleLike(reviewId: String, userId: String) async throws
    func getMapMarkers() async throws -> [ReviewMapMarker]
}
