import Foundation
import FirebaseAuth

// MARK: - API Error (used across repositories)

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida"
        case .networkError(let e): return "Error de red: \(e.localizedDescription)"
        case .decodingError(let e): return "Error al procesar respuesta: \(e.localizedDescription)"
        case .serverError(let code, let msg): return "Error del servidor (\(code)): \(msg)"
        case .noData: return "Sin datos"
        }
    }
}

// MARK: - GROQ AI Service (proxied via Cloud Function)

class GroqAIService {
    static let shared = GroqAIService()

    private let functionURL = "https://us-central1-tuprofe-89d43.cloudfunctions.net/generateReviewSummary"

    func generateReviewSummary(reviews: [ReviewInfo]) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw APIError.serverError(401, "Usuario no autenticado")
        }

        let idToken = try await user.getIDToken()

        let body: [String: Any] = [
            "reviews": reviews.prefix(20).map { $0.content }
        ]

        guard let url = URL(string: functionURL) else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw APIError.serverError(code, "Error en el servicio de resumen")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let summary = json["summary"] as? String else {
            throw APIError.decodingError(NSError(domain: "GroqSummary", code: 0))
        }

        return summary
    }
}