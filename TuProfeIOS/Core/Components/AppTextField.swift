import SwiftUI

// MARK: - Outlined TextField matching Android TextFieldApp (Material OutlinedTextField)

struct AppTextField: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var autocorrect: Bool = true

    @FocusState private var isFocused: Bool
    private var isActive: Bool { isFocused || !text.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Floating label (appears above the field when active)
            Text(placeholder)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isFocused ? .verdetp : .gris)
                .padding(.leading, 20)
                .frame(height: 16)
                .opacity(isActive ? 1 : 0)

            ZStack(alignment: .leading) {
                // Inline placeholder when field is empty and not focused
                if !isActive {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundColor(.gris)
                        .padding(.leading, 16)
                        .allowsHitTesting(false)
                }

                TextField("", text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(!autocorrect)
                    .focused($isFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .background(Color.pastel)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .strokeBorder(
                        isFocused ? Color.verdetp : Color.bordeTuProfe,
                        lineWidth: 1.5
                    )
            )
        }
        .animation(.easeOut(duration: 0.15), value: isActive)
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Secure TextField (password with toggle)

struct AppSecureField: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    @Binding var isVisible: Bool

    @FocusState private var isFocused: Bool
    private var isActive: Bool { isFocused || !text.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(placeholder)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isFocused ? .verdetp : .gris)
                .padding(.leading, 20)
                .frame(height: 16)
                .opacity(isActive ? 1 : 0)

            ZStack(alignment: .leading) {
                HStack {
                    Group {
                        if isVisible {
                            TextField("", text: $text)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("", text: $text)
                                .textInputAutocapitalization(.never)
                        }
                    }
                    .focused($isFocused)

                    Button(action: { isVisible.toggle() }) {
                        Image(systemName: isVisible ? "eye" : "eye.slash")
                            .foregroundColor(.gris)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if !isActive {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundColor(.gris)
                        .padding(.leading, 16)
                        .allowsHitTesting(false)
                }
            }
            .background(Color.pastel)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .strokeBorder(
                        isFocused ? Color.verdetp : Color.bordeTuProfe,
                        lineWidth: 1.5
                    )
            )
        }
        .animation(.easeOut(duration: 0.15), value: isActive)
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Search Bar

struct SearchBarView: View {
    let placeholder: LocalizedStringKey
    @Binding var query: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.verdetp)
                .padding(.leading, 12)

            TextField(placeholder, text: $query)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !query.isEmpty {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 12)
            }
        }
        .padding(.vertical, 10)
        .background(Color.pastel)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    isFocused ? Color.verdetp : Color.clear,
                    lineWidth: 1.5
                )
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Large multiline TextField

struct AppTextEditor: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var minHeight: CGFloat = 100

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
            }
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: minHeight)
        }
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 1.5)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.15).ignoresSafeArea()
        VStack(spacing: 8) {
            AppTextField(placeholder: "Correo electrónico", text: .constant(""))
            AppTextField(placeholder: "Nombre", text: .constant("Jorge"))
            AppSecureField(placeholder: "Contraseña", text: .constant(""), isVisible: .constant(false))
            SearchBarView(placeholder: "Busca a TuProfe", query: .constant(""))
        }
        .padding(.vertical)
    }
}
