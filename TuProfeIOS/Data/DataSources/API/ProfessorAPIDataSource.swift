import Foundation

// MARK: - ProfessorAPIDataSource (equivalente a ProfessorRemoteDataSourceImpl de Android)
// Nota: la API Express usa IDs enteros para profesores; Firestore usa strings.

final class ProfessorAPIDataSource: ProfessorDataSource {

    // La API devuelve IDs enteros — usamos este DTO internamente
    private struct ProfessorAPIDto: Decodable {
        let id: Int
        let name: String
        let department: String?
        let subjects: [String]?
        let foto: String?
        let fotoProf: String?

        func toProfesor() -> Profesor {
            Profesor(
                id: String(id),
                nombreProfe: name,
                imageprofeUrl: fotoProf ?? foto,
                departamento: department ?? "",
                materias: subjects ?? []
            )
        }
    }

    private let api = APIClient.shared

    func getAllProfessors() async throws -> [Profesor] {
        let dtos: [ProfessorAPIDto] = try await api.get("/professors")
        return dtos.map { $0.toProfesor() }
    }

    func getProfessorById(_ id: String) async throws -> Profesor {
        let intId = Int(id) ?? 0
        let dto: ProfessorAPIDto = try await api.get("/professors/\(intId)")
        return dto.toProfesor()
    }

    func getAverageRating(for professorId: String) async throws -> Float {
        let reviews = try await ReviewAPIDataSource().getReviewsByProfessor(professorId)
        guard !reviews.isEmpty else { return 0 }
        return Float(reviews.map { $0.rating }.reduce(0, +)) / Float(reviews.count)
    }
}
