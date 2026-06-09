import Foundation

// MARK: - APIClient (equivalente al RetrofitClient de Android)
// Simulador iOS: usa "localhost" | Dispositivo real: cambia por la IP de tu Mac en la LAN

final class APIClient {
    static let shared = APIClient()

    var baseURL = "http://localhost:3000"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - GET

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        let url = try buildURL(path, query: query)
        let (data, response) = try await session.data(from: url)
        try validate(response, data: data)
        return try decode(data)
    }

    // MARK: - POST con body y respuesta decodificable

    func post<T: Decodable>(_ path: String, body: Encodable, query: [String: String] = [:]) async throws -> T {
        let request = try buildRequest(path, method: "POST", body: body, query: query)
        let (data, response) = try await session.data(for: request)
        try validate(response, data: data)
        return try decode(data)
    }

    // MARK: - POST sin respuesta (toggle, etc.)

    func postVoid(_ path: String, body: Encodable? = nil, query: [String: String] = [:]) async throws {
        let request = try buildRequest(path, method: "POST", body: body, query: query)
        let (data, response) = try await session.data(for: request)
        try validate(response, data: data)
    }

    // MARK: - PUT

    func put(_ path: String, body: Encodable? = nil) async throws {
        let request = try buildRequest(path, method: "PUT", body: body)
        let (data, response) = try await session.data(for: request)
        try validate(response, data: data)
    }

    // MARK: - DELETE

    func delete(_ path: String) async throws {
        var request = URLRequest(url: try buildURL(path))
        request.httpMethod = "DELETE"
        let (data, response) = try await session.data(for: request)
        try validate(response, data: data)
    }

    // MARK: - Helpers

    private func buildURL(_ path: String, query: [String: String] = [:]) throws -> URL {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.invalidURL }
        return url
    }

    private func buildRequest(_ path: String, method: String, body: Encodable?, query: [String: String] = [:]) throws -> URLRequest {
        var request = URLRequest(url: try buildURL(path, query: query))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw APIError.serverError(http.statusCode, msg)
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
