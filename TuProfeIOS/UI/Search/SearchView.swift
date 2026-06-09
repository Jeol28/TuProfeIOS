import SwiftUI

// MARK: - SearchView (matches Android SearchScreen)

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                TuProfeTopBarView()

                // Search bar only — no TitleHeader (matches Android SearchHeader)
                SearchBarView(
                    placeholder: "Busca a TuProfe",
                    query: $viewModel.searchQuery
                )
                .padding(.vertical, 16)

                // Content
                if viewModel.isLoading {
                    ReviewListSkeleton(count: 5)
                } else if viewModel.searchResults.isEmpty {
                    SearchEmptyState(query: viewModel.searchQuery)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            SearchResultsCount(count: viewModel.searchResults.count)

                            ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, profesor in
                                ProfessorCard(
                                    profesor: profesor,
                                    rating: viewModel.ratings[profesor.id] ?? 0,
                                    onTap: { navState.navigate(to: .profe(profeId: profesor.profeId)) }
                                )
                                .animatedListItem(index: index)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .onAppear { viewModel.cargarTodosLosProfesores() }
    }
}

// MARK: - Empty state (matches Android SearchEmptyState)

private struct SearchEmptyState: View {
    let query: String

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gris)
            Group {
                if query.isEmpty {
                    Text("Busca a tu profe favorito")
                } else {
                    Text("No se encontraron resultados\npara \"\(query)\"")
                }
            }
            .font(.system(size: 15))
            .foregroundColor(.gris)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            Spacer()
        }
    }
}

// MARK: - Results count (matches Android SearchResultsCount)

private struct SearchResultsCount: View {
    let count: Int

    var body: some View {
        Group {
            if count == 1 {
                Text("1 profesor encontrado")
            } else {
                Text("\(count) profesores encontrados")
            }
        }
        .font(.system(size: 13))
        .foregroundColor(.gris)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 4)
        .padding(.bottom, 4)
    }
}

// MARK: - Professor card (matches Android ProfessorCard)

struct ProfessorCard: View {
    let profesor: Profesor
    let rating: Float
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ProfileImageView(url: profesor.imageprofeUrl, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(profesor.nombreProfe)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if !profesor.departamento.isEmpty {
                        Text(profesor.departamento)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    StarRatingView(rating: Double(rating), starSize: 18)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.pastel)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(Color.bordeTuProfe, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(CardPressButtonStyle())
    }
}

// MARK: - SearchViewModel

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery = "" {
        didSet { filterResults() }
    }
    @Published var searchResults: [Profesor] = []
    @Published var ratings: [String: Float] = [:]
    @Published var isLoading = false

    private var allProfessors: [Profesor] = []
    private let professorRepo = ProfessorRepository.shared

    func cargarTodosLosProfesores() {
        guard allProfessors.isEmpty else { return }
        isLoading = true
        Task {
            do {
                let professors = try await professorRepo.getAllProfessors()
                allProfessors = professors
                searchResults = professors

                await withTaskGroup(of: (String, Float).self) { group in
                    for prof in professors {
                        group.addTask {
                            let rating = (try? await ProfessorRepository.shared.getAverageRating(for: prof.id)) ?? 0
                            return (prof.id, rating)
                        }
                    }
                    for await (id, rating) in group {
                        ratings[id] = rating
                    }
                }
            } catch {
                searchResults = []
            }
            isLoading = false
        }
    }

    private func filterResults() {
        if searchQuery.isEmpty {
            searchResults = allProfessors
        } else {
            let query = searchQuery.lowercased()
            searchResults = allProfessors.filter {
                $0.nombreProfe.lowercased().contains(query) ||
                $0.departamento.lowercased().contains(query) ||
                $0.materias.contains { $0.lowercased().contains(query) }
            }
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(NavigationState())
}
