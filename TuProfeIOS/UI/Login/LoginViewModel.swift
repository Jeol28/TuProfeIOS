import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var passwordVisible = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var navigateToMain = false
    @Published var isGoogleLoading = false
    @Published var isGitHubLoading = false

    private let authRepo = AuthRepository.shared

    func setEmail(_ value: String) { email = value }
    func setPassword(_ value: String) { password = value }
    func togglePasswordVisibility() { passwordVisible.toggle() }

    func loginClick() {
        guard !email.isEmpty, !password.isEmpty else {
            showError(message: "Por favor complete todos los campos")
            return
        }

        isLoading = true
        showError = false

        Task {
            do {
                try await authRepo.signIn(email: email, password: password)
                navigateToMain = true
            } catch let error as AuthError {
                showError(message: error.localizedDescription ?? "Error desconocido")
            } catch {
                showError(message: error.localizedDescription)
            }
            isLoading = false
        }
    }

    func signInWithGoogle() {
        isGoogleLoading = true
        showError = false
        Task {
            do {
                try await authRepo.signInWithGoogle()
                navigateToMain = true
            } catch {
                showError(message: error.localizedDescription)
            }
            isGoogleLoading = false
        }
    }

    func signInWithGitHub() {
        isGitHubLoading = true
        showError = false
        Task {
            do {
                try await authRepo.signInWithGitHub()
                navigateToMain = true
            } catch {
                showError(message: error.localizedDescription)
            }
            isGitHubLoading = false
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}