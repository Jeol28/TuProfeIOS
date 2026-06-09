import SwiftUI
import UIKit

// MARK: - PaymentState

enum PaymentState: Equatable {
    case idle
    case loading
    case readyToPay(clientSecret: String)
    case success
    case error(String)
}

// MARK: - PaymentViewModel

@MainActor
class PaymentViewModel: ObservableObject {
    @Published var state: PaymentState = .idle

    private let repo = PaymentRepository.shared

    func startPayment() {
        guard state != .loading else { return }
        state = .loading
        Task {
            let result = await repo.createPaymentIntent()
            switch result {
            case .success(let clientSecret):
                state = .readyToPay(clientSecret: clientSecret)
                presentStripeSheet(clientSecret: clientSecret)
            case .failure(let error):
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Stripe Payment Sheet
    // Requires: File → Add Package Dependencies → https://github.com/stripe/stripe-ios
    // Add product "StripePaymentSheet" and uncomment the section below.
    //
    // import StripePaymentSheet
    //
    // private func presentStripeSheet(clientSecret: String) {
    //     var config = PaymentSheet.Configuration()
    //     config.merchantDisplayName = "TuProfe"
    //     let sheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
    //     guard let topVC = UIApplication.shared.topViewController else { return }
    //     sheet.present(from: topVC) { [weak self] result in
    //         switch result {
    //         case .completed: self?.onPaymentSuccess()
    //         case .failed(let error): self?.state = .error(error.localizedDescription)
    //         case .canceled: self?.state = .idle
    //         }
    //     }
    // }

    private func presentStripeSheet(clientSecret: String) {
        // Placeholder: replace with Stripe presentation once SDK is added.
        // See comment above for instructions.
        onPaymentSuccess()
    }

    func onPaymentSuccess() {
        Task {
            guard let userId = AuthRepository.shared.currentUserId else { return }
            let endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
            try? await UserRepository.shared.updateSubscription(
                userId: userId, active: true, endDate: endDate
            )
            state = .success
        }
    }

    func onPaymentError(_ message: String) { state = .error(message) }
    func resetState() { state = .idle }
}

// MARK: - UIApplication top view controller (for Stripe SDK use)

extension UIApplication {
    var topViewController: UIViewController? {
        let scene = connectedScenes.first as? UIWindowScene
        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

// MARK: - PaymentView

struct PaymentView: View {
    let onBack: () -> Void
    let onSuccess: () -> Void
    @StateObject private var viewModel = PaymentViewModel()

    private let beneficios = [
        "premium_resenas_ilimitadas",
        "premium_sin_anuncios",
        "premium_acceso_prioritario"
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.verdetp)
                            .frame(width: 40, height: 40)
                            .background(Color.verdetp.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Star icon
                Image(systemName: "star.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.verdetp)

                Spacer().frame(height: 16)

                Text("premium_plan_title", tableName: "Localizable")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Spacer().frame(height: 8)

                Text("premium_support_text", tableName: "Localizable")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 32)

                // Price card
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 8) {
                            Text("premium_plan_mensual", tableName: "Localizable")
                                .font(.system(size: 18, weight: .semibold))
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("$9.900 COP")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.verdetp)
                                Text("premium_por_mes", tableName: "Localizable")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            Divider().padding(.horizontal, 16)
                            ForEach(beneficios, id: \.self) { key in
                                Text(LocalizedStringKey(key))
                                    .font(.system(size: 15))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                // Action button
                Group {
                    switch viewModel.state {
                    case .loading:
                        ProgressView()
                            .tint(.verdetp)
                            .frame(height: 52)

                    case .error(let msg):
                        VStack(spacing: 12) {
                            Text(msg)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            subscribeButton
                        }

                    default:
                        subscribeButton
                    }
                }
                .padding(.horizontal, 24)

                Button(action: onBack) {
                    Text("premium_ahora_no", tableName: "Localizable")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)

                Spacer().frame(height: 40)
            }
        }
        .onChange(of: viewModel.state) { newState in
            if newState == .success { onSuccess() }
        }
    }

    private var isErrorState: Bool {
        if case .error = viewModel.state { return true }
        return false
    }

    private var subscribeButton: some View {
        Button(action: { viewModel.startPayment() }) {
            Text(isErrorState ? "premium_reintentar" : "premium_suscribirme", tableName: "Localizable")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.verdetp)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}