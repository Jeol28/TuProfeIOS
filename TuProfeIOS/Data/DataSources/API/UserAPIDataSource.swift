import Foundation

// MARK: - UserAPIDataSource (equivalente a UsuarioRemoteDataSourceImpl de Android)

final class UserAPIDataSource: UserDataSource {
    private let api = APIClient.shared

    private struct UpdateUserBody: Encodable {
        let username: String
        let email: String
        let carrera: String
    }

    private struct UpdatePhotoBody: Encodable {
        let foto: String
    }

    private struct RegisterUserBody: Encodable {
        let id: String
        let username: String
        let carrera: String
        let FCMToken: String
    }

    func getUserById(_ userId: String, currentUserId: String) async throws -> Usuario {
        let dto: UserDto = try await api.get(
            "/users/\(userId)",
            query: ["currentUserId": currentUserId]
        )
        return dto.toUsuario()
    }

    func registerUser(userId: String, username: String, email: String, carrera: String, fcmToken: String?) async throws {
        let body = RegisterUserBody(
            id: userId,
            username: username,
            carrera: carrera,
            FCMToken: fcmToken ?? ""
        )
        let _: UserDto = try await api.post("/users/register", body: body)
    }

    func updateUser(userId: String, username: String, email: String, carrera: String) async throws {
        try await api.put("/users/\(userId)", body: UpdateUserBody(username: username, email: email, carrera: carrera))
    }

    func updateUserPhoto(userId: String, photoURL: String) async throws {
        try await api.put("/users/\(userId)/photo", body: UpdatePhotoBody(foto: photoURL))
    }

    // API REST no soporta ajustes de privacidad (igual que Android)
    func updatePrivacySettings(userId: String, perfilAnonimo: Bool, perfilPublico: Bool, resenasEnPerfil: Bool) async throws {}

    func getFollowers(userId: String, currentUserId: String) async throws -> [Usuario] {
        let dtos: [UserDto] = try await api.get(
            "/users/\(userId)/followers",
            query: ["currentUserId": currentUserId]
        )
        return dtos.map { $0.toUsuario() }
    }

    func getFollowing(userId: String, currentUserId: String) async throws -> [Usuario] {
        let dtos: [UserDto] = try await api.get(
            "/users/\(userId)/following",
            query: ["currentUserId": currentUserId]
        )
        return dtos.map { $0.toUsuario() }
    }

    func followOrUnfollowUser(currentUserId: String, targetUserId: String) async throws {
        try await api.postVoid(
            "/users/\(targetUserId)/follow-toggle",
            query: ["followerId": currentUserId]
        )
    }

    func getFollowingIds(userId: String) async throws -> [String] {
        return try await api.get("/users/\(userId)/following/ids")
    }

    // No hay endpoint para FCM en la API REST
    func updateFCMToken(userId: String, token: String) async throws {}

    func updateSubscription(userId: String, active: Bool, endDate: Date) async throws {}
}
