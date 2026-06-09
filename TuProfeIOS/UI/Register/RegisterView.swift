import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)

                    LogoSection()

                    Spacer().frame(height: 16)

                    Text("REGISTRARSE")
                        .font(.custom("BebasNeue-Regular", size: 25))
                        .foregroundColor(.verdetp2)

                    Spacer().frame(height: 16)

                    if viewModel.showError {
                        Text(LocalizedStringKey(viewModel.errorMessage))
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    VStack(spacing: 0) {
                        AppTextField(
                            placeholder: "Email",
                            text: $viewModel.email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            autocorrect: false
                        )
                        AppTextField(
                            placeholder: "Usuario",
                            text: $viewModel.usuario,
                            autocapitalization: .never
                        )
                        AppTextField(
                            placeholder: "Carrera",
                            text: $viewModel.carrera
                        )
                        AppSecureField(
                            placeholder: "Contraseña",
                            text: $viewModel.password1,
                            isVisible: $viewModel.passwordVisible
                        )
                        AppSecureField(
                            placeholder: "Repetir Contraseña",
                            text: $viewModel.password2,
                            isVisible: $viewModel.passwordVisible
                        )
                    }
                    .padding(.horizontal, 40)

                    Spacer().frame(height: 16)

                    AppButton(
                        title: "REGISTRARSE",
                        action: { viewModel.onRegisterClickSecure() },
                        isEnabled: !viewModel.isLoading,
                        isLoading: viewModel.isLoading
                    )

                    Spacer().frame(height: 8)

                    AppTextButton(title: "VOLVER", action: { navState.pop() })

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onChange(of: viewModel.navigateHome) { nav in
            if nav { navState.pop() }
        }
        .alert("¡Cuenta creada!", isPresented: $viewModel.showSuccessDialog) {
            Button("Aceptar") { viewModel.onSuccessDialogDismissed() }
        } message: {
            Text("Por favor, verifica tu correo para activar tu cuenta." + "\n\n" + NSLocalizedString("Si no lo recibes, revisa tu carpeta de spam.", comment: ""))
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.showError)
    }
}

#Preview {
    RegisterView()
        .environmentObject(NavigationState())
}
