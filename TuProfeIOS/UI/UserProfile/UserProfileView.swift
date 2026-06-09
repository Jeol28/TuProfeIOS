import SwiftUI

// MARK: - UserProfileView (matches Android UserProfileScreen)

struct UserProfileView: View {
    let userId: String
    @StateObject private var viewModel = UserProfileViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            if viewModel.isLoading {
                ProgressView().tint(.verdetp)
            } else if viewModel.isBlockedByUser {
                VStack(spacing: 12) {
                    Image(systemName: "slash.circle")
                        .font(.system(size: 46))
                        .foregroundColor(.verdetp.opacity(0.45))
                    Text("Este usuario te ha bloqueado")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.verdetp.opacity(0.65))
                        .multilineTextAlignment(.center)
                    Text("No puedes seguirlo ni ver sus reseñas.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
            } else if let user = viewModel.user {
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 8)

                        // Profile header
                        VStack(spacing: 12) {
                            // Block + Chat buttons — only for other users
                            if userId != AuthRepository.shared.currentUserId {
                                HStack {
                                    Button(action: { viewModel.showBlockConfirm = true }) {
                                        Image(systemName: "slash.circle")
                                            .foregroundStyle(Color.verdetp)
                                            .font(.system(size: 18))
                                            .frame(width: 42, height: 42)
                                            .background(Color.verdetp.opacity(0.1), in: Circle())
                                            .overlay { Circle().strokeBorder(Color.verdetp.opacity(0.3), lineWidth: 1) }
                                    }
                                    .buttonStyle(.plain)
                                    Spacer()
                                    Button(action: {
                                        let chatId = ChatRepository.chatId(for: userId, uid2: viewModel.currentUserId)
                                        navState.navigate(to: .chat(chatId: chatId, otherUserId: userId))
                                    }) {
                                        Image(systemName: "message")
                                            .foregroundStyle(Color.verdetp)
                                            .font(.system(size: 18))
                                            .frame(width: 42, height: 42)
                                            .background(Color.verdetp.opacity(0.1), in: Circle())
                                            .overlay { Circle().strokeBorder(Color.verdetp.opacity(0.3), lineWidth: 1) }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            ProfileImageView(
                                url: user.imageprofeUrl,
                                size: 90,
                                borderWidth: 3,
                                borderColor: .verdetp,
                                isViewable: true
                            )

                            if !user.perfilAnonimo {
                                Text(user.nombreUsu)
                                    .font(.system(size: 22, weight: .bold))
                            } else {
                                Text("Usuario anónimo")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.secondary)
                            }

                            Text(user.carrera)
                                .font(.system(size: 14))
                                .foregroundColor(.verdetp)

                            // Followers / Following
                            HStack(spacing: 40) {
                                VStack(spacing: 2) {
                                    Text("\(user.followersCount)")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("Seguidores")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Divider().frame(height: 32)
                                VStack(spacing: 2) {
                                    Text("\(user.followingCount)")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("Siguiendo")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Follow button
                            if userId != AuthRepository.shared.currentUserId {
                                Button(action: { viewModel.toggleFollow() }) {
                                    Group {
                                        if viewModel.isFollowing {
                                            Text("Siguiendo")
                                        } else {
                                            Text("Seguir")
                                        }
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(viewModel.isFollowing ? .secondary : .white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 10)
                                    .background(viewModel.isFollowing ? Color.secondary.opacity(0.15) : Color.verdetp)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                viewModel.isFollowing ? Color.secondary.opacity(0.3) : Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .animation(.easeInOut(duration: 0.2), value: viewModel.isFollowing)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Reviews (if public)
                        if user.perfilPublico && user.resenasEnPerfil {
                            Text("Reseñas")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.verdetp)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                                .padding(.bottom, 8)

                            ForEach(Array(viewModel.userReviews.enumerated()), id: \.element.id) { index, review in
                                ReviewCardView(
                                    review: review,
                                    onTap: { navState.navigate(to: .detalle(reviewId: review.reviewId)) },
                                    onProfessorTap: { navState.navigate(to: .profe(profeId: review.profesor.profeId)) },
                                    onUserTap: { navState.navigate(to: .profile(userId: review.usuario.id)) },
                                    onLike: { viewModel.toggleLike(reviewId: review.reviewId) }
                                )
                                .animatedListItem(index: index)
                            }
                        } else if !user.perfilPublico {
                            VStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary)
                                Text("Este perfil es privado")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 40)
                        }

                        Spacer().frame(height: 110)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            TuProfeTopBarView()
        }
        .onAppear { viewModel.cargarPerfil(userId: userId) }
        .confirmationDialog(
            "¿Bloquear a \(viewModel.user?.nombreUsu ?? "este usuario")?",
            isPresented: $viewModel.showBlockConfirm,
            titleVisibility: .visible
        ) {
            Button("Bloquear", role: .destructive) { viewModel.blockUser() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Ya no verás su contenido.")
        }
        .onChange(of: viewModel.navigateBack) { back in
            if back { navState.pop() }
        }
    }
}

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var user: Usuario? = nil
    @Published var userReviews: [ReviewInfo] = []
    @Published var isLoading = false
    @Published var isFollowing = false
    @Published var showBlockConfirm = false
    @Published var navigateBack = false
    @Published var isBlockedByUser = false

    private let userRepo = UserRepository.shared
    private let reviewRepo = ReviewRepository.shared
    private let moderationRepo = ModerationRepository.shared

    var currentUserId: String { AuthRepository.shared.currentUserId ?? "" }

    func cargarPerfil(userId: String) {
        isLoading = true
        Task {
            do {
                async let u = userRepo.getUserById(userId, currentUserId: currentUserId)
                async let reviews = reviewRepo.getReviewsByUser(userId)
                let (fetchedUser, fetchedReviews) = try await (u, reviews)
                user = fetchedUser
                userReviews = fetchedReviews
                isFollowing = fetchedUser.followed
                isBlockedByUser = ModerationCache.shared.blockedByUserIds.contains(userId)
            } catch {
                print("Error: \(error)")
            }
            isLoading = false
        }
    }

    func toggleLike(reviewId: String) {
        guard !currentUserId.isEmpty else { return }
        if let idx = userReviews.firstIndex(where: { $0.id == reviewId }) {
            userReviews[idx].liked.toggle()
            userReviews[idx].likes += userReviews[idx].liked ? 1 : -1
        }
        Task {
            do {
                try await reviewRepo.toggleLike(reviewId: reviewId, userId: currentUserId)
            } catch {
                if let idx = userReviews.firstIndex(where: { $0.id == reviewId }) {
                    userReviews[idx].liked.toggle()
                    userReviews[idx].likes += userReviews[idx].liked ? 1 : -1
                }
            }
        }
    }

    func blockUser() {
        guard let blockedId = user?.id,
              let currentId = AuthRepository.shared.currentUserId else { return }
        let wasFollowing = isFollowing
        Task {
            try? await moderationRepo.blockUser(blockerId: currentId, blockedId: blockedId)
            if wasFollowing {
                try? await userRepo.followOrUnfollowUser(currentUserId: currentId, targetUserId: blockedId)
            }
            navigateBack = true
        }
    }

    func toggleFollow() {
        guard let userId = user?.id else { return }
        Task {
            do {
                try await userRepo.followOrUnfollowUser(currentUserId: currentUserId, targetUserId: userId)
                isFollowing.toggle()
                user?.followed = isFollowing
                if isFollowing {
                    user?.followersCount += 1
                } else {
                    user?.followersCount -= 1
                }
            } catch {
                print("Error follow: \(error)")
            }
        }
    }
}