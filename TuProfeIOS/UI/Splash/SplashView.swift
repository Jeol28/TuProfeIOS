import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI

// MARK: - SplashView (matches Android SplashScreen)

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onComplete: (Bool) -> Void

    var body: some View {
        ZStack {
            ScrollingBackgroundView()
            AnimatedImage(name: colorScheme == .dark ? "loading_logo-dark.gif" : "loading_logo.gif")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
        }
        .ignoresSafeArea()
        .onAppear { checkAuthAndNavigate() }
    }

    private func checkAuthAndNavigate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete(Auth.auth().currentUser != nil)
        }
    }
}

// MARK: - Scrolling background (matches Android BackgroundImage composable)

struct ScrollingBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    private static let duration: TimeInterval = 60

    private static func loadImage(named name: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "jpeg"),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return UIImage(named: name)
    }

    private static let fondoLight: UIImage? = loadImage(named: "fondo")
    private static let fondoDark: UIImage?  = loadImage(named: "fondo-dark")

    private var fondo: UIImage? {
        colorScheme == .dark ? Self.fondoDark ?? Self.fondoLight : Self.fondoLight
    }

    var body: some View {
        TimelineView(.animation) { tl in
            let elapsed = tl.date.timeIntervalSinceReferenceDate
            let progress = CGFloat(elapsed.truncatingRemainder(dividingBy: Self.duration) / Self.duration)
            GeometryReader { geo in
                let h = geo.size.height
                let offsetY = progress * h
                if let img = fondo {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: h)
                        .clipped()
                        .offset(y: offsetY)
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: h)
                        .clipped()
                        .offset(y: offsetY - h)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView(onComplete: { _ in })
}