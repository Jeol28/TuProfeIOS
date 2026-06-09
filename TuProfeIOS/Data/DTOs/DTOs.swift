import Foundation

// MARK: - UserDto

struct UserDto: Codable {
    let id: String
    var name: String?
    var username: String?
    var email: String?
    var carrera: String?
    var foto: String?
    var followingCount: Int?
    var followersCount: Int?
    var followed: Bool?
    var perfilAnonimo: Bool?
    var perfilPublico: Bool?
    var resenasEnPerfil: Bool?
    var subscriptionActive: Bool?
    var subscriptionEnd: String?

    func toUsuario() -> Usuario {
        let subEnd: Date? = subscriptionEnd.flatMap {
            ISO8601DateFormatter().date(from: $0)
        }
        return Usuario(
            id: id,
            nombreUsu: username ?? name ?? "Usuario",
            email: email ?? "",
            carrera: carrera ?? "",
            imageprofeUrl: foto,
            followingCount: followingCount ?? 0,
            followersCount: followersCount ?? 0,
            followed: followed ?? false,
            perfilAnonimo: perfilAnonimo ?? false,
            perfilPublico: perfilPublico ?? true,
            resenasEnPerfil: resenasEnPerfil ?? true,
            subscriptionActive: subscriptionActive ?? false,
            subscriptionEnd: subEnd
        )
    }
}

// MARK: - ProfessorDto

struct ProfessorDto: Codable {
    let id: String
    let name: String
    let department: String?
    let subjects: [String]?
    let foto: String?
    let createdAt: String?
    let updatedAt: String?

    func toProfesor() -> Profesor {
        Profesor(
            id: id,
            nombreProfe: name,
            imageprofeUrl: foto,
            departamento: department ?? "",
            materias: subjects ?? []
        )
    }
}

// MARK: - ProfessorNameDto (embedded in ReviewDto)

struct ProfessorNameDto: Codable {
    let id: String?
    let name: String?
    let foto: String?
    let department: String?
}

// MARK: - ReviewDto

struct ReviewDto: Codable {
    let id: String?
    let userId: String?
    let professorId: String?
    let content: String?
    let time: String?
    let rating: Int?
    let comment: Int?
    let createdAt: String?
    let updatedAt: String?
    let materia: String?
    let professor: ProfessorNameDto?
    let user: UserDto?
    var likesCount: Int
    var liked: Bool?
    let latitude: Double?
    let longitude: Double?
    let imageUrls: [String]?

    func toReviewInfo() -> ReviewInfo? {
        guard let id = id else { return nil }
        let professorId = professor?.id ?? professorId ?? ""
        let prof = Profesor(
            id: professorId,
            nombreProfe: professor?.name ?? "Profesor",
            imageprofeUrl: professor?.foto,
            departamento: professor?.department ?? "",
            materias: []
        )

        let userDto = user ?? UserDto(id: userId ?? "")
        let mat = Materia(id: materia ?? "", nombreMateria: materia ?? "")

        return ReviewInfo(
            id: id,
            usuario: userDto.toUsuario(),
            profesor: prof,
            materia: mat,
            content: content ?? "",
            rating: rating ?? 0,
            time: formatTuProfeDate(time ?? createdAt),
            likes: likesCount,
            commentsCount: comment ?? 0,
            liked: liked ?? false,
            editado: !(updatedAt ?? "").isEmpty,
            latitude: latitude,
            longitude: longitude,
            imageUrls: imageUrls ?? []
        )
    }

    func toReviewMapMarker() -> ReviewMapMarker? {
        guard let id = id,
              let lat = latitude,
              let lng = longitude else { return nil }
        return ReviewMapMarker(
            id: id,
            profesorNombre: professor?.name ?? "Profesor",
            rating: rating ?? 0,
            latitude: lat,
            longitude: lng,
            materia: materia ?? "",
            profesorFotoUrl: professor?.foto,
            authorUserId: user?.id ?? userId ?? ""
        )
    }
}

// MARK: - CommentDto

struct CommentDto: Codable {
    let id: String?
    let reviewId: String?
    let parentCommentId: String?
    let userId: String?
    let content: String?
    let createdAt: String?
    let updatedAt: String?
    var likesCount: Int
    var liked: Bool?
    var repliesCount: Int?
    let user: UserDto?

    func toCommentInfo() -> CommentInfo? {
        guard let id = id else { return nil }
        let userDto = user ?? UserDto(id: userId ?? "")
        return CommentInfo(
            id: id,
            reviewId: reviewId ?? "",
            parentCommentId: parentCommentId,
            usuario: userDto.toUsuario(),
            content: content ?? "",
            time: formatTuProfeDate(createdAt ?? updatedAt),
            likes: likesCount,
            liked: liked ?? false,
            repliesCount: repliesCount ?? 0,
            editado: !(updatedAt ?? "").isEmpty
        )
    }
}

// MARK: - CreateReviewDto

struct CreateReviewDto: Codable {
    var userId: String?
    let professorId: String?
    let content: String?
    let rating: Int?
    let time: String?
    let materia: String?
    let latitude: Double?
    let longitude: Double?
    var user: CreateReviewUserDto?
    let professor: CreateReviewProfessorDto?
    var imageUrls: [String]?
}

struct CreateReviewUserDto: Codable {
    let id: String
    let username: String
    let foto: String?
}

struct CreateReviewProfessorDto: Codable {
    let id: String
    let name: String
    let foto: String?
}

// MARK: - CreateCommentDto

struct CreateCommentDto: Codable {
    let reviewId: String
    let parentCommentId: String?
    let userId: String
    let content: String
    let createdAt: String
    let user: UserDto?
}

// MARK: - RegisterUserDto (Firestore)

struct RegisterUserDto: Codable {
    let id: String
    let username: String
    let carrera: String
    var FCMToken: String?
    let email: String
    let perfilAnonimo: Bool
    let perfilPublico: Bool
    let resenasEnPerfil: Bool
}