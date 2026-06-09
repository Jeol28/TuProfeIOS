import SwiftUI

// MARK: - AyudaYSoporteView (matches Android AyudaYSoporteScreen)

struct AyudaYSoporteView: View {
    @EnvironmentObject var navState: NavigationState

    private let faqs: [(question: String, answer: String)] = [
        ("¿Cómo creo una reseña?", "Toca el botón + en la barra inferior. Busca al profesor, selecciona la materia, pon una calificación y escribe tu experiencia."),
        ("¿Puedo editar mi reseña?", "Sí. Ve a 'Mi historial' en tu perfil y toca 'Editar' en la reseña que quieres modificar."),
        ("¿Qué es el perfil anónimo?", "Con el perfil anónimo activado, tu nombre aparece como 'Anónimo' en todas tus reseñas y comentarios."),
        ("¿Cómo funciona el Resumen IA?", "En el perfil de un profesor, toca 'Resumen IA'. Usamos Llama 3.3 70B para generar un análisis de todas las reseñas."),
        ("¿Cómo sigo a otros usuarios?", "Ve al perfil de otro usuario y toca el botón 'Seguir'. Sus reseñas aparecerán en tu pestaña 'Siguiendo'."),
        ("¿Cómo elimino mi cuenta?", "Ve a 'Editar perfil' y al final de la página encontrarás la opción 'Eliminar cuenta'. Esta acción es irreversible."),
        ("¿Cómo veo el mapa de reseñas?", "Toca el ícono del mapa en la barra inferior. Las reseñas con ubicación aparecerán como marcadores de colores según su calificación."),
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        TitleHeader(title: "Ayuda y soporte")
                        Text("Preguntas frecuentes")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    // FAQ list
                    VStack(spacing: 12) {
                        ForEach(faqs.indices, id: \.self) { i in
                            FAQCard(question: faqs[i].question, answer: faqs[i].answer)
                                .animatedEntrance(delay: Double(i) * 0.06)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Contact
                    VStack(spacing: 12) {
                        Divider().padding(.top, 24)

                        Text("¿No encontraste lo que buscabas?")
                            .font(.system(size: 15, weight: .semibold))

                        Link(destination: URL(string: "mailto:soporte@tuprofe.com")!) {
                            Label("Contactar soporte", systemImage: "envelope")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.verdetp)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            TuProfeTopBarView()
        }
    }
}

// MARK: - FAQ expandable card

struct FAQCard: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(LocalizedStringKey(question))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.verdetp)
                        .font(.system(size: 14))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Divider().padding(.horizontal, 16)
                Text(LocalizedStringKey(answer))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    AyudaYSoporteView()
        .environmentObject(NavigationState())
}