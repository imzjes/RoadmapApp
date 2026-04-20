import Foundation
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

/// App-wide coordinator. Owned by `RoadmapApp` and passed into the view
/// hierarchy via `@Environment`. Keeps cross-stage state (session ID, draft
/// roadmap, transient agent transcripts) in one place so individual views
/// stay focused on their job.
@Observable
@MainActor
final class FlowModel {
    var phase: FlowPhase = .launch
    var goalDraft: String = ""
    var sessionID: String?
    var assessmentTranscript: [AssessmentTurn] = []
    var liveAssistantText: String = ""
    var errorMessage: String?

    /// Per-stage live trace entries streamed from the Worker. Rendered on
    /// the AgentTrace screen while generation is in progress.
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

    /// Called on first appear. Decides whether to jump straight to the main
    /// app (returning user) or start onboarding.
    func bootstrap() {
        if let active = store.activeRoadmap() {
            activeRoadmapID = active.id
            phase = .ready
        } else {
            phase = .onboarding(.goal)
        }
    }

    // MARK: Onboarding transitions

    func submitGoal() async {
        guard !goalDraft.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            let id = try await session.createSession()
            sessionID = id
            phase = .onboarding(.assessment)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitAssessmentAnswer(_ answer: String) {
        assessmentTranscript.append(AssessmentTurn(question: nil, answer: answer, done: false))
    }

    func finishAssessment() {
        phase = .onboarding(.confirm)
    }

    func generate() {
        phase = .generating
    }

    func markReady(roadmapID: UUID) {
        activeRoadmapID = roadmapID
        phase = .ready
    }

    // MARK: Reset

    func startOver() {
        goalDraft = ""
        sessionID = nil
        assessmentTranscript.removeAll()
        liveAssistantText = ""
        liveTraces.removeAll()
        errorMessage = nil
        activeRoadmapID = nil
        phase = .onboarding(.goal)
    }
}
