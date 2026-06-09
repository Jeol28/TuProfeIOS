import Foundation
import FirebaseFirestore

final class ProfessorFirestoreDataSource: ProfessorDataSource {
    private let db = Firestore.firestore()

    private func parseProfesor(_ doc: DocumentSnapshot) -> Profesor? {
        guard let data = doc.data(), let name = data["name"] as? String else { return nil }
        return Profesor(
            id: doc.documentID,
            nombreProfe: name,
            imageprofeUrl: data["foto_prof"] as? String ?? data["foto"] as? String,
            departamento: data["department"] as? String ?? "",
            materias: data["subjects"] as? [String] ?? []
        )
    }

    func getAllProfessors() async throws -> [Profesor] {
        let snapshot = try await db.collection("professors").getDocuments()
        return snapshot.documents.compactMap { parseProfesor($0) }
    }

    func getProfessorById(_ id: String) async throws -> Profesor {
        let doc = try await db.collection("professors").document(id).getDocument()
        guard let prof = parseProfesor(doc) else {
            throw NSError(domain: "ProfessorFirestoreDataSource", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Profesor no encontrado"])
        }
        return prof
    }

    func getAverageRating(for professorId: String) async throws -> Float {
        let snapshot = try await db.collection("reviews")
            .whereField("professorId", isEqualTo: professorId)
            .getDocuments()
        let ratings = snapshot.documents.compactMap { $0.data()["rating"] as? Int }
        guard !ratings.isEmpty else { return 0 }
        return Float(ratings.reduce(0, +)) / Float(ratings.count)
    }
}
