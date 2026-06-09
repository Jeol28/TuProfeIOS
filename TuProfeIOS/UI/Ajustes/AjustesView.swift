import SwiftUI

// MARK: - AjustesView (matches Android AjustesScreen)

struct AjustesView: View {
    @StateObject private var viewModel = AjustesViewModel()
    @EnvironmentObject var navState: NavigationState
    @State private var showLanguageToast = false

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)

                    // ── Privacidad ──────────────────────────────────────────────

                    SectionLabel(text: "Privacidad")
                        .padding(.bottom, 8)

                    PrivacyToggleCard(
                        systemImage: "eye.slash",
                        title: "Perfil anónimo",
                        subtitle: "Tu nombre no aparecerá en las reseñas que publiques",
                        isOn: $viewModel.perfilAnonimo,
                        enabled: true
                    )

                    PrivacyToggleCard(
                        systemImage: "person",
                        title: "Perfil público",
                        subtitle: "Permite que otros usuarios vean tu perfil",
                        isOn: $viewModel.perfilPublico,
                        enabled: true
                    )

                    PrivacyToggleCard(
                        systemImage: "star",
                        title: "Reseñas en perfil",
                        subtitle: "Muestra tus reseñas en tu perfil público",
                        isOn: Binding(
                            get: { viewModel.resenasEnPerfil && viewModel.perfilPublico },
                            set: { _ in viewModel.toggleResenasEnPerfil() }
                        ),
                        enabled: viewModel.perfilPublico
                    )

                    Divider()
                        .padding(.vertical, 20)

                    // ── Usuarios bloqueados ─────────────────────────────────────

                    SectionLabel(text: "Usuarios bloqueados")
                        .padding(.bottom, 8)

                    if viewModel.isLoadingBlocked {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else if viewModel.blockedUsers.isEmpty {
                        PrivacyInfoCard(
                            systemImage: "person.slash",
                            text: "No has bloqueado a ningún usuario"
                        )
                    } else {
                        ForEach(viewModel.blockedUsers) { user in
                            BlockedUserCard(user: user) {
                                viewModel.unblockUser(blockedId: user.id)
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, 20)

                    // ── Idioma ──────────────────────────────────────────────────

                    SectionLabel(text: "Idioma")
                        .padding(.bottom, 4)

                    Text("Elige el idioma de la aplicación")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 12)

                    LanguageSelectorCard(
                        selectedCode: viewModel.selectedLanguage,
                        onLanguageSelected: {
                            viewModel.setLanguage($0)
                            showLanguageToast = true
                        }
                    )

                    Divider()
                        .padding(.vertical, 20)

                    // ── Política de privacidad ──────────────────────────────────

                    SectionLabel(text: "Política de privacidad")
                        .padding(.bottom, 8)

                    PrivacyInfoCard(
                        systemImage: "shield",
                        text: "Tu información se utiliza únicamente para ofrecer la experiencia de TuProfe. No compartimos tus datos con terceros."
                    )

                    Divider()
                        .padding(.vertical, 20)

                    // ── Versión ─────────────────────────────────────────────────

                    SectionLabel(text: "Versión de la app")
                        .padding(.bottom, 8)

                    AppVersionCard()

                    Spacer().frame(height: 110)
                }
                .padding(.horizontal, 24)
            }
        }
        .safeAreaInset(edge: .top) {
            TuProfeTopBarView()
        }
        .onAppear {
            viewModel.loadFromFirestore()
            viewModel.loadBlockedUsers()
        }
        .overlay(alignment: .bottom) {
            if showLanguageToast {
                LanguageAppliedToast()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 120)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { showLanguageToast = false }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showLanguageToast)
    }
}

// MARK: - Section label

private struct SectionLabel: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Privacy toggle card (matches Android PrivacyToggleItem)

private struct PrivacyToggleCard: View {
    let systemImage: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @Binding var isOn: Bool
    let enabled: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .foregroundColor(.verdetp)
                .font(.system(size: 22))
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.verdetp)
                .labelsHidden()
                .disabled(!enabled)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 1.5)
        )
        .opacity(enabled ? 1.0 : 0.4)
        .padding(.vertical, 6)
    }
}

// MARK: - Privacy info card (matches Android PrivacyInfoCard)

private struct PrivacyInfoCard: View {
    let systemImage: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.verdetp)
                .font(.system(size: 20))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 1.5)
        )
    }
}

// MARK: - App version card (matches Android version card)

private struct AppVersionCard: View {
    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(v)"
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "info.circle")
                .foregroundColor(.verdetp)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 2) {
                Text("TuProfe")
                    .font(.system(size: 15, weight: .bold))
                Text(versionString)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 1.5)
        )
    }
}

// MARK: - Blocked user card

private struct BlockedUserCard: View {
    let user: BlockedUser
    let onUnblock: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle")
                .foregroundColor(.verdetp)
                .font(.system(size: 26))

            Text(user.username)
                .font(.system(size: 15, weight: .bold))

            Spacer()

            Button(action: onUnblock) {
                Text("Desbloquear")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.red, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 1.5)
        )
        .padding(.vertical, 6)
    }
}

// MARK: - Language applied toast

private struct LanguageAppliedToast: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.verdetp)
            Text("Idioma aplicado")
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Language selector card (matches Android LanguageSelectorCard)

private struct LanguageSelectorCard: View {
    let selectedCode: String
    let onLanguageSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .foregroundColor(.verdetp)
                    .font(.system(size: 22))

                Text("Idioma")
                    .font(.system(size: 15, weight: .bold))
            }
            .padding(.bottom, 14)

            ForEach(LanguageManager.supported, id: \.code) { item in
                LanguageOptionRow(
                    label: LocalizedStringKey(item.label),
                    selected: selectedCode == item.code,
                    onClick: { onLanguageSelected(item.code) }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 1.5)
        )
    }
}

private struct LanguageOptionRow: View {
    let label: LocalizedStringKey
    let selected: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? Color.verdetp : Color.secondary.opacity(0.5), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if selected {
                        Circle()
                            .fill(Color.verdetp)
                            .frame(width: 10, height: 10)
                    }
                }

                Text(label)
                    .font(.system(size: 14, weight: selected ? .semibold : .regular))
                    .foregroundColor(selected ? .verdetp : .primary)

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ViewModel (matches Android AjustesViewModel)

@MainActor
class AjustesViewModel: ObservableObject {
    @Published var perfilAnonimo: Bool = false
    @Published var perfilPublico: Bool = true
    @Published var resenasEnPerfil: Bool = true
    @Published var blockedUsers: [BlockedUser] = []
    @Published var isLoadingBlocked = false
    @Published var selectedLanguage: String = LanguageManager.shared.selectedCode

    private var isLoaded = false
    private let userRepo = UserRepository.shared
    private let moderationRepo = ModerationRepository.shared

    private var userId: String { AuthRepository.shared.currentUserId ?? "" }

    init() {
        let ud = UserDefaults.standard
        perfilAnonimo = ud.object(forKey: "perfil_anonimo") as? Bool ?? false
        perfilPublico = ud.object(forKey: "perfil_publico") as? Bool ?? true
        resenasEnPerfil = ud.object(forKey: "resenas_en_perfil") as? Bool ?? true
        selectedLanguage = LanguageManager.shared.selectedCode
    }

    func setLanguage(_ code: String) {
        LanguageManager.shared.setLanguage(code)
        selectedLanguage = code
    }

    func loadBlockedUsers() {
        guard !userId.isEmpty else { return }
        isLoadingBlocked = true
        Task {
            let list = (try? await moderationRepo.getBlockedUsers(userId: userId)) ?? []
            blockedUsers = list
            isLoadingBlocked = false
        }
    }

    func unblockUser(blockedId: String) {
        guard !userId.isEmpty else { return }
        Task {
            try? await moderationRepo.unblockUser(blockerId: userId, blockedId: blockedId)
            blockedUsers.removeAll { $0.id == blockedId }
        }
    }

    func loadFromFirestore() {
        guard !userId.isEmpty else { return }
        Task {
            do {
                let user = try await userRepo.getUserById(userId, currentUserId: userId)
                perfilAnonimo = user.perfilAnonimo
                perfilPublico = user.perfilPublico
                resenasEnPerfil = user.resenasEnPerfil
                saveToUserDefaults()
                isLoaded = true
            } catch {
                isLoaded = true
            }
        }
    }

    func togglePerfilAnonimo() {
        perfilAnonimo.toggle()
        saveToUserDefaults()
        persistToFirestore()
    }

    func togglePerfilPublico() {
        perfilPublico.toggle()
        saveToUserDefaults()
        persistToFirestore()
    }

    func toggleResenasEnPerfil() {
        guard perfilPublico else { return }
        resenasEnPerfil.toggle()
        saveToUserDefaults()
        persistToFirestore()
    }

    private func saveToUserDefaults() {
        let ud = UserDefaults.standard
        ud.set(perfilAnonimo, forKey: "perfil_anonimo")
        ud.set(perfilPublico, forKey: "perfil_publico")
        ud.set(resenasEnPerfil, forKey: "resenas_en_perfil")
    }

    private func persistToFirestore() {
        guard !userId.isEmpty else { return }
        let anonimo = perfilAnonimo
        let publico = perfilPublico
        let resenas = resenasEnPerfil
        Task {
            try? await userRepo.updatePrivacySettings(
                userId: userId,
                perfilAnonimo: anonimo,
                perfilPublico: publico,
                resenasEnPerfil: resenas
            )
        }
    }
}
