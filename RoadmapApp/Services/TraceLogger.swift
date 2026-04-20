import Foundation
import SwiftData

/// Writes `AgentTrace` rows into the store. The WeeklyReview and AgentTrace
/// screens query these rows to show what the agent did, with what model, and
/// at what token cost.
@MainActor
struct TraceLogger {
    var context: ModelContext

    func append(_ dto: AgentTraceDTO, to roadmap: Roadmap?) {
        let stage = AgentStage(rawValue: dto.stage) ?? .intake
        let trace = AgentTrace(
            stage: stage,
            model: dto.model,
            requestSummary: dto.requestSummary,
            responseSummary: dto.responseSummary,
            inputTokens: dto.inputTokens,
            outputTokens: dto.outputTokens,
            cachedInputTokens: dto.cachedInputTokens,
            durationMs: dto.durationMs
        )
        trace.roadmap = roadmap
        context.insert(trace)
        try? context.save()
    }
}
