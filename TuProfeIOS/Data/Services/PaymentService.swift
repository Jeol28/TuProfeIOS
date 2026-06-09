import Foundation

final class PaymentService {
    static let shared = PaymentService()

    private let backendUrl = "https://tuprofe-backend.onrender.com/create-payment-intent"

    func createPaymentIntent() async -> Result<String, Error> {
        guard let url = URL(string: backendUrl) else {
            return .failure(NSError(domain: "PaymentService", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "URL inválida"]))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("TuProfeApp/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("69420", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.httpBody = "{}".data(using: .utf8)
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NSError(domain: "PaymentService", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "Error del servidor"])
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let clientSecret = json["clientSecret"] as? String else {
                throw NSError(domain: "PaymentService", code: -3,
                              userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida del servidor"])
            }
            return .success(clientSecret)
        } catch {
            return .failure(error)
        }
    }
}