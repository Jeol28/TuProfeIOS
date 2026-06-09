import Foundation

// MARK: - ProfessorRepository

class ProfessorRepository {
    static let shared = ProfessorRepository()
    private let dataSource: any ProfessorDataSource = makeProfessorDataSource()

    func getAllProfessors() async throws -> [Profesor] {
        try await dataSource.getAllProfessors()
    }

    func getProfessorById(_ id: String) async throws -> Profesor {
        try await dataSource.getProfessorById(id)
    }

    func getAverageRating(for professorId: String) async throws -> Float {
        try await dataSource.getAverageRating(for: professorId)
    }
}
