import Foundation

struct Usuario: Identifiable, Equatable {
    let id: String
    var usuarioId: String { id }
    let nombreUsu: String
    let email: String
    let carrera: String
    let imageprofeUrl: String?
    var followingCount: Int
    var followersCount: Int
    var followed: Bool
    let perfilAnonimo: Bool
    let perfilPublico: Bool
    let resenasEnPerfil: Bool
    let subscriptionActive: Bool
    let subscriptionEnd: Date?

    var subscriptionDaysLeft: Int? {
        guard let end = subscriptionEnd else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        return max(0, days)
    }

    static func == (lhs: Usuario, rhs: Usuario) -> Bool {
        lhs.id == rhs.id
    }
}