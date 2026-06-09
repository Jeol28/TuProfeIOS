import Foundation

struct Materia: Identifiable, Equatable {
    let id: String
    var materiaId: String { id }
    let nombreMateria: String
}