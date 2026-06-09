import Foundation

protocol UserDataSource {
    func getUserById(_ userId: String, currentUserId: String) async throws -> Usuario
    func registerUser(userId: String, username: String, email: String, carrera: String, fcmToken: String?) async throws
    func updateUser(userId: String, username: String, email: String, carrera: String) async throws
    func updateUserPhoto(userId: String, photoURL: String) async throws
    func updatePrivacySettings(userId: String, perfilAnonimo: Bool, perfilPublico: Bool, resenasEnPerfil: Bool) async throws
    func getFollowers(userId: String, currentUserId: String) async throws -> [Usuario]
    func getFollowing(userId: String, currentUserId: String) async throws -> [Usuario]
    func followOrUnfollowUser(currentUserId: String, targetUserId: String) async throws
    func getFollowingIds(userId: String) async throws -> [String]
    func updateFCMToken(userId: String, token: String) async throws
    func updateSubscription(userId: String, active: Bool, endDate: Date) async throws
}
