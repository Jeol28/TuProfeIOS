import SwiftUI

// MARK: - MainView (matches Android MainScreen with tabs + sort)

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @EnvironmentObject var navState: NavigationState

    private let tabs: [LocalizedStringKey] = ["Para ti", "Siguiendo"]

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                TuProfeTopBarView()

                if viewModel.isLoading {
                    ReviewListSkeleton(count: 5)
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(LocalizedStringKey(error))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        AppButton(title: "Reintentar", action: { viewModel.fetchReviews() })
                        Spacer()
                    }
                } else {
                    FeedTabBar(
                        selectedTab: $viewModel.selectedTab,
                        tabs: tabs,
                        sortOrder: viewModel.sortOrder,
                        onSortSelected: { viewModel.setSortOrder($0) }
                    )

                    if viewModel.selectedTab == 0 {
                        ReviewFeedList(
                            reviews: viewModel.currentList,
                            onReviewTap: { id in navState.navigate(to: .detalle(reviewId: id)) },
                            onProfessorTap: { id in navState.navigate(to: .profe(profeId: id)) },
                            onUserTap: { id in navState.navigate(to: .profile(userId: id)) },
                            onLikeTap: { id in viewModel.toggleLike(reviewId: id) }
                        )
                    } else {
                        FollowingFeedList(
                            reviews: viewModel.followingReviews,
                            onReviewTap: { id in navState.navigate(to: .detalle(reviewId: id)) },
                            onProfessorTap: { id in navState.navigate(to: .profe(profeId: id)) },
                            onUserTap: { id in navState.navigate(to: .profile(userId: id)) },
                            onLikeTap: { id in viewModel.toggleLike(reviewId: id) }
                        )
                    }
                }
            }
        }
        .onAppear { viewModel.fetchReviews() }
        .onChange(of: viewModel.selectedTab) { tab in
            if tab == 1 { viewModel.refreshFollowingReviews() }
        }
    }
}

// MARK: - Feed Tab Bar (matches Android FeedTabBar)

struct FeedTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [LocalizedStringKey]
    let sortOrder: SortOrder
    let onSortSelected: (SortOrder) -> Void

    @State private var showSortMenu = false

    var body: some View {
        HStack(spacing: 0) {
            // Tab pills — fills all remaining space (weight(1f) equivalent)
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { index in
                    Button(action: { selectedTab = index }) {
                        VStack(spacing: 0) {
                            Text(tabs[index])
                                .font(.system(size: 15, weight: selectedTab == index ? .bold : .regular))
                                .foregroundColor(selectedTab == index ? .verdetp : .secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)

                            Rectangle()
                                .fill(selectedTab == index ? Color.verdetp : Color.clear)
                                .frame(height: 2)
                                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(maxWidth: .infinity)

            // Sort button — fixed width, no spacer
            Button(action: { showSortMenu = true }) {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundColor(sortOrder != .recientes ? .verdetp : .secondary)
                    .frame(width: 48, height: 48)
            }
            .confirmationDialog("Ordenar por", isPresented: $showSortMenu) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button(action: { onSortSelected(order) }) {
                        Label(
                            LocalizedStringKey(order.rawValue),
                            systemImage: sortOrder == order ? "checkmark" : ""
                        )
                    }
                }
            }
        }
        .frame(height: 48)
        .background(Color.pastel.opacity(0.95))
    }
}

// MARK: - Review feed list

struct ReviewFeedList: View {
    let reviews: [ReviewInfo]
    let onReviewTap: (String) -> Void
    let onProfessorTap: (String) -> Void
    let onUserTap: (String) -> Void
    var onLikeTap: ((String) -> Void)? = nil

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(reviews.enumerated()), id: \.element.id) { index, review in
                    ReviewCardView(
                        review: review,
                        onTap: { onReviewTap(review.reviewId) },
                        onProfessorTap: { onProfessorTap(review.profesor.profeId) },
                        onUserTap: { onUserTap(review.usuario.id) },
                        onLike: { onLikeTap?(review.reviewId) }
                    )
                    .animatedListItem(index: index)
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 110)
        }
    }
}

// MARK: - Following feed (empty state)

struct FollowingFeedList: View {
    let reviews: [ReviewInfo]
    let onReviewTap: (String) -> Void
    let onProfessorTap: (String) -> Void
    let onUserTap: (String) -> Void
    var onLikeTap: ((String) -> Void)? = nil

    var body: some View {
        if reviews.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "person.2.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Aún no sigues a nadie\no las personas que sigues no han publicado reseñas")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
        } else {
            ReviewFeedList(
                reviews: reviews,
                onReviewTap: onReviewTap,
                onProfessorTap: onProfessorTap,
                onUserTap: onUserTap,
                onLikeTap: onLikeTap
            )
        }
    }
}

#Preview {
    MainView()
        .environmentObject(NavigationState())
}