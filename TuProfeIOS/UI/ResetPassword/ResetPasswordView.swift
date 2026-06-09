import SwiftUI

struct ResetPasswordView: View {
    @StateObject private var viewModel = ResetPasswordViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)

                    LogoSection()

                    Spacer().frame(height: 16)

                    Text("RECUPERAR CONTRASEÑA")
                        .font(.custom("BebasNeue-Regular", size: 22))
                        .foregroundColor(.verdetp2)

                    Spacer().frame(height: 16)

                    Text("Ingresa tu dirección de correo electrónico y te enviaremos un enlace para reestablecer tu contraseña")
                        .font(.system(size: 17))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 50)

                    Spacer().frame(height: 16)

                    AppTextField(
                        placeholder: "Email",
                        text: $viewModel.email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        autocorrect: false
                    )
                    .padding(.horizontal, 40)

                    Spacer().frame(height: 16)

                    if viewModel.showSuccess {
                        Text("Si el correo está registrado, recibirás un enlace")
                            .foregroundColor(.verdetp)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        Text(NSLocalizedString("Si no lo recibes, revisa tu carpeta de spam.", comment: ""))
                            .foregroundColor(.verdetp)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                    } else if viewModel.showError {
                        Text(LocalizedStringKey(viewModel.errorMessage))
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Spacer().frame(height: 16)

                    AppButton(
                        title: "ENVIAR ENLACE",
                        action: { viewModel.sendReset() },
                        isEnabled: !viewModel.isLoading,
                        isLoading: viewModel.isLoading
                    )

                    Spacer().frame(height: 24)

                    AppTextButton(title: "VOLVER", action: { navState.pop() })

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.showSuccess)
        .animation(.easeOut(duration: 0.3), value: viewModel.showError)
    }
}

@MainActor
class ResetPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var showError = false
    @Published var errorMessage = ""

    func sendReset() {
        guard !email.isEmpty else {
            showError = true
            errorMessage = "Por favor ingresa tu correo"
            return
        }
        isLoading = true
        Task {
            do {
                try await AuthRepository.shared.resetPassword(email: email)
                showSuccess = true
                showError = false
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    ResetPasswordView()
        .environmentObject(NavigationState())
}
