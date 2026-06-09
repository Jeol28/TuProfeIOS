import SwiftUI

// MARK: - ConfigView (matches Android ConfigScreen - user profile + settings hub)

struct ConfigView: View {
    let onLogout: () -> Void
    @StateObject private var viewModel = ConfigViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                TuProfeTopBarView()

                HStack {
                    ZStack(alignment: .topTrailing) {
                        Button(action: { navState.navigate(to: .notifInbox) }) {
                            Image(systemName: "bell")
                                .foregroundStyle(Color.verdetp)
                                .font(.system(size: 18))
                                .frame(width: 42, height: 42)
                                .background(Color.verdetp.opacity(0.1), in: Circle())
                                .overlay { Circle().strokeBorder(Color.verdetp.opacity(0.3), lineWidth: 1) }
                        }
                        .buttonStyle(.plain)
                        if viewModel.unreadNotifCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(x: 2, y: -2)
                        }
                    }
                    Spacer()
                    ZStack(alignment: .topTrailing) {
                        Button(action: { navState.navigate(to: .chatList) }) {
                            Image(systemName: "message")
                                .foregroundStyle(Color.verdetp)
                                .font(.system(size: 18))
                                .frame(width: 42, height: 42)
                                .background(Color.verdetp.opacity(0.1), in: Circle())
                                .overlay { Circle().strokeBorder(Color.verdetp.opacity(0.3), lineWidth: 1) }
                        }
                        .buttonStyle(.plain)
                        if viewModel.hasUnreadChats {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if viewModel.isLoading {
                    ProgressView().tint(.verdetp)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 20)

                        // Profile header
                        ProfileHeaderSection(
                            viewModel: viewModel,
                            onFollowersTap: { viewModel.openFollowersSheet() },
                            onFollowingTap: { viewModel.openFollowingSheet() }
                        )

                        Spacer().frame(height: 24)

                        // Menu items
                        VStack(spacing: 0) {
                            ConfigItemRow(
                                systemImage: "pencil.circle",
                                title: "Editar perfil",
                                subtitle: "Actualiza tu información personal"
                            ) {
                                navState.navigate(to: .configPerfil)
                            }

                            ConfigItemRow(
                                systemImage: "star.circle",
                                title: "Mis reseñas",
                                subtitle: "Ver tu historial de reseñas y comentarios"
                            ) {
                                navState.navigate(to: .historial)
                            }

                            ConfigItemRow(
                                systemImage: "bell.circle",
                                title: "Notificaciones",
                                subtitle: "Gestiona tus notificaciones"
                            ) {
                                navState.navigate(to: .notificaciones)
                            }

                            ConfigItemRow(
                                systemImage: "gearshape.circle",
                                title: "Ajustes",
                                subtitle: "Preferencias de la aplicación"
                            ) {
                                navState.navigate(to: .ajustes)
                            }

                            ConfigItemRow(
                                systemImage: "questionmark.circle",
                                title: "Ayuda y soporte",
                                subtitle: "Preguntas frecuentes y contacto"
                            ) {
                                navState.navigate(to: .ayudaYSoporte)
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 24)

                        // Subscription banner
                        if viewModel.subscriptionActive && (viewModel.subscriptionDaysLeft ?? 100) > 3 {
                            EmptyView()
                        } else if viewModel.subscriptionActive && (viewModel.subscriptionDaysLeft ?? 0) <= 3 {
                            RenewalReminderBannerView(
                                daysLeft: viewModel.subscriptionDaysLeft ?? 0,
                                onClick: { navState.navigate(to: .payment) }
                            )
                        } else {
                            SubscripcionBannerView(
                                onClick: { navState.navigate(to: .payment) }
                            )
                        }

                        Spacer().frame(height: 8)

                        // Logout
                        Button(action: {
                            viewModel.onLogoutClick()
                            onLogout()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                Text("Cerrar sesión")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 110)
                    }
                }
            }
        }
        }
        .sheet(isPresented: $viewModel.showFollowersSheet) {
            FollowListSheet(
                title: "Seguidores",
                users: viewModel.followersList,
                isLoading: viewModel.isLoadingList,
                currentUserId: viewModel.currentUserId,
                onUserTap: { userId in
                    viewModel.showFollowersSheet = false
                    navState.navigate(to: .profile(userId: userId))
                },
                onFollowToggle: { userId in viewModel.followOrUnfollowInList(userId: userId) }
            )
        }
        .sheet(isPresented: $viewModel.showFollowingSheet) {
            FollowListSheet(
                title: "Siguiendo",
                users: viewModel.followingList,
                isLoading: viewModel.isLoadingList,
                currentUserId: viewModel.currentUserId,
                onUserTap: { userId in
                    viewModel.showFollowingSheet = false
                    navState.navigate(to: .profile(userId: userId))
                },
                onFollowToggle: { userId in viewModel.followOrUnfollowInList(userId: userId) }
            )
        }
        .onAppear { viewModel.loadUserProfile() }
    }
}

// MARK: - Profile header

struct ProfileHeaderSection: View {
    @ObservedObject var viewModel: ConfigViewModel
    let onFollowersTap: () -> Void
    let onFollowingTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ProfileImageView(
                url: viewModel.profileImageUrl,
                size: 90,
                borderWidth: 3,
                borderColor: .verdetp
            )

            Text(viewModel.username)
                .font(.system(size: 22, weight: .bold))

            Text(viewModel.carrera)
                .font(.system(size: 14))
                .foregroundColor(.verdetp)

            Text(viewModel.email)
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            // Followers / Following counts
            HStack(spacing: 40) {
                Button(action: onFollowersTap) {
                    VStack(spacing: 2) {
                        Text("\(viewModel.followersCount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Seguidores")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Divider().frame(height: 32)

                Button(action: onFollowingTap) {
                    VStack(spacing: 2) {
                        Text("\(viewModel.followingCount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Siguiendo")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Follow list sheet

struct FollowListSheet: View {
    let title: LocalizedStringKey
    let users: [Usuario]
    let isLoading: Bool
    let currentUserId: String
    let onUserTap: (String) -> Void
    let onFollowToggle: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().tint(.verdetp)
                } else {
                    List(users) { user in
                        HStack(spacing: 12) {
                            Button(action: { onUserTap(user.id) }) {
                                HStack(spacing: 12) {
                                    ProfileImageView(url: user.imageprofeUrl, size: 44)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.nombreUsu)
                                            .font(.system(size: 15, weight: .semibold))
                                        Text(user.carrera)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            Spacer()

                            if user.id != currentUserId {
                                Button(action: { onFollowToggle(user.id) }) {
                                    Text(user.followed ? "Siguiendo" : "Seguir")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(user.followed ? .secondary : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(user.followed ? Color.secondary.opacity(0.15) : Color.verdetp)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - ConfigViewModel

@MainActor
class ConfigViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var carrera = ""
    @Published var profileImageUrl: String? = nil
    @Published var followersCount = 0
    @Published var followingCount = 0
    @Published var isLoading = false
    @Published var showFollowersSheet = false
    @Published var showFollowingSheet = false
    @Published var followersList: [Usuario] = []
    @Published var followingList: [Usuario] = []
    @Published var isLoadingList = false
    @Published var hasUnreadChats = false
    @Published var unreadNotifCount = 0
    @Published var subscriptionActive = false
    @Published var subscriptionDaysLeft: Int? = nil

    var currentUserId: String { AuthRepository.shared.currentUserId ?? "" }

    private let userRepo = UserRepository.shared
    private let chatRepo = ChatRepository.shared
    private let notifRepo = NotificationRepository.shared
    private var unreadListenTask: Task<Void, Never>?
    private var notifListenTask: Task<Void, Never>?

    func loadUserProfile() {
        guard !currentUserId.isEmpty else { return }
        isLoading = true
        Task {
            do {
                let user = try await userRepo.getUserById(currentUserId, currentUserId: currentUserId)
                username = user.nombreUsu
                email = user.email
                carrera = user.carrera
                profileImageUrl = user.imageprofeUrl
                followersCount = user.followersCount
                followingCount = user.followingCount
                subscriptionActive = user.subscriptionActive
                subscriptionDaysLeft = user.subscriptionDaysLeft
            } catch {
                print("Error cargando perfil: \(error)")
            }
            isLoading = false
        }
        startListeningUnread()
    }

    private func startListeningUnread() {
        let uid = currentUserId
        guard !uid.isEmpty else { return }
        unreadListenTask?.cancel()
        unreadListenTask = Task {
            for await chats in chatRepo.listenChats(userId: uid) {
                hasUnreadChats = chats.contains { $0.unreadCount > 0 }
            }
        }
        notifListenTask?.cancel()
        notifListenTask = Task {
            for await count in notifRepo.listenUnreadCount(userId: uid) {
                unreadNotifCount = count
            }
        }
    }

    func openFollowersSheet() {
        showFollowersSheet = true
        isLoadingList = true
        Task {
            followersList = (try? await userRepo.getFollowers(userId: currentUserId, currentUserId: currentUserId)) ?? []
            isLoadingList = false
        }
    }

    func openFollowingSheet() {
        showFollowingSheet = true
        isLoadingList = true
        Task {
            followingList = (try? await userRepo.getFollowing(userId: currentUserId, currentUserId: currentUserId)) ?? []
            isLoadingList = false
        }
    }

    func followOrUnfollowInList(userId: String) {
        Task {
            try? await userRepo.followOrUnfollowUser(currentUserId: currentUserId, targetUserId: userId)
            if let idx = followersList.firstIndex(where: { $0.id == userId }) {
                followersList[idx].followed.toggle()
            }
            if let idx = followingList.firstIndex(where: { $0.id == userId }) {
                followingList[idx].followed.toggle()
            }
        }
    }

    func onLogoutClick() {
        try? AuthRepository.shared.signOut()
    }
}

// MARK: - SubscripcionBannerView

struct SubscripcionBannerView: View {
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("premium_ayudanos", tableName: "Localizable")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("premium_precio", tableName: "Localizable")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.verdetp)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.verdetp.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}

// MARK: - RenewalReminderBannerView

struct RenewalReminderBannerView: View {
    let daysLeft: Int
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(daysLeft == 0
                         ? NSLocalizedString("premium_vence_hoy", comment: "")
                         : String(format: NSLocalizedString("premium_vence_dias", comment: ""), daysLeft))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                    Text("premium_renueva", tableName: "Localizable")
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.label).opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.label))
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemRed).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color(UIColor.systemRed).opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}