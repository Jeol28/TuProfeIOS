import SwiftUI

// MARK: - ProfeView (matches Android ProfeScreen + ProfeContent)

struct ProfeView: View {
    let profeId: String
    @StateObject private var viewModel = ProfeViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            if viewModel.isLoading {
                VStack {
                    ProfessorInfoCardSkeleton()
                    ReviewListSkeleton(count: 3)
                }
            } else if let profesor = viewModel.profesor {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Professor info card
                        ProfessorInfoCard(
                            professorName: profesor.nombreProfe,
                            generalRating: viewModel.averageRating,
                            professorImageUrl: profesor.imageprofeUrl,
                            departamento: profesor.departamento
                        )
                        .animatedEntrance(delay: 0)

                        // AI Summary section
                        IASection(viewModel: viewModel)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)

                        // Section header
                        Text("Reseñas de alumnos")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.verdetp)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                        // Reviews
                        ForEach(Array(viewModel.professorReviews.enumerated()), id: \.element.id) { index, review in
                            ReviewCardView(
                                review: review,
                                onTap: { navState.navigate(to: .detalle(reviewId: review.reviewId)) },
                                onProfessorTap: { navState.navigate(to: .profe(profeId: review.profesor.profeId)) },
                                onUserTap: { navState.navigate(to: .profile(userId: review.usuario.id)) },
                                onLike: { viewModel.toggleLike(reviewId: review.reviewId) }
                            )
                            .animatedListItem(index: index)
                        }

                        Spacer().frame(height: 110)
                    }
                }
            } else {
                Text("Profesor no encontrado")
                    .foregroundColor(.secondary)
            }
        }
        .safeAreaInset(edge: .top) {
            TuProfeTopBarView()
        }
        .onAppear { viewModel.cargarDatos(profeId: profeId) }
    }
}

// MARK: - AI Summary section (matches Android IASection + ResumenIACard)

struct IASection: View {
    @ObservedObject var viewModel: ProfeViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            if viewModel.isLoadingIA {
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(.verdetp)
                    Text("Analizando reseñas...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if let resumen = viewModel.resumenIA {
                ResumenIACard(resumen: resumen)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                AppButton(
                    title: "RESUMEN IA",
                    action: { viewModel.generarResumenIA() }
                )
                .frame(maxWidth: .infinity)

                if let errorIA = viewModel.errorIA {
                    Text(LocalizedStringKey(errorIA))
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                }
            }
        }
        .animation(.easeOut(duration: 0.4), value: viewModel.resumenIA)
    }
}

// MARK: - AI Summary card (matches Android ResumenIACard)

struct ResumenIACard: View {
    let resumen: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.verdetp)
                    .font(.system(size: 18))
                Text("Resumen de Inteligencia Artificial")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.verdetp)
            }

            Text(resumen)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineSpacing(4)

            HStack {
                Spacer()
                Text("Generado por Llama 3.3 70B en Groq")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [.verdetp, .verdetp2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Professor info card (matches Android ProfessorInfoCard)

struct ProfessorInfoCard: View {
    let professorName: String
    let generalRating: Float
    let professorImageUrl: String?
    var departamento: String = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                ProfessorImageView(url: professorImageUrl, size: 110, isViewable: true)

                Text(professorName)
                    .font(.system(size: 22, weight: .semibold))
                    .multilineTextAlignment(.center)

                if !departamento.isEmpty {
                    Text(departamento)
                        .font(.system(size: 14))
                        .foregroundColor(.verdetp2)
                }

                StarRatingView(rating: Double(generalRating), starColor: .verdetp, starSize: 22)

                if generalRating > 0 {
                    Text(String(format: "%.1f", generalRating))
                        .font(.system(size: 14))
                        .foregroundColor(.verdetp2)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Skeleton for professor card

struct ProfessorInfoCardSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.tpSurfaceVariantLight)
                .frame(width: 110, height: 110)
                .shimmerEffect()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.tpSurfaceVariantLight)
                .frame(width: 160, height: 18)
                .shimmerEffect()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.tpSurfaceVariantLight)
                .frame(width: 100, height: 12)
                .shimmerEffect()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.tpSurfaceVariantLight)
                .frame(width: 120, height: 20)
                .shimmerEffect()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Color.bordeTuProfe.opacity(0.35), lineWidth: 2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    ProfeView(profeId: "test123")
        .environmentObject(NavigationState())
}