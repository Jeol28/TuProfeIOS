import Foundation

protocol ProfessorDataSource {
    func getAllProfessors() async throws -> [Profesor]
    func getProfessorById(_ id: String) async throws -> Profesor
    func getAverageRating(for professorId: String) async throws -> Float
}
