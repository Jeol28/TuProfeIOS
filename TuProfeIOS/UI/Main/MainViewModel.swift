import Foundation
import Combine

enum SortOrder: String, CaseIterable {
    case recientes = "Recientes"
    case mejorCalificadas = "Mejor calificadas"
    case masGustadas = "Más gustadas"
}

@MainActor
class MainViewModel: ObservableObject {
    @Published var reviews: [ReviewInfo] = []
    @Published var followingIds: Set<String> = []
    @Published var selectedTab = 0
    @Published var sortOrder: SortOrder = .recientes
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let reviewRepo = ReviewRepository.shared
    private let userRepo = UserRepository.shared
    private let moderationRepo = ModerationRepository.shared
    private var listenerTask: Task<Void, Never>?
    private var moderationObserver: NSObjectProtocol?

    // MARK: - Start real-time listener (matches Android getReviewsLive)

    func startListening() {
        guard listenerTask == nil else { return }
        isLoading = true

        if let userId = AuthRepository.shared.currentUserId, !userId.isEmpty {
            Task { await moderationRepo.loadCacheForUser(userId: userId) }
        }

        moderationObserver = NotificationCenter.default.addObserver(
            forName: .moderationUpdated, object: nil, queue: .main
        ) { [weak self] _ in
            self?.applyModerationFilter()
        }

        listenerTask = Task {
            for await updatedReviews in reviewRepo.listenAllReviews() {
                self.reviews = updatedReviews.applyModerationFilter()
                self.isLoading = false
            }
        }
        loadFollowingIds()
    }

    private func applyModerationFilter() {
        reviews = reviews.applyModerationFilter()
    }

    func stopListening() {
        listenerTask?.cancel()
        listenerTask = nil
    }

    // Called by MainView .onAppear
    func fetchReviews() {
        startListening()
    }

    func toggleLike(reviewId: String) {
        guard let userId = AuthRepository.shared.currentUserId, !userId.isEmpty else { return }
        if let idx = reviews.firstIndex(where: { $0.id == reviewId }) {
            reviews[idx].liked.toggle()
            reviews[idx].likes += reviews[idx].liked ? 1 : -1
        }
        Task {
            do {
                try await reviewRepo.toggleLike(reviewId: reviewId, userId: userId)
            } catch {
                // Revert on failure
                if let idx = reviews.firstIndex(where: { $0.id == reviewId }) {
                    reviews[idx].liked.toggle()
                    reviews[idx].likes += reviews[idx].liked ? 1 : -1
                }
            }
        }
    }

    // MARK: - Following IDs

    private func loadFollowingIds() {
        guard let userId = AuthRepository.shared.currentUserId else { return }
        Task {
            let ids = (try? await userRepo.getFollowingIds(userId: userId)) ?? []
            self.followingIds = Set(ids)
        }
    }

    func refreshFollowingReviews() {
        loadFollowingIds()
    }

    // MARK: - Tab / sort

    func selectTab(_ index: Int) {
        selectedTab = index
        if index == 1 { refreshFollowingReviews() }
    }

    func setSortOrder(_ order: SortOrder) {
        sortOrder = order
    }

    // MARK: - Computed lists

    var followingReviews: [ReviewInfo] {
        reviews.filter { followingIds.contains($0.usuario.id) }
    }

    var currentList: [ReviewInfo] {
        let raw = selectedTab == 0 ? reviews : followingReviews
        switch sortOrder {
        case .recientes: return raw
        case .mejorCalificadas: return raw.sorted { $0.rating > $1.rating }
        case .masGustadas: return raw.sorted { $0.likes > $1.likes }
        }
    }
}