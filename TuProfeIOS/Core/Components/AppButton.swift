import SwiftUI

// MARK: - Primary Button (matches Android AppButton with BebasNeue)

struct AppButton: View {
    let title: LocalizedStringKey
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(height: 20)
                } else {
                    Text(title)
                        .font(.custom("BebasNeue-Regular", size: 20))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
            }
            .frame(minWidth: 160, minHeight: 44)
        }
        .background(isEnabled ? Color.verdetp : Color.gray)
        .clipShape(Capsule())
        .disabled(!isEnabled || isLoading)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Row Button (smaller, for "Olvidé contraseña" / "Crear cuenta")

struct AppButtonRow: View {
    let title: LocalizedStringKey
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("BebasNeue-Regular", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .background(Color.verdetp)
        .clipShape(Capsule())
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Text Button with underline (AppTextButton)

struct AppTextButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .underline()
                .foregroundColor(.verdetp2)
        }
    }
}

// MARK: - Icon Button

struct TpIconButton: View {
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AppButton(title: "INICIAR SESIÓN", action: {})
        AppButtonRow(title: "CREAR CUENTA", action: {})
        AppTextButton(title: "Olvidé mi contraseña", action: {})
        AppButton(title: "CARGANDO", action: {}, isLoading: true)
    }
    .padding()
}