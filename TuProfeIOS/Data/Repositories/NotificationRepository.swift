import Foundation

final class NotificationRepository {
    static let shared = NotificationRepository()
    private let dataSource = NotificationFirestoreDataSource()
    private init() {}

    func listenNotifications(userId: String) -> AsyncStream<[AppNotification]> {
        dataSource.listenNotifications(userId: userId)
    }

    func listenUnreadCount(userId: String) -> AsyncStream<Int> {
        dataSource.listenUnreadCount(userId: userId)
    }

    func markRead(userId: String, notifId: String) async throws {
        try await dataSource.markRead(userId: userId, notifId: notifId)
    }

    func markAllRead(userId: String) async throws {
        try await dataSource.markAllRead(userId: userId)
    }
}
