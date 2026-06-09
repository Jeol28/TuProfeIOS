import SwiftUI

// MARK: - NotifInboxView (matches Android NotifInboxScreen)

struct NotifInboxView: View {
    @StateObject private var viewModel = NotifInboxViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { navState.pop() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.verdetp)
                    }
                    .buttonStyle(.plain)

                    Text(LocalizedStringKey("Notificaciones"))
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)

                    if viewModel.notifications.contains(where: { !$0.isRead }) {
                        Button(action: { viewModel.markAllRead() }) {
                            Text(LocalizedStringKey("notif_marcar_leidas"))
                                .font(.system(size: 12))
                                .foregroundColor(.verdetp)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if viewModel.notifications.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.verdetp.opacity(0.4))
                        Text(LocalizedStringKey("notif_sin_notificaciones"))
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(viewModel.notifications) { notif in
                                NotifItemRow(notif: notif) {
                                    viewModel.onNotificationTap(notif)
                                    navigate(notif: notif)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) { TuProfeTopBarView() }
    }

    private func navigate(notif: AppNotification) {
        guard !notif.entityId.isEmpty else { return }
        switch notif.type {
        case "like", "reviewDeleted":
            navState.navigate(to: .detalle(reviewId: notif.entityId))
        case "comment", "reply":
            navState.navigate(to: .commentDetalle(commentId: notif.entityId))
        case "follow":
            navState.navigate(to: .profile(userId: notif.entityId))
        default:
            break
        }
    }
}

// MARK: - Single notification row

private struct NotifItemRow: View {
    let notif: AppNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar with type badge
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if !notif.senderImageUrl.isEmpty, let url = URL(string: notif.senderImageUrl) {
                            AsyncImage(url: url) { phase in
                                if let img = phase.image {
                                    img.resizable().scaledToFill()
                                } else {
                                    Color.verdetp.opacity(0.15)
                                }
                            }
                        } else {
                            Color.verdetp.opacity(0.15)
                                .overlay(
                                    Image(systemName: typeIcon(notif.type))
                                        .foregroundColor(.verdetp)
                                        .font(.system(size: 18))
                                )
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                    Circle()
                        .fill(Color.verdetp)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: typeIcon(notif.type))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 4, y: 4)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedTitle(for: notif))
                        .font(.system(size: 14, weight: notif.isRead ? .regular : .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(notif.timestamp.relativeString)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Unread dot
                if !notif.isRead {
                    Circle()
                        .fill(Color.verdetp)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(12)
            .background(
                notif.isRead ? Color.clear : Color.verdetp.opacity(0.06)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        notif.isRead ? Color.clear : Color.verdetp.opacity(0.15),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func localizedTitle(for notif: AppNotification) -> String {
        let name = notif.senderName.isEmpty ? "?" : notif.senderName
        switch notif.type {
        case "like":          return String(format: NSLocalizedString("notif_like_title", comment: ""), name)
        case "comment":       return String(format: NSLocalizedString("notif_comment_title", comment: ""), name)
        case "reply":         return String(format: NSLocalizedString("notif_reply_title", comment: ""), name)
        case "follow":        return String(format: NSLocalizedString("notif_follow_title", comment: ""), name)
        case "reviewDeleted": return NSLocalizedString("notif_review_deleted_title", comment: "")
        default:              return notif.title.isEmpty ? notif.type : notif.title
        }
    }

    private func typeIcon(_ type: String) -> String {
        switch type {
        case "like":                return "hand.thumbsup"
        case "comment", "reply":   return "bubble.left"
        case "follow":              return "person.badge.plus"
        case "review", "reviewDeleted": return "star"
        default:                    return "bell"
        }
    }
}

// MARK: - Date helper

private extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = LanguageManager.shared.currentLocale
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - ViewModel

@MainActor
class NotifInboxViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []

    private let notifRepo = NotificationRepository.shared
    private var listenTask: Task<Void, Never>?
    private var uid: String { AuthRepository.shared.currentUserId ?? "" }

    init() {
        guard !uid.isEmpty else { return }
        listenTask = Task {
            for await list in notifRepo.listenNotifications(userId: uid) {
                self.notifications = list
            }
        }
    }

    deinit { listenTask?.cancel() }

    func onNotificationTap(_ notif: AppNotification) {
        guard !notif.isRead else { return }
        Task { try? await notifRepo.markRead(userId: uid, notifId: notif.id) }
    }

    func markAllRead() {
        Task { try? await notifRepo.markAllRead(userId: uid) }
    }
}
