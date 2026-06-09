import Foundation

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

// MARK: - GROQ AI Service (OpenAI-compatible, model llama-3.3-70b-versatile)

class GroqAIService {
    static let shared = GroqAIService()

    private let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "GROQ_API_KEY") as? String ?? ""
    }()

    private let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    private let model = "llama-3.3-70b-versatile"

    func generateReviewSummary(reviews: [ReviewInfo]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw APIError.serverError(401, "GROQ API key no configurada")
        }

        let reviewsText = reviews.prefix(20).map { "- \($0.content)" }.joined(separator: "\n")

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "Eres un asistente experto en analizar reseñas de profesores. Resume los puntos clave (lo bueno y lo malo) de forma muy concisa y objetiva en español. Usa un tono profesional."
                ],
                [
                    "role": "user",
                    "content": "Basado en estas reseñas de alumnos, genera un resumen corto:\n\n\(reviewsText)"
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.7
        ]

        guard let url = URL(string: baseURL) else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError(0, "Error en GROQ API")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIError.decodingError(NSError(domain: "GROQ", code: 0))
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}