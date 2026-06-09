import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Auth errors matching Android error messages

enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case tooManyRequests
    case networkError
    case weakPassword
    case emailAlreadyInUse
    case emailNotVerified
    case requiresRecentLogin
    case googleSignInError
    case gitHubSignInError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:   return NSLocalizedString("Credenciales incorrectas", comment: "")
        case .userNotFound:         return NSLocalizedString("Usuario no encontrado", comment: "")
        case .tooManyRequests:      return NSLocalizedString("Demasiados intentos. Intenta más tarde", comment: "")
        case .networkError:         return NSLocalizedString("Error de conexión a internet", comment: "")
        case .weakPassword:         return NSLocalizedString("La contraseña es demasiado débil", comment: "")
        case .emailAlreadyInUse:    return NSLocalizedString("El usuario ya está registrado", comment: "")
        case .emailNotVerified:     return NSLocalizedString("Por favor verifica tu correo antes de iniciar sesión", comment: "")
        case .requiresRecentLogin:  return NSLocalizedString("Debes iniciar sesión nuevamente", comment: "")
        case .googleSignInError:    return NSLocalizedString("Error al iniciar sesión con Google", comment: "")
        case .gitHubSignInError:    return NSLocalizedString("Error al iniciar sesión con GitHub", comment: "")
        case .unknown(let msg):     return msg
        }
    }
}

// MARK: - AuthRepository

class AuthRepository {
    static let shared = AuthRepository()

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    var currentUserEmail: String? {
        Auth.auth().currentUser?.email
    }

    var isEmailVerified: Bool {
        Auth.auth().currentUser?.isEmailVerified ?? false
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            if !result.user.isEmailVerified {
                try? Auth.auth().signOut()
                throw AuthError.emailNotVerified
            }
        } catch let error as NSError {
            throw mapFirebaseError(error, default: "Error al iniciar sesión")
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async throws -> String {
        guard password.count >= 6 else { throw AuthError.weakPassword }
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            try await result.user.sendEmailVerification()
            return result.user.uid
        } catch let error as NSError {
            throw mapFirebaseError(error, default: "Error al registrar el usuario")
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Reset Password

    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw mapFirebaseError(error, default: "Error al enviar el enlace")
        }
    }

    // MARK: - Delete Account

    func deleteAccount(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.userNotFound }
        let userId = user.uid
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        do {
            try await user.reauthenticate(with: credential)
            try await Firestore.firestore().collection("users").document(userId).delete()
            try await user.delete()
        } catch let error as NSError {
            throw mapFirebaseError(error, default: "Error al eliminar la cuenta")
        }
    }

    // MARK: - Update profile photo URL

    func updateProfileImage(photoURL: URL) async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.userNotFound }
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.photoURL = photoURL
        try await changeRequest.commitChanges()
    }

    // MARK: - Google Sign-In (OAuth web flow, mirrors Android OAuthProvider)

    func signInWithGoogle() async throws {
        let provider = OAuthProvider(providerID: "google.com")
        let credential: AuthCredential = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                provider.getCredentialWith(nil) { credential, error in
                    if let _ = error {
                        continuation.resume(throwing: AuthError.googleSignInError)
                    } else if let credential {
                        continuation.resume(returning: credential)
                    } else {
                        continuation.resume(throwing: AuthError.googleSignInError)
                    }
                }
            }
        }
        do {
            try await Auth.auth().signIn(with: credential)
        } catch {
            throw AuthError.googleSignInError
        }
    }

    // MARK: - GitHub Sign-In

    func signInWithGitHub() async throws {
        let provider = OAuthProvider(providerID: "github.com")
        provider.scopes = ["user:email"]
        let credential: AuthCredential = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                provider.getCredentialWith(nil) { credential, error in
                    if let _ = error {
                        continuation.resume(throwing: AuthError.gitHubSignInError)
                    } else if let credential {
                        continuation.resume(returning: credential)
                    } else {
                        continuation.resume(throwing: AuthError.gitHubSignInError)
                    }
                }
            }
        }
        do {
            try await Auth.auth().signIn(with: credential)
        } catch {
            throw AuthError.gitHubSignInError
        }
    }

    // MARK: - Error mapping
    // Firebase iOS SDK 10+: error cases live in AuthErrorCode.Code, not AuthErrorCode directly

    private func mapFirebaseError(_ error: NSError, default defaultMessage: String) -> AuthError {
        guard let code = AuthErrorCode.Code(rawValue: error.code) else {
            return .unknown(defaultMessage)
        }
        switch code {
        case .wrongPassword, .invalidCredential, .invalidEmail:
            return .invalidCredentials
        case .userNotFound:
            return .userNotFound
        case .tooManyRequests:
            return .tooManyRequests
        case .networkError:
            return .networkError
        case .weakPassword:
            return .weakPassword
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .requiresRecentLogin:
            return .requiresRecentLogin
        default:
            return .unknown(defaultMessage)
        }
    }
}