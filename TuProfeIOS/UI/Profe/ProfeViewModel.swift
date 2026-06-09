import Foundation

@MainActor
class ProfeViewModel: ObservableObject {
    @Published var profesor: Profesor? = nil
    @Published var professorReviews: [ReviewInfo] = []
    @Published var averageRating: Float = 0
    @Published var isLoading = false
    @Published var resumenIA: String? = nil
    @Published var isLoadingIA = false
    @Published var errorIA: String? = nil

    private let professorRepo = ProfessorRepository.shared
    private let reviewRepo = ReviewRepository.shared
    private let aiService = GroqAIService.shared

    func cargarDatos(profeId: String) {
        isLoading = true
        Task {
            async let prof = professorRepo.getProfessorById(profeId)
            async let reviews = reviewRepo.getReviewsByProfessor(profeId)
            async let rating = professorRepo.getAverageRating(for: profeId)

            do {
                let (p, r, avg) = try await (prof, reviews, rating)
                profesor = p
                professorReviews = r.applyModerationFilter()
                averageRating = avg
            } catch {
                print("Error cargando profesor: \(error)")
            }
            isLoading = false
        }
    }

    func toggleLike(reviewId: String) {
        guard let userId = AuthRepository.shared.currentUserId, !userId.isEmpty else { return }
        if let idx = professorReviews.firstIndex(where: { $0.id == reviewId }) {
            professorReviews[idx].liked.toggle()
            professorReviews[idx].likes += professorReviews[idx].liked ? 1 : -1
        }
        Task {
            do {
                try await reviewRepo.toggleLike(reviewId: reviewId, userId: userId)
            } catch {
                if let idx = professorReviews.firstIndex(where: { $0.id == reviewId }) {
                    professorReviews[idx].liked.toggle()
                    professorReviews[idx].likes += professorReviews[idx].liked ? 1 : -1
                }
            }
        }
    }

    func generarResumenIA() {
        guard !professorReviews.isEmpty else {
            errorIA = "No hay reseñas para generar un resumen"
            return
        }
        isLoadingIA = true
        errorIA = nil
        Task {
            do {
                let resumen = try await aiService.generateReviewSummary(reviews: professorReviews)
                resumenIA = resumen
            } catch {
                errorIA = "Error al generar resumen"
            }
            isLoadingIA = false
        }
    }
}