import Foundation
import SwiftData
import SwiftUI

/// Coarse navigation state for first-launch + active use. Each case maps to
/// a top-level view. `FlowModel` is the single source of truth for "what
/// screen should we show right now".
enum FlowPhase: Equatable {
    case launch
    case onboarding(OnboardingStep)
    case generating
    case ready
}

enum OnboardingStep: Equatable {
    case goal
    case assessment
    case confirm
}

/// One question/answer pair in the live assessment. The worker feeds the
/// question + meta; the client fills in `answer` when the user submits.
struct AssessmentEntry: Identifiable, Sendable {
    let id = UUID()
    var question: String
    var kind: AssistantMeta.Kind
    var suggestions: [String]
    var answer: String?
}

/// App-wide coordinator. Owned by `RoadmapApp` and passed into the view
/// hierarchy via `@Environment`. Owns cross-stage state (session ID, draft
/// roadmap, transient agent transcripts) so individual views stay focused.
@Observable
@MainActor
final class FlowModel {
    var phase: FlowPhase = .launch
    var goalDraft: String = ""
    var sessionID: String?
    var assessment: [AssessmentEntry] = []
    var liveAssistantText: String = ""
    var generationStream: String = ""
    var errorMessage: String?
    var isProcessing: Bool = false

    /// Per-stage live trace entries streamed from the Worker. While onboarding
    /// is in flight the active roadmap doesn't exist yet, so these buffer
    /// here and get persisted once the new roadmap is created.
    var liveTraces: [AgentTraceDTO] = []

    /// Populated when the user finishes onboarding. Once set, the main tab
    /// bar is rendered.
    var activeRoadmapID: UUID?

    private let store: RoadmapStore
    private let agent: AgentClient
    private let session: SessionStore

    init(
        store: RoadmapStore = .shared,
        agent: AgentClient = LiveAgentClient(),
        session: SessionStore = DurableObjectSessionStore()
    ) {
        self.store = store
        self.agent = agent
        self.session = session
    }

    // MARK: Launch decision

    func bootstrap() {
        if let active = store.activeRoadmap() {
            activeRoadmapID = active.id
            phase = .ready
        } else {
            phase = .onboarding(.goal)
        }
    }

    // MARK: Onboarding — Intake

    func submitGoal() async {
        guard !goalDraft.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard !isProcessing else { return }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let id = try await session.createSession()
            sessionID = id

            let stream = agent.runIntake(IntakeRequest(goal: goalDraft, sessionID: id))
            // The intake stage emits two assistant_text events: the goal
            // restatement (informational) and the first assessment question.
            var firstText: String?
            for try await event in stream {
                switch event {
                case .assistantText(let text, let meta):
                    if firstText == nil {
                        firstText = text
                        liveAssistantText = text
                    } else {
                        appendAssistantQuestion(text, meta: meta)
                    }
                case .trace(let dto):
                    liveTraces.append(dto)
                case .error(let message):
                    errorMessage = message
                default:
                    break
                }
            }

            // Advance to assessment as soon as we have at least one question.
            if !assessment.isEmpty {
                phase = .onboarding(.assessment)
            } else if errorMessage == nil {
                errorMessage = "The agent didn't return a question. Try again."
            }
        } catch {
            errorMessage = friendlyMessage(error)
        }
    }

    // MARK: Onboarding — Assessment

    func submitAssessmentAnswer(_ answer: String) async {
        guard let sessionID, let activeIndex = assessment.lastIndex(where: { $0.answer == nil }) else { return }
        guard !isProcessing else { return }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        assessment[activeIndex].answer = answer

        do {
            let stream = agent.continueAssessment(sessionID: sessionID, answer: answer)
            for try await event in stream {
                switch event {
                case .assistantText(let text, let meta):
                    appendAssistantQuestion(text, meta: meta)
                case .trace(let dto):
                    liveTraces.append(dto)
                case .stageFinished(_, let payload):
                    if isFinalAssessmentPayload(payload) {
                        phase = .onboarding(.confirm)
                    }
                case .error(let message):
                    errorMessage = message
                default:
                    break
                }
            }
        } catch {
            errorMessage = friendlyMessage(error)
        }
    }

    func finishAssessment() {
        // User explicitly hit "Done — build my plan" before the agent finalized.
        phase = .onboarding(.confirm)
    }

    // MARK: Generate

    func generate() async {
        guard let sessionID else {
            errorMessage = "Session expired. Start over."
            return
        }
        guard !isProcessing else { return }
        isProcessing = true
        errorMessage = nil
        phase = .generating
        generationStream = ""
        defer { isProcessing = false }

        do {
            let stream = agent.runGenerate(sessionID: sessionID)
            var finalPayload: String?
            for try await event in stream {
                switch event {
                case .partialJSON(let chunk):
                    generationStream += chunk
                case .stageFinished(.generate, let payload):
                    finalPayload = payload
                case .trace(let dto):
                    liveTraces.append(dto)
                case .error(let message):
                    errorMessage = message
                default:
                    break
                }
            }

            guard let payload = finalPayload, let data = payload.data(using: .utf8) else {
                errorMessage = "Generation finished but no roadmap was returned."
                return
            }

            let dto = try JSONDecoder().decode(GeneratedRoadmapDTO.self, from: data)
            let roadmap = dto.materialize(goal: goalDraft)
            store.insertRoadmap(roadmap)
            store.activate(roadmap)
            ScheduleEngine(daysPerWeek: 4).assignDates(to: roadmap)
            try? store.mainContext.save()

            // Flush buffered trace events onto the new roadmap.
            let logger = TraceLogger(context: store.mainContext)
            for trace in liveTraces {
                logger.append(trace, to: roadmap)
            }
            liveTraces.removeAll()

            activeRoadmapID = roadmap.id
            phase = .ready
        } catch {
            errorMessage = friendlyMessage(error)
        }
    }

    // MARK: Revise

    /// Calls `runRevise` on the active session. Persists every trace to the
    /// active roadmap and returns the classification ("none" / "small" / "deep")
    /// so the calling view can show a follow-up confirmation.
    @discardableResult
    func revise(notes: String) async -> String? {
        guard let sessionID else {
            errorMessage = "Session expired. Run a full assessment to enable revisions."
            return nil
        }
        guard !isProcessing else { return nil }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        var classification: String?
        do {
            let stream = agent.runRevise(sessionID: sessionID, weeklyReviewJSON: notes)
            for try await event in stream {
                switch event {
                case .trace(let dto):
                    persistTraceImmediately(dto)
                case .stageFinished(.revise, let payload):
                    if let data = payload.data(using: .utf8),
                       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        classification = obj["classification"] as? String
                    }
                case .error(let message):
                    errorMessage = message
                default:
                    break
                }
            }
        } catch {
            errorMessage = friendlyMessage(error)
        }
        return classification
    }

    // MARK: Enrich

    /// Calls `runEnrichment` for one phase. Stateless — sends the phase + tasks
    /// in the request body so it works without an active session. Decoded
    /// resources get attached to the matching tasks by case-insensitive title.
    func enrichPhase(_ phase: Phase) async {
        guard !isProcessing else { return }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        let request = EnrichRequest(
            phaseID: phase.id.uuidString,
            phaseTitle: phase.title,
            tasks: phase.orderedTasks.map { task in
                EnrichRequest.PhaseTask(title: task.title, detail: task.detail)
            }
        )

        do {
            let stream = agent.runEnrichment(request)
            for try await event in stream {
                switch event {
                case .trace(let dto):
                    persistTraceImmediately(dto)
                case .stageFinished(_, let payload):
                    applyEnrichmentPayload(payload, to: phase)
                case .error(let message):
                    errorMessage = message
                default:
                    break
                }
            }
        } catch {
            errorMessage = friendlyMessage(error)
        }
    }

    private func applyEnrichmentPayload(_ payload: String, to phase: Phase) {
        guard let data = payload.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(EnrichmentPayload.self, from: data) else {
            return
        }
        let tasks = phase.orderedTasks
        for resource in parsed.resources {
            guard let task = matchTask(tasks, name: resource.taskTitle) else { continue }
            let kind = ResourceKind(rawValue: resource.kind) ?? .article
            let model = Resource(
                title: resource.title,
                urlString: resource.url,
                kind: kind,
                author: resource.author,
                durationMinutes: resource.durationMinutes
            )
            model.task = task
            var current = task.resources ?? []
            current.append(model)
            task.resources = current
        }
        try? store.mainContext.save()
    }

    /// Title match for enrichment. Tries exact, then case-insensitive, then
    /// substring containment in either direction — the model sometimes
    /// rephrases the task title slightly.
    private func matchTask(_ tasks: [LearningTask], name: String) -> LearningTask? {
        let needle = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = tasks.first(where: { $0.title == needle }) { return exact }
        let lower = needle.lowercased()
        if let ci = tasks.first(where: { $0.title.lowercased() == lower }) { return ci }
        if let partial = tasks.first(where: { $0.title.lowercased().contains(lower) || lower.contains($0.title.lowercased()) }) {
            return partial
        }
        return nil
    }

    private func persistTraceImmediately(_ dto: AgentTraceDTO) {
        liveTraces.append(dto)
        guard let activeRoadmapID,
              let roadmap = store.allRoadmaps().first(where: { $0.id == activeRoadmapID }) else {
            return
        }
        TraceLogger(context: store.mainContext).append(dto, to: roadmap)
    }

    // MARK: Reset

    func startOver() {
        Task { [sessionID, session] in
            if let sessionID { await session.endSession(sessionID) }
        }
        // Wipe persisted roadmaps so the Today / Roadmap screens don't keep
        // showing stale tasks from previous goals.
        for roadmap in store.allRoadmaps() {
            store.delete(roadmap)
        }
        goalDraft = ""
        sessionID = nil
        assessment.removeAll()
        liveAssistantText = ""
        generationStream = ""
        liveTraces.removeAll()
        errorMessage = nil
        activeRoadmapID = nil
        isProcessing = false
        phase = .onboarding(.goal)
    }

    // MARK: Internal helpers

    private func appendAssistantQuestion(_ text: String, meta: AssistantMeta?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        assessment.append(
            AssessmentEntry(
                question: trimmed,
                kind: meta?.kind ?? .open,
                suggestions: meta?.suggestions ?? []
            )
        )
    }

    private func isFinalAssessmentPayload(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        return (obj["done"] as? Bool) == true
    }

    private func friendlyMessage(_ error: Error) -> String {
        if let agentError = error as? AgentClientError {
            return agentError.errorDescription ?? "Agent error."
        }
        return error.localizedDescription
    }
}
