import Foundation

/// Event streamed back from the Cloudflare Worker while the agent loop runs.
/// Mirrors the Worker's SSE payload shape — one case per event type.
enum AgentEvent: Sendable {
    case stageStarted(AgentStage)
    case assistantText(String)
    case toolUse(name: String, input: [String: String])
    case toolResult(name: String, summary: String)
    case partialJSON(String)
    case trace(AgentTraceDTO)
    case stageFinished(AgentStage, payloadJSON: String)
    case error(String)
}

/// Plain-old payload for an agent step. Decoded from Worker, mapped into the
/// SwiftData `AgentTrace` model by `TraceLogger`.
struct AgentTraceDTO: Codable, Sendable {
    var stage: String
    var model: String
    var requestSummary: String?
    var responseSummary: String?
    var inputTokens: Int
    var outputTokens: Int
    var cachedInputTokens: Int
    var durationMs: Int
}

struct IntakeRequest: Codable, Sendable {
    var goal: String
    var sessionID: String
}

struct AssessmentTurn: Codable, Sendable {
    var question: String?
    var answer: String?
    var done: Bool
}

/// Client-side interface. Implementations stream Worker SSE responses as a
/// typed `AsyncThrowingStream<AgentEvent>`. Swap the implementation for a
/// fake in unit tests and previews.
protocol AgentClient: Sendable {
    func runIntake(_ req: IntakeRequest) -> AsyncThrowingStream<AgentEvent, Error>
    func continueAssessment(sessionID: String, answer: String) -> AsyncThrowingStream<AgentEvent, Error>
    func runGenerate(sessionID: String) -> AsyncThrowingStream<AgentEvent, Error>
    func runEnrichment(sessionID: String, phaseID: UUID) -> AsyncThrowingStream<AgentEvent, Error>
    func runRevise(sessionID: String, weeklyReviewJSON: String) -> AsyncThrowingStream<AgentEvent, Error>
}

/// Production `AgentClient`. Uses the Worker URL from xcconfig. SSE parsing
/// is deliberately minimal — the Worker emits one JSON object per line.
struct LiveAgentClient: AgentClient {
    var baseURL: URL?

    init(baseURL: URL? = URL(string: AppSecrets.workerBaseURL)) {
        self.baseURL = baseURL
    }

    func runIntake(_ req: IntakeRequest) -> AsyncThrowingStream<AgentEvent, Error> {
        stream(path: "/v1/intake", body: req)
    }

    func continueAssessment(sessionID: String, answer: String) -> AsyncThrowingStream<AgentEvent, Error> {
        stream(path: "/v1/assess", body: ["sessionID": sessionID, "answer": answer])
    }

    func runGenerate(sessionID: String) -> AsyncThrowingStream<AgentEvent, Error> {
        stream(path: "/v1/generate", body: ["sessionID": sessionID])
    }

    func runEnrichment(sessionID: String, phaseID: UUID) -> AsyncThrowingStream<AgentEvent, Error> {
        stream(path: "/v1/enrich", body: ["sessionID": sessionID, "phaseID": phaseID.uuidString])
    }

    func runRevise(sessionID: String, weeklyReviewJSON: String) -> AsyncThrowingStream<AgentEvent, Error> {
        stream(path: "/v1/revise", body: ["sessionID": sessionID, "review": weeklyReviewJSON])
    }

    private func stream<Body: Encodable>(path: String, body: Body) -> AsyncThrowingStream<AgentEvent, Error> {
        AsyncThrowingStream { continuation in
            guard let baseURL else {
                continuation.finish(throwing: AgentClientError.missingWorkerURL)
                return
            }
            let task = Task {
                do {
                    var request = URLRequest(url: baseURL.appendingPathComponent(path))
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.httpBody = try JSONEncoder().encode(body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                        throw AgentClientError.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
                    }
                    for try await line in bytes.lines {
                        guard !line.isEmpty else { continue }
                        if let event = AgentEvent.decode(line: line) {
                            continuation.yield(event)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

enum AgentClientError: LocalizedError {
    case missingWorkerURL
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .missingWorkerURL: "Worker URL not configured. See Settings."
        case .badStatus(let code): "Worker returned status \(code)."
        }
    }
}

extension AgentEvent {
    /// Decodes one line from the SSE stream. The Worker emits newline-delimited
    /// JSON objects of shape `{"type": "...", ...}`.
    static func decode(line: String) -> AgentEvent? {
        guard let data = line.data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = raw["type"] as? String else {
            return nil
        }
        switch type {
        case "stage_started":
            if let s = raw["stage"] as? String, let stage = AgentStage(rawValue: s) {
                return .stageStarted(stage)
            }
        case "assistant_text":
            if let t = raw["text"] as? String { return .assistantText(t) }
        case "tool_use":
            let name = (raw["name"] as? String) ?? ""
            let input = (raw["input"] as? [String: String]) ?? [:]
            return .toolUse(name: name, input: input)
        case "tool_result":
            let name = (raw["name"] as? String) ?? ""
            let summary = (raw["summary"] as? String) ?? ""
            return .toolResult(name: name, summary: summary)
        case "partial_json":
            if let s = raw["json"] as? String { return .partialJSON(s) }
        case "trace":
            if let dict = raw["trace"],
               let data = try? JSONSerialization.data(withJSONObject: dict),
               let dto = try? JSONDecoder().decode(AgentTraceDTO.self, from: data) {
                return .trace(dto)
            }
        case "stage_finished":
            if let s = raw["stage"] as? String,
               let stage = AgentStage(rawValue: s) {
                let payload = (raw["payload"] as? String) ?? ""
                return .stageFinished(stage, payloadJSON: payload)
            }
        case "error":
            if let m = raw["message"] as? String { return .error(m) }
        default: break
        }
        return nil
    }
}
