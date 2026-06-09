import SwiftUI
import SDWebImageSwiftUI

// MARK: - LoginView (matches Android HomeScreen with staggered animations)

struct LoginView: View {
    let onLoginSuccess: () -> Void

    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var navState: NavigationState

    @State private var showLogo = false
    @State private var showForm = false
    @State private var showButtons = false

    var body: some View {
        ZStack {
            ScrollingBackgroundView()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)

                    // Logo section — first to appear
                    if showLogo {
                        LogoSection()
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    Spacer().frame(height: 40)

                    // Form section
                    if showForm {
                        LoginFormSection(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Error message
                    if viewModel.showError {
                        Text(LocalizedStringKey(viewModel.errorMessage))
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .transition(.opacity)
                    }

                    Spacer().frame(height: 24)

                    // Buttons section
                    if showButtons {
                        LoginButtonsSection(
                            isLoading: viewModel.isLoading,
                            isGoogleLoading: viewModel.isGoogleLoading,
                            isGitHubLoading: viewModel.isGitHubLoading,
                            onLogin: { viewModel.loginClick() },
                            onForgotPassword: {
                                navState.navigate(to: .passwordReset)
                            },
                            onRegister: {
                                navState.navigate(to: .register)
                            },
                            onGoogle: { viewModel.signInWithGoogle() },
                            onGitHub: { viewModel.signInWithGitHub() }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear { startAnimations() }
        .onChange(of: viewModel.navigateToMain) { isNav in
            if isNav { onLoginSuccess() }
        }
        .animation(.easeOut(duration: 0.4), value: viewModel.showError)
    }

    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5)) { showLogo = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.42)) { showForm = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.easeOut(duration: 0.38)) { showButtons = true }
        }
    }
}

// MARK: - Logo Section

struct LogoSection: View {
    @Environment(\.colorScheme) private var colorScheme
    private static let logoLight = Bundle.main.url(forResource: "img",      withExtension: "png")
    private static let logoDark  = Bundle.main.url(forResource: "img-dark", withExtension: "png")

    var body: some View {
        WebImage(url: colorScheme == .dark ? Self.logoDark ?? Self.logoLight : Self.logoLight)
            .resizable()
            .scaledToFit()
            .frame(width: 220)
    }
}

// MARK: - Form Section

struct LoginFormSection: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        VStack(spacing: 12) {
            AppTextField(
                placeholder: "Email",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                autocapitalization: .never,
                autocorrect: false
            )

            AppSecureField(
                placeholder: "Contraseña",
                text: $viewModel.password,
                isVisible: $viewModel.passwordVisible
            )
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Buttons Section (matches Android Botones)

struct LoginButtonsSection: View {
    let isLoading: Bool
    let isGoogleLoading: Bool
    let isGitHubLoading: Bool
    let onLogin: () -> Void
    let onForgotPassword: () -> Void
    let onRegister: () -> Void
    let onGoogle: () -> Void
    let onGitHub: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AppButton(
                title: "INICIAR SESIÓN",
                action: onLogin,
                isLoading: isLoading
            )

            Spacer().frame(height: 16)

            // Divider "o continúa con"
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(height: 1)
                Text(LocalizedStringKey("o continúa con"))
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .fixedSize()
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(height: 1)
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 12)

            // Social login buttons
            HStack(spacing: 12) {
                SocialLoginButton(
                    label: "Google",
                    icon: AnyView(GoogleIconBadge()),
                    isLoading: isGoogleLoading,
                    action: onGoogle,
                    containerColor: .white,
                    contentColor: Color(red: 0.235, green: 0.251, blue: 0.263),
                    borderColor: Color(red: 0.867, green: 0.867, blue: 0.867)
                )
                SocialLoginButton(
                    label: "GitHub",
                    icon: AnyView(GitHubIconBadge()),
                    isLoading: isGitHubLoading,
                    action: onGitHub,
                    containerColor: Color(red: 0.141, green: 0.161, blue: 0.18),
                    contentColor: .white,
                    borderColor: Color(red: 0.267, green: 0.302, blue: 0.337)
                )
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 44)

            HStack(spacing: 12) {
                loginSecondaryButton(title: "OLVIDÉ LA CONTRASEÑA", action: onForgotPassword)
                    .offset(x: -25)
                loginSecondaryButton(title: "CREAR CUENTA", action: onRegister)
                    .offset(x: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func loginSecondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(LocalizedStringKey(title))
                .font(.custom("BebasNeue-Regular", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 10)
        }
        .background(Color.verdetp)
        .clipShape(Capsule())
        .pressScaleEffect()
    }
}

// MARK: - Social Login Button

private struct SocialLoginButton: View {
    let label: String
    let icon: AnyView
    let isLoading: Bool
    let action: () -> Void
    let containerColor: Color
    let contentColor: Color
    let borderColor: Color

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: contentColor))
                        .scaleEffect(0.85)
                } else {
                    HStack(spacing: 8) {
                        icon
                        Text(label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(contentColor)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .disabled(isLoading)
        .background(containerColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .pressScaleEffect()
    }
}

// MARK: - Brand Icon Badges

private struct GoogleIconBadge: View {
    var body: some View {
        Image("ic_google")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
    }
}

private struct GitHubIconBadge: View {
    var body: some View {
        Image("ic_github")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
    }
}

#Preview {
    LoginView(onLoginSuccess: {})
        .environmentObject(NavigationState())
}
