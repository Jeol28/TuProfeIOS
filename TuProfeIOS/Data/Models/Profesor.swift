import Foundation

struct Profesor: Identifiable, Equatable, Hashable {
    let id: String
    var profeId: String { id }
    let nombreProfe: String
    let imageprofeUrl: String?
    let departamento: String
    let materias: [String]

    static func == (lhs: Profesor, rhs: Profesor) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}