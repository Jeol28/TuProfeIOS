import SwiftUI
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

// MARK: - NotificacionesView (matches Android NotificacionesScreen)

struct NotificacionesView: View {
    @StateObject private var viewModel = NotificacionesViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 12) {
                    Spacer().frame(height: 8)

                    NotifToggleCard(
                        systemImage: "hand.thumbsup",
                        title: "Likes en reseñas",
                        subtitle: "Recibe notificaciones cuando den like a tus reseñas",
                        isOn: $viewModel.likesEnabled
                    )

                    NotifToggleCard(
                        systemImage: "bubble.left",
                        title: "Comentarios en reseñas",
                        subtitle: "Recibe notificaciones cuando comenten tus reseñas",
                        isOn: $viewModel.comentariosEnabled
                    )

                    NotifToggleCard(
                        systemImage: "person.badge.plus",
                        title: "Nuevos seguidores",
                        subtitle: "Recibe notificaciones cuando alguien te siga",
                        isOn: $viewModel.seguidoresEnabled
                    )

                    Divider()
                        .padding(.vertical, 8)

                    SystemPermissionCard(
                        granted: viewModel.permissionGranted,
                        onRequest: { viewModel.requestPermission() }
                    )

                    Spacer().frame(height: 110)
                }
                .padding(.horizontal, 24)
            }
        }
        .safeAreaInset(edge: .top) {
            TuProfeTopBarView()
        }
        .onAppear { viewModel.refreshPermissionState() }
    }
}

// MARK: - Toggle card (matches Android NotifToggleItem)

struct NotifToggleCard: View {
    let systemImage: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .foregroundColor(.verdetp)
                .font(.system(size: 22))
                .frame(width: 36, height: 36)

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

// MARK: - System permission card (matches Android SystemPermissionCard)

struct SystemPermissionCard: View {
    let granted: Bool
    let onRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: granted ? "bell.badge.fill" : "bell.slash.fill")
                    .foregroundColor(.verdetp)
                    .font(.system(size: 22))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Permisos del sistema")
                        .font(.system(size: 15, weight: .bold))
                    Text("Activa las notificaciones para recibir alertas")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            if !granted {
                AppButton(title: "Activar permisos", action: onRequest)
            } else {
                Text("✓ Permisos concedidos")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.verdetp)
            }
        }
        .padding(20)
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 1.5)
        )
    }
}

// MARK: - ViewModel

@MainActor
class NotificacionesViewModel: ObservableObject {
    @Published var likesEnabled: Bool {
        didSet {
            UserDefaults.standard.set(likesEnabled, forKey: "notif_likes")
            syncPrefsToFirestore()
        }
    }
    @Published var comentariosEnabled: Bool {
        didSet {
            UserDefaults.standard.set(comentariosEnabled, forKey: "notif_comentarios")
            syncPrefsToFirestore()
        }
    }
    @Published var seguidoresEnabled: Bool {
        didSet {
            UserDefaults.standard.set(seguidoresEnabled, forKey: "notif_seguidores")
            syncPrefsToFirestore()
        }
    }
    @Published var permissionGranted = false

    init() {
        let ud = UserDefaults.standard
        likesEnabled = ud.object(forKey: "notif_likes") as? Bool ?? true
        comentariosEnabled = ud.object(forKey: "notif_comentarios") as? Bool ?? true
        seguidoresEnabled = ud.object(forKey: "notif_seguidores") as? Bool ?? true
    }

    private func syncPrefsToFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(userId).updateData([
            "notifPrefs": [
                "likes": likesEnabled,
                "comentarios": comentariosEnabled,
                "seguidores": seguidoresEnabled
            ]
        ])
    }

    func refreshPermissionState() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            permissionGranted = settings.authorizationStatus == .authorized
        }
    }

    func requestPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                permissionGranted = granted
            } catch {
                permissionGranted = false
            }
        }
    }
}