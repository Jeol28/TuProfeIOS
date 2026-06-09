import SwiftUI
import PhotosUI

// MARK: - ConfigPerfilView (matches Android ConfigPerfilScreen)

struct ConfigPerfilView: View {
    @StateObject private var viewModel = ConfigPerfilViewModel()
    @EnvironmentObject var navState: NavigationState
    @State private var selectedPhoto: PhotosPickerItem? = nil

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 8)

                    // Profile image picker
                    VStack(spacing: 8) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                ProfileImageView(
                                    url: viewModel.profileImageUrl,
                                    size: 100,
                                    borderWidth: 3,
                                    borderColor: .verdetp
                                )

                                Circle()
                                    .fill(Color.verdetp)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 14))
                                    )
                                    .offset(x: 4, y: 4)
                            }
                        }

                        if viewModel.isUploadingPhoto {
                            ProgressView("Subiendo foto...")
                                .font(.system(size: 12))
                                .tint(.verdetp)
                        }
                    }

                    // Form fields
                    VStack(spacing: 14) {
                        AppTextField(
                            placeholder: "Nombre de usuario",
                            text: $viewModel.username,
                            autocapitalization: .never
                        )

                        AppTextField(
                            placeholder: "Correo electrónico",
                            text: $viewModel.email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        AppTextField(
                            placeholder: "Carrera",
                            text: $viewModel.carrera
                        )
                    }
                    .padding(.horizontal, 32)

                    if let error = viewModel.error {
                        Text(LocalizedStringKey(error))
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .padding(.horizontal, 24)
                    }

                    if let msg = viewModel.passwordResetMessage {
                        Text(LocalizedStringKey(msg))
                            .foregroundColor(viewModel.passwordResetIsError ? .red : .verdetp)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    AppTextButton(title: "CAMBIAR CONTRASEÑA", action: { viewModel.sendPasswordReset() })

                    AppButton(
                        title: "GUARDAR CAMBIOS",
                        action: { viewModel.saveChanges() },
                        isEnabled: !viewModel.isLoading,
                        isLoading: viewModel.isLoading
                    )

                    // Delete account
                    Button(action: { viewModel.showDeleteAccountAlert = true }) {
                        Text("BORRAR CUENTA")
                            .font(.custom("BebasNeue-Regular", size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                    }
                    .background(Color.red)
                    .clipShape(Capsule())
                    .pressScaleEffect()
                    .padding(.bottom, 24)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            TuProfeTopBarView()
        }
        .onChange(of: selectedPhoto) { item in
            Task {
                guard let item else { return }
                if let raw = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: raw),
                   let jpeg = uiImage.jpegData(compressionQuality: 0.8) {
                    await viewModel.uploadPhoto(data: jpeg)
                } else {
                    viewModel.error = "No se pudo cargar la imagen seleccionada"
                }
            }
        }
        .onChange(of: viewModel.success) { ok in if ok { navState.pop() } }
        .onChange(of: viewModel.deleteAccountSuccess) { ok in if ok { navState.popToRoot(); navState.isAuthenticated = false } }
        .alert("¿Eliminar cuenta?", isPresented: $viewModel.showDeleteAccountAlert) {
            SecureField("Contraseña", text: $viewModel.deletePassword)
            Button("Eliminar", role: .destructive) {
                viewModel.deleteAccount()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción es irreversible. Se eliminarán todos tus datos.")
        }
        .onAppear { viewModel.loadCurrentUser() }
    }
}

// MARK: - Privacy toggle

struct PrivacyToggle: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(.verdetp)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - ConfigPerfilViewModel

@MainActor
class ConfigPerfilViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var carrera = ""
    @Published var profileImageUrl: String? = nil
    @Published var isLoading = false
    @Published var isUploadingPhoto = false
    @Published var error: String? = nil
    @Published var success = false
    @Published var showDeleteAccountAlert = false
    @Published var deletePassword = ""
    @Published var deleteAccountSuccess = false
    @Published var passwordResetMessage: String? = nil
    @Published var passwordResetIsError = false

    private let userRepo = UserRepository.shared
    private let storageRepo = StorageRepository.shared
    private let authRepo = AuthRepository.shared

    var currentUserId: String { authRepo.currentUserId ?? "" }

    func loadCurrentUser() {
        email = authRepo.currentUserEmail ?? ""
        Task {
            do {
                let user = try await userRepo.getUserById(currentUserId, currentUserId: currentUserId)
                username = user.nombreUsu
                carrera = user.carrera
                profileImageUrl = user.imageprofeUrl
            } catch {
                print("Error: \(error)")
            }
        }
    }

    func saveChanges() {
        isLoading = true
        error = nil
        Task {
            do {
                try await userRepo.updateUser(
                    userId: currentUserId,
                    username: username,
                    email: email,
                    carrera: carrera
                )
                success = true
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }

    func uploadPhoto(data: Data) async {
        isUploadingPhoto = true
        do {
            let url = try await storageRepo.uploadProfileImage(userId: currentUserId, imageData: data)
            try await userRepo.updateUserPhoto(userId: currentUserId, photoURL: url)
            if let photoURL = URL(string: url) {
                try? await authRepo.updateProfileImage(photoURL: photoURL)
            }
            profileImageUrl = url
        } catch {
            self.error = "Error al subir la foto"
        }
        isUploadingPhoto = false
    }

    func sendPasswordReset() {
        guard let authEmail = authRepo.currentUserEmail else { return }
        passwordResetMessage = nil
        Task {
            do {
                try await authRepo.resetPassword(email: authEmail)
                passwordResetMessage = "Se ha enviado un correo para cambiar tu contraseña"
                passwordResetIsError = false
            } catch {
                passwordResetMessage = error.localizedDescription
                passwordResetIsError = true
            }
        }
    }

    func deleteAccount() {
        Task {
            do {
                try await authRepo.deleteAccount(email: email, password: deletePassword)
                deleteAccountSuccess = true
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}