import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - TuProfe Color Palette

extension Color {
    // Fixed greens (same in light and dark)
    static let verdetp  = Color(hex: "1AC06A")   // R.color.verdetp — always green
    static let tpPrimary           = Color(hex: "006D38")
    static let tpPrimaryDark       = Color(hex: "4BE086")
    static let tpPrimaryContainer  = Color(hex: "1AC06A")
    static let tpOnPrimaryContainer = Color(hex: "004723")
    static let tpBackgroundLight   = Color(hex: "F3FCF1")
    static let tpBackgroundDark    = Color(hex: "0E150F")
    static let tpSurfaceLight      = Color(hex: "FFF9ED")
    static let tpSurfaceDark       = Color(hex: "141312")
    static let tpSecondaryLight    = Color(hex: "615E54")
    static let tpSecondaryContainerLight = Color(hex: "FBF5E7")
    static let tpOutlineLight      = Color(hex: "6C7B6E")
    static let tpOutlineVariantLight = Color(hex: "BBCABB")
    static let tpOutlineDark       = Color(hex: "869487")
    static let tpError             = Color(hex: "BA1A1A")
    static let tpErrorDark         = Color(hex: "FFB4AB")
    // BordeTuProfe has no night override in Android — same in both modes
    static let bordeTuProfe = Color(hex: "E2D3B5")

    // MARK: - Adaptive (light → dark matching Android values-night/colors.xml)

    // pastel: #FFF9ED light → #2C2C2C dark
    static let pastel = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0x2C/255.0, green: 0x2C/255.0, blue: 0x2C/255.0, alpha: 1)
            : UIColor(red: 0xFF/255.0, green: 0xF9/255.0, blue: 0xED/255.0, alpha: 1)
    })

    // gris: #B3B3B3 light → #8A8A8A dark
    static let gris = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0x8A/255.0, green: 0x8A/255.0, blue: 0x8A/255.0, alpha: 1)
            : UIColor(red: 0xB3/255.0, green: 0xB3/255.0, blue: 0xB3/255.0, alpha: 1)
    })

    // verdetp2: #1AC06A light → #FFFFFF dark (used for title text)
    static let verdetp2 = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? .white
            : UIColor(red: 0x1A/255.0, green: 0xC0/255.0, blue: 0x6A/255.0, alpha: 1)
    })

    // tpSurfaceVariantLight: #D7E7D7 light → #3D4A3E dark (shimmer / skeleton backgrounds)
    static let tpSurfaceVariantLight = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0x3D/255.0, green: 0x4A/255.0, blue: 0x3E/255.0, alpha: 1)
            : UIColor(red: 0xD7/255.0, green: 0xE7/255.0, blue: 0xD7/255.0, alpha: 1)
    })
}

// MARK: - Adaptive helpers

struct AppColor {
    static func primary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .tpPrimaryDark : .tpPrimary
    }
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .tpBackgroundDark : .tpBackgroundLight
    }
    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .tpSurfaceDark : .tpSurfaceLight
    }
    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .tpSurfaceVariantLight : .tpOutlineVariantLight
    }
}
