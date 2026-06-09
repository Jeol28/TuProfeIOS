import Foundation

struct ReviewInfo: Identifiable, Equatable {
    let id: String
    var reviewId: String { id }
    let usuario: Usuario
    let profesor: Profesor
    let materia: Materia
    let content: String
    let rating: Int
    let time: String
    var likes: Int
    var commentsCount: Int
    var liked: Bool
    var editado: Bool
    let latitude: Double?
    let longitude: Double?
    var imageUrls: [String]

    static func == (lhs: ReviewInfo, rhs: ReviewInfo) -> Bool {
        lhs.id == rhs.id &&
        lhs.liked == rhs.liked &&
        lhs.likes == rhs.likes &&
        lhs.commentsCount == rhs.commentsCount &&
        lhs.editado == rhs.editado
    }
}

struct ReviewMapMarker: Identifiable {
    let id: String
    var reviewId: String { id }
    let profesorNombre: String
    let rating: Int
    let latitude: Double
    let longitude: Double
    let materia: String
    let profesorFotoUrl: String?
    let authorUserId: String
}