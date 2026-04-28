import Foundation
import SwiftData

/// Decodes the JSON the worker's generate stage emits and turns it into a
/// SwiftData `Roadmap` graph. The schema mirrors `prompts/generate.md`.
struct GeneratedRoadmapDTO: Codable, Sendable {
    var title: String
    var summary: String
    var phases: [PhaseDTO]

    struct PhaseDTO: Codable, Sendable {
        var title: String
        var summary: String?
        var targetWeeks: Int?
        var tasks: [TaskDTO]
    }

    struct TaskDTO: Codable, Sendable {
        var title: String
        var detail: String?
        var durationMinutes: Int?
    }

    /// Build a fresh `Roadmap` model graph. Caller is responsible for inserting
    /// it into the model context.
    @MainActor
    func materialize(goal: String) -> Roadmap {
        let roadmap = Roadmap(
            goal: goal,
            title: title,
            summary: summary,
            level: nil,
            status: .active
        )
        let phaseModels: [Phase] = phases.enumerated().map { index, phaseDTO in
            let phase = Phase(
                title: phaseDTO.title,
                summary: phaseDTO.summary,
                orderIndex: index,
                targetWeeks: phaseDTO.targetWeeks ?? 2
            )
            phase.tasks = phaseDTO.tasks.enumerated().map { taskIndex, taskDTO in
                let task = LearningTask(
                    title: taskDTO.title,
                    detail: taskDTO.detail,
                    orderIndex: taskIndex,
                    durationMinutes: taskDTO.durationMinutes ?? 25
                )
                task.phase = phase
                return task
            }
            return phase
        }
        for phase in phaseModels { phase.roadmap = roadmap }
        roadmap.phases = phaseModels
        return roadmap
    }
}

/// Payload from the enrichment stage: per-task resource entries.
struct EnrichmentPayload: Codable, Sendable {
    var resources: [ResourceDTO]

    struct ResourceDTO: Codable, Sendable {
        var taskTitle: String
        var title: String
        var url: String
        var kind: String
        var author: String?
        var durationMinutes: Int?
    }
}
