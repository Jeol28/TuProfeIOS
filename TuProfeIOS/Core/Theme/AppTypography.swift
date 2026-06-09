import SwiftUI

// MARK: - Custom fonts matching Android (BebasNeue + Montserrat)
// Add BebasNeue.ttf and Montserrat-Regular.ttf to Resources/Fonts/
// then declare them in Info.plist under "Fonts provided by application"

extension Font {
    // BebasNeue — used for headings and buttons in Android
    static func bebasNeue(size: CGFloat) -> Font {
        Font.custom("BebasNeue-Regular", size: size)
    }

    // Montserrat — used for body text (only ExtraBold weight available in bundle)
    static func montserrat(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .heavy, .black:
            return Font.custom("Montserrat-ExtraBold", size: size)
        case .semibold:
            return Font.custom("Montserrat-ExtraBold", size: size)
        case .medium:
            return Font.custom("Montserrat-Medium", size: size)
        default:
            return Font.custom("Montserrat-Regular", size: size)
        }
    }

    // Fallback to system font if custom fonts not available
    static func tpTitle(_ size: CGFloat = 36) -> Font {
        Font.system(size: size, weight: .heavy, design: .default)
    }

    static func tpButton(_ size: CGFloat = 18) -> Font {
        Font.system(size: size, weight: .bold, design: .rounded)
    }

    static func tpBody(_ size: CGFloat = 16) -> Font {
        Font.system(size: size, weight: .regular)
    }

    static func tpCaption(_ size: CGFloat = 13) -> Font {
        Font.system(size: size, weight: .regular)
    }
}

// MARK: - Text modifiers

extension View {
    func tpTitleStyle() -> some View {
        self.font(.system(size: 36, weight: .heavy))
            .foregroundColor(.verdetp)
    }

    func tpHeadlineStyle() -> some View {
        self.font(.system(size: 22, weight: .semibold))
    }

    func tpBodyStyle() -> some View {
        self.font(.system(size: 16, weight: .regular))
    }

    func tpCaptionStyle() -> some View {
        self.font(.system(size: 13, weight: .regular))
            .foregroundColor(.secondary)
    }
}