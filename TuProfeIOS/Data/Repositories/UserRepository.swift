import Foundation
import FirebaseMessaging

// MARK: - UserRepository

class UserRepository {
    static let shared = UserRepository()
    private let dataSource: any UserDataSource = makeUserDataSource()

    func getUserById(_ userId: String, currentUserId: String) async throws -> Usuario {
        try await dataSource.getUserById(userId, currentUserId: currentUserId)
    }

    func registerUser(userId: String, username: String, email: String, carrera: String) async throws {
        let fcmToken = try? await Messaging.messaging().token()
        try await dataSource.registerUser(
            userId: userId,
            username: username,
            email: email,
            carrera: carrera,
            fcmToken: fcmToken
        )
    }

    func updateUser(userId: String, username: String, email: String, carrera: String) async throws {
        try await dataSource.updateUser(userId: userId, username: username, email: email, carrera: carrera)
    }

    func updateUserPhoto(userId: String, photoURL: String) async throws {
        try await dataSource.updateUserPhoto(userId: userId, photoURL: photoURL)
    }

    func updatePrivacySettings(userId: String, perfilAnonimo: Bool, perfilPublico: Bool, resenasEnPerfil: Bool) async throws {
        try await dataSource.updatePrivacySettings(
            userId: userId,
            perfilAnonimo: perfilAnonimo,
            perfilPublico: perfilPublico,
            resenasEnPerfil: resenasEnPerfil
        )
    }

    func getFollowers(userId: String, currentUserId: String) async throws -> [Usuario] {
        try await dataSource.getFollowers(userId: userId, currentUserId: currentUserId)
    }

    func getFollowing(userId: String, currentUserId: String) async throws -> [Usuario] {
        try await dataSource.getFollowing(userId: userId, currentUserId: currentUserId)
    }

    func followOrUnfollowUser(currentUserId: String, targetUserId: String) async throws {
        try await dataSource.followOrUnfollowUser(currentUserId: currentUserId, targetUserId: targetUserId)
    }

    func getFollowingIds(userId: String) async throws -> [String] {
        try await dataSource.getFollowingIds(userId: userId)
    }

    func updateFCMToken(userId: String, token: String) async throws {
        try await dataSource.updateFCMToken(userId: userId, token: token)
    }

    func updateSubscription(userId: String, active: Bool, endDate: Date) async throws {
        try await dataSource.updateSubscription(userId: userId, active: active, endDate: endDate)
    }
}
