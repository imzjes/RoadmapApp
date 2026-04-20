import Foundation

/// Server-side session identity + cache handle. v1 points at a Durable Object
/// on the Worker; v1.1 swaps in a Postgres-backed session row without any
/// client changes.
protocol SessionStore: Sendable {
    func createSession() async throws -> String
    func endSession(_ id: String) async
}

/// Durable Object–backed session. The Worker creates the DO on first use; the
/// client only needs to pass the ID back on every call.
struct DurableObjectSessionStore: SessionStore {
    var baseURL: URL?

    init(baseURL: URL? = URL(string: AppSecrets.workerBaseURL)) {
        self.baseURL = baseURL
    }

    func createSession() async throws -> String {
        guard let baseURL else { throw AgentClientError.missingWorkerURL }
        var req = URLRequest(url: baseURL.appendingPathComponent("/v1/session"))
        req.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: req)
        struct SessionResponse: Decodable { let id: String }
        return try JSONDecoder().decode(SessionResponse.self, from: data).id
    }

    func endSession(_ id: String) async {
        guard let baseURL else { return }
        var req = URLRequest(url: baseURL.appendingPathComponent("/v1/session/\(id)"))
        req.httpMethod = "DELETE"
        _ = try? await URLSession.shared.data(for: req)
    }
}
