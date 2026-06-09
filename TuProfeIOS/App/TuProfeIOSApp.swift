import SwiftUI
import Firebase
import FirebaseMessaging
import UserNotifications

@main
struct TuProfeIOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

struct AppRootView: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        AppNavigationView()
            .preferredColorScheme(nil)
            .environment(\.locale, languageManager.currentLocale)
            .id(languageManager.refreshID)
    }
}
