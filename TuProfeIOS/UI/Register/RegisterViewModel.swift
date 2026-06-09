import Foundation

@MainActor
class RegisterViewModel: ObservableObject {
    @Published var email = ""
    @Published var usuario = ""
    @Published var carrera = ""
    @Published var password1 = ""
    @Published var password2 = ""
    @Published var passwordVisible = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var showSuccessDialog = false
    @Published var navigateHome = false

    private let authRepo = AuthRepository.shared
    private let userRepo = UserRepository.shared

    func onRegisterClickSecure() {
        guard !email.isEmpty, !usuario.isEmpty, !carrera.isEmpty,
              !password1.isEmpty, !password2.isEmpty else {
            showError(message: "Por favor completa todos los campos")
            return
        }
        guard password1 == password2 else {
            showError(message: "Las contraseñas no coinciden")
            return
        }
        guard password1.count >= 6 else {
            showError(message: "La contraseña debe tener al menos 6 caracteres")
            return
        }

        isLoading = true
        showError = false

        Task {
            do {
                let uid = try await authRepo.signUp(email: email, password: password1)
                try await userRepo.registerUser(
                    userId: uid,
                    username: usuario,
                    email: email,
                    carrera: carrera
                )
                try? authRepo.signOut()
                showSuccessDialog = true
            } catch let error as AuthError {
                showError(message: error.localizedDescription ?? "Error en el registro")
            } catch {
                showError(message: error.localizedDescription)
            }
            isLoading = false
        }
    }

    func onSuccessDialogDismissed() {
        showSuccessDialog = false
        navigateHome = true
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}