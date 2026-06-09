import SwiftUI
import UIKit

// MARK: - Enable swipe-back gesture when navigation bar is hidden

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}

// MARK: - Navigation routes (equivalent to Android Screen sealed class)

enum AppRoute: Hashable {
    case splash
    case login
    case register
    case passwordReset
    case main
    case search
    case profe(profeId: String)
    case historial
    case loading
    case mapa
    case createReview
    case editReview(reviewId: String)
    case configPerfil
    case configuracion
    case detalle(reviewId: String)
    case profile(userId: String)
    case commentDetalle(commentId: String)
    case editComment(commentId: String)
    case ayudaYSoporte
    case notificaciones
    case notifInbox
    case ajustes
    case chatList
    case chat(chatId: String, otherUserId: String)
    case payment
}

// MARK: - Tab bar items (equivalent to Android bottomNavItems)

enum TabItem: Int, CaseIterable {
    case home = 0
    case search = 1
    case map = 2
    case profile = 3

    var icon: (selected: String, unselected: String) {
        switch self {
        case .home: return ("house.fill", "house")
        case .search: return ("magnifyingglass", "magnifyingglass")
        case .map: return ("map.fill", "map")
        case .profile: return ("person.fill", "person")
        }
    }
}

// MARK: - Navigation State

class NavigationState: ObservableObject {
    @Published var path = NavigationPath()          // auth flow
    @Published var homePath = NavigationPath()
    @Published var searchPath = NavigationPath()
    @Published var mapaPath = NavigationPath()
    @Published var configPath = NavigationPath()
    @Published var selectedTab: TabItem = .home
    @Published var showCreateReview = false
    @Published var isAuthenticated = false {
        didSet { if isAuthenticated { flushPendingDeepLink() } }
    }
    private var pendingDeepLink: AppRoute? = nil
    private var deepLinkObserver: NSObjectProtocol?

    init() {
        deepLinkObserver = NotificationCenter.default.addObserver(
            forName: .openNotifInbox, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.isAuthenticated {
                self.selectedTab = .profile
                self.configPath.append(AppRoute.notifInbox)
            } else {
                self.pendingDeepLink = .notifInbox
            }
        }
    }

    deinit {
        if let obs = deepLinkObserver { NotificationCenter.default.removeObserver(obs) }
    }

    private func flushPendingDeepLink() {
        guard let link = pendingDeepLink else { return }
        pendingDeepLink = nil
        selectedTab = .profile
        configPath.append(link)
    }

    func navigate(to route: AppRoute) {
        guard isAuthenticated else { path.append(route); return }
        switch selectedTab {
        case .home:    homePath.append(route)
        case .search:  searchPath.append(route)
        case .map:     mapaPath.append(route)
        case .profile: configPath.append(route)
        }
    }

    func popToRoot() {
        path = NavigationPath()
        homePath = NavigationPath()
        searchPath = NavigationPath()
        mapaPath = NavigationPath()
        configPath = NavigationPath()
    }

    func popToRoot(tab: TabItem) {
        switch tab {
        case .home:    homePath = NavigationPath()
        case .search:  searchPath = NavigationPath()
        case .map:     mapaPath = NavigationPath()
        case .profile: configPath = NavigationPath()
        }
    }

    func handleTabTap(_ tab: TabItem) {
        if selectedTab == tab {
            popToRoot(tab: tab)
        } else {
            selectedTab = tab
        }
    }

    func pop() {
        guard isAuthenticated else { if !path.isEmpty { path.removeLast() }; return }
        switch selectedTab {
        case .home:    if !homePath.isEmpty    { homePath.removeLast() }
        case .search:  if !searchPath.isEmpty  { searchPath.removeLast() }
        case .map:     if !mapaPath.isEmpty    { mapaPath.removeLast() }
        case .profile: if !configPath.isEmpty  { configPath.removeLast() }
        }
    }
}

// MARK: - Main navigation container

struct AppNavigationView: View {
    @StateObject private var navState = NavigationState()
    @State private var showSplash = true

    var body: some View {
        if showSplash {
            SplashView(onComplete: { isAuth in
                navState.isAuthenticated = isAuth
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSplash = false
                }
            })
        } else if navState.isAuthenticated {
            MainTabView()
                .environmentObject(navState)
        } else {
            AuthNavigationView()
                .environmentObject(navState)
        }
    }
}

// MARK: - Auth navigation stack

struct AuthNavigationView: View {
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        NavigationStack(path: $navState.path) {
            LoginView(onLoginSuccess: {
                navState.isAuthenticated = true
            })
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .register:
            RegisterView()
        case .passwordReset:
            ResetPasswordView()
        default:
            EmptyView()
        }
    }
}

// MARK: - Main tab container (with FAB center button matching Android)

@MainActor
class ChatBadgeViewModel: ObservableObject {
    @Published var hasUnreadChats = false
    @Published var hasUnreadNotifs = false
    private let chatRepo = ChatRepository.shared
    private let notifRepo = NotificationRepository.shared
    private var chatTask: Task<Void, Never>?
    private var notifTask: Task<Void, Never>?

    func startListening() {
        let uid = AuthRepository.shared.currentUserId ?? ""
        guard !uid.isEmpty else { return }
        chatTask?.cancel()
        chatTask = Task {
            for await chats in chatRepo.listenChats(userId: uid) {
                hasUnreadChats = chats.contains { $0.unreadCount > 0 }
            }
        }
        notifTask?.cancel()
        notifTask = Task {
            for await count in notifRepo.listenUnreadCount(userId: uid) {
                hasUnreadNotifs = count > 0
            }
        }
    }
    deinit { chatTask?.cancel(); notifTask?.cancel() }
}

struct MainTabView: View {
    @EnvironmentObject var navState: NavigationState
    @StateObject private var badgeVM = ChatBadgeViewModel()

    var body: some View {
        TabView(selection: $navState.selectedTab) {
            MainTabStack()
                .tag(TabItem.home)
            SearchTabStack()
                .tag(TabItem.search)
            MapaTabStack()
                .tag(TabItem.map)
            ConfigTabStack()
                .tag(TabItem.profile)
        }
        .toolbar(.hidden, for: .tabBar)
        .ignoresSafeArea(.keyboard)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TuProfeTabBar(
                selectedTab: $navState.selectedTab,
                onCreateTap: { navState.showCreateReview = true },
                onTabTap: { navState.handleTabTap($0) },
                hasUnreadChats: badgeVM.hasUnreadChats,
                hasUnreadNotifs: badgeVM.hasUnreadNotifs
            )
        }
        .onAppear { badgeVM.startListening() }
        .sheet(isPresented: $navState.showCreateReview) {
            CreateReviewView(onSuccess: {
                navState.showCreateReview = false
            })
        }
    }
}

struct MainTabStack: View {
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        NavigationStack(path: $navState.homePath) {
            MainView()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self) { route in
                    routeView(route)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
    }
}

struct SearchTabStack: View {
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        NavigationStack(path: $navState.searchPath) {
            SearchView()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self) { route in
                    routeView(route)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
    }
}

struct MapaTabStack: View {
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        NavigationStack(path: $navState.mapaPath) {
            MapaView()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self) { route in
                    routeView(route)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
    }
}

struct ConfigTabStack: View {
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        NavigationStack(path: $navState.configPath) {
            ConfigView(onLogout: {
                navState.popToRoot()
                navState.isAuthenticated = false
            })
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                routeView(route)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}

// MARK: - Shared route builder

@ViewBuilder
func routeView(_ route: AppRoute) -> some View {
    switch route {
    case .profe(let profeId):
        ProfeView(profeId: profeId)
    case .detalle(let reviewId):
        DetalleView(reviewId: reviewId)
    case .profile(let userId):
        UserProfileView(userId: userId)
    case .commentDetalle(let commentId):
        CommentDetalleView(commentId: commentId)
    case .editReview(let reviewId):
        EditReviewView(reviewId: reviewId)
    case .editComment(let commentId):
        EditCommentView(commentId: commentId)
    case .historial:
        HistorialView()
    case .configPerfil:
        ConfigPerfilView()
    case .ayudaYSoporte:
        AyudaYSoporteView()
    case .notificaciones:
        NotificacionesView()
    case .notifInbox:
        NotifInboxView()
    case .ajustes:
        AjustesView()
    case .mapa:
        MapaView()
    case .chatList:
        ChatListView()
    case .chat(let chatId, let otherUserId):
        ChatView(chatId: chatId, otherUserId: otherUserId)
    case .payment:
        PaymentViewWrapper()
    default:
        EmptyView()
    }
}

// MARK: - PaymentViewWrapper (bridges NavigationState into PaymentView callbacks)

struct PaymentViewWrapper: View {
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        PaymentView(
            onBack: { navState.pop() },
            onSuccess: {
                navState.pop()
            }
        )
    }
}

// MARK: - Top App Bar (matches Android TuProfeTopBar)

struct TuProfeTopBarView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.pastel
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                Text("TuProfe")
                    .font(.custom("Montserrat-ExtraBold", size: 26))
                    .foregroundColor(.verdetp)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)

                LinearGradient(
                    colors: [
                        .clear,
                        Color.verdetp.opacity(0.18),
                        Color.verdetp.opacity(0.45),
                        Color.verdetp.opacity(0.18),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1.5)
            }
        }
        .frame(height: 56)
    }
}

// MARK: - Bottom Tab Bar (matches Android TuProfeBottomBar with elevated FAB center)

struct TuProfeTabBar: View {
    @Binding var selectedTab: TabItem
    let onCreateTap: () -> Void
    let onTabTap: (TabItem) -> Void
    var hasUnreadChats: Bool = false
    var hasUnreadNotifs: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            // Background that fills 56pt bar + bottom safe area
            Color.pastel
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)

            // Main bar buttons
            HStack(spacing: 0) {
                ForEach([TabItem.home, TabItem.search], id: \.self) { tab in
                    tabButton(tab)
                }

                Spacer().frame(width: 64) // space for FAB

                ForEach([TabItem.map, TabItem.profile], id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .frame(height: 56)

            // Elevated FAB center button
            Button(action: onCreateTap) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.verdetp)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 3)
                    )
                    .shadow(color: Color.verdetp.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .offset(y: -20)
        }
        .frame(height: 56)
    }

    private func tabButton(_ tab: TabItem) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: { onTabTap(tab) }) {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isSelected ? tab.icon.selected : tab.icon.unselected)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .verdetp : .gray)
                    if tab == .profile && (hasUnreadChats || hasUnreadNotifs) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}