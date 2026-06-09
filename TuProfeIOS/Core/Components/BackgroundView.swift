import SwiftUI

// MARK: - Background matching Android BackgroundImage composable

struct AppBackgroundView: View {
    var body: some View {
        ScrollingBackgroundView()
    }
}

// MARK: - Screen wrapper that applies the background

struct TuProfeBackground<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppBackgroundView()
            content
        }
    }
}

// MARK: - Shimmer effect modifier (matches Android shimmerEffect())

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: phase - 0.3),
                        .init(color: .white.opacity(0.55), location: phase),
                        .init(color: .clear, location: phase + 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.3)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.4
                }
            }
    }
}

extension View {
    func shimmerEffect() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Press scale effect modifier (matches Android pressScaleEffect)

// ButtonStyle-based press scale — safe to use inside ScrollView (no DragGesture conflict)
struct CardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Kept for non-scroll contexts (buttons outside lists)
struct PressScaleEffect: ViewModifier {
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .updating($isPressed) { _, state, _ in state = true }
            )
    }
}

extension View {
    func pressScaleEffect() -> some View {
        modifier(PressScaleEffect())
    }
}

// MARK: - Screen entrance animation (matches Android AnimatedScreen)

struct AnimatedEntrance: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func animatedEntrance(delay: Double = 0) -> some View {
        modifier(AnimatedEntrance(delay: delay))
    }
}

// MARK: - List item staggered animation (matches Android AnimatedListItem)

struct AnimatedListItem: ViewModifier {
    let index: Int
    @State private var appeared = false

    var delay: Double { Double(min(index, 8)) * 0.06 }

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .onAppear {
                withAnimation(.easeOut(duration: 0.35).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func animatedListItem(index: Int) -> some View {
        modifier(AnimatedListItem(index: index))
    }
}

#Preview {
    TuProfeBackground {
        VStack {
            Text("TuProfe")
                .font(.largeTitle)
                .foregroundColor(.verdetp)
        }
    }
}