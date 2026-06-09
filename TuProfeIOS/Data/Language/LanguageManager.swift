import Foundation
import SwiftUI
import ObjectiveC

// MARK: - Bundle swizzling for in-app language switching

private var languageBundleKey: UInt8 = 0

private class BundleEx: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let langBundle = objc_getAssociatedObject(self, &languageBundleKey) as? Bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return langBundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

private extension Bundle {
    static func applyLanguage(_ code: String) {
        object_setClass(Bundle.main, BundleEx.self)
        let resolved = code.isEmpty ? LanguageManager.systemLanguageCode() : code
        if let path = Bundle.main.path(forResource: resolved, ofType: "lproj"),
           let b = Bundle(path: path) {
            objc_setAssociatedObject(Bundle.main, &languageBundleKey, b, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            objc_setAssociatedObject(Bundle.main, &languageBundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - LanguageManager

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    static let supported: [(code: String, label: String)] = [
        ("",   "Sistema"),
        ("es", "Español"),
        ("en", "English"),
        ("fr", "Français"),
        ("pt", "Português"),
        ("ar", "العربية"),
        ("de", "Deutsch"),
        ("it", "Italiano"),
        ("ja", "日本語"),
        ("ko", "한국어"),
        ("ru", "Русский"),
        ("hi", "हिन्दी"),
        ("th", "ภาษาไทย"),
        ("vi", "Tiếng Việt"),
        ("zh", "中文"),
        ("nl", "Nederlands"),
        ("pl", "Polski"),
        ("sv", "Svenska"),
        ("tr", "Türkçe")
    ]

    @Published var selectedCode: String
    @Published var refreshID: UUID = UUID()

    var currentLocale: Locale {
        selectedCode.isEmpty ? .current : Locale(identifier: selectedCode)
    }

    static func systemLanguageCode() -> String {
        let preferred = Locale.preferredLanguages.first ?? "es"
        let langCode = Locale(identifier: preferred).language.languageCode?.identifier ?? "es"
        let supportedCodes = Set(supported.compactMap { $0.code.isEmpty ? nil : $0.code })
        return supportedCodes.contains(langCode) ? langCode : "es"
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "selected_language") ?? ""
        selectedCode = saved
        Bundle.applyLanguage(saved)
    }

    func setLanguage(_ code: String) {
        guard code != selectedCode else { return }
        selectedCode = code
        Bundle.applyLanguage(code)
        UserDefaults.standard.set(code, forKey: "selected_language")
        if code.isEmpty {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
        refreshID = UUID()
    }
}
