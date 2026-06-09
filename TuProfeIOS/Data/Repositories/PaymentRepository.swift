import Foundation

final class PaymentRepository {
    static let shared = PaymentRepository()
    private let service = PaymentService.shared

    func createPaymentIntent() async -> Result<String, Error> {
        await service.createPaymentIntent()
    }
}