import Foundation
import SwiftData

/// Initial SwiftData schema. All properties are optional or defaulted and every
/// relationship declares an inverse so the store is CloudKit-safe if sync is
/// enabled later without a migration.
enum RoadmapSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Roadmap.self, Phase.self, LearningTask.self, Resource.self, AgentTrace.self]
    }

    // MARK: Roadmap

    @Model
    final class Roadmap {
        @Attribute(.unique) var id: UUID = UUID()
        var goal: String = ""
        var title: String?
        var summary: String?
        var level: String?
        var statusRaw: String = RoadmapStatus.draft.rawValue
        var assessmentJSON: String?
        var createdAt: Date = Date()
        var updatedAt: Date = Date()

        @Relationship(deleteRule: .cascade, inverse: \Phase.roadmap)
        var phases: [Phase]? = []

        @Relationship(deleteRule: .cascade, inverse: \AgentTrace.roadmap)
        var traces: [AgentTrace]? = []

        init(
            id: UUID = UUID(),
            goal: String = "",
            title: String? = nil,
            summary: String? = nil,
            level: String? = nil,
            status: RoadmapStatus = .draft,
            assessmentJSON: String? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.goal = goal
            self.title = title
            self.summary = summary
            self.level = level
            self.statusRaw = status.rawValue
            self.assessmentJSON = assessmentJSON
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    // MARK: Phase

    @Model
    final class Phase {
        @Attribute(.unique) var id: UUID = UUID()
        var title: String = ""
        var summary: String?
        var orderIndex: Int = 0
        var targetWeeks: Int = 2
        var startDate: Date?
        var endDate: Date?

        var roadmap: Roadmap?

        @Relationship(deleteRule: .cascade, inverse: \LearningTask.phase)
        var tasks: [LearningTask]? = []

        init(
            id: UUID = UUID(),
            title: String = "",
            summary: String? = nil,
            orderIndex: Int = 0,
            targetWeeks: Int = 2,
            startDate: Date? = nil,
            endDate: Date? = nil
        ) {
            self.id = id
            self.title = title
            self.summary = summary
            self.orderIndex = orderIndex
            self.targetWeeks = targetWeeks
            self.startDate = startDate
            self.endDate = endDate
        }
    }

    // MARK: LearningTask

    @Model
    final class LearningTask {
        @Attribute(.unique) var id: UUID = UUID()
        var title: String = ""
        var detail: String?
        var orderIndex: Int = 0
        var durationMinutes: Int = 30
        var scheduledDate: Date?
        var completedAt: Date?

        var phase: Phase?

        @Relationship(deleteRule: .cascade, inverse: \Resource.task)
        var resources: [Resource]? = []

        init(
            id: UUID = UUID(),
            title: String = "",
            detail: String? = nil,
            orderIndex: Int = 0,
            durationMinutes: Int = 30,
            scheduledDate: Date? = nil,
            completedAt: Date? = nil
        ) {
            self.id = id
            self.title = title
            self.detail = detail
            self.orderIndex = orderIndex
            self.durationMinutes = durationMinutes
            self.scheduledDate = scheduledDate
            self.completedAt = completedAt
        }
    }

    // MARK: Resource

    @Model
    final class Resource {
        @Attribute(.unique) var id: UUID = UUID()
        var title: String = ""
        var urlString: String = ""
        var kindRaw: String = ResourceKind.article.rawValue
        var author: String?
        var durationMinutes: Int?
        var summary: String?

        var task: LearningTask?

        init(
            id: UUID = UUID(),
            title: String = "",
            urlString: String = "",
            kind: ResourceKind = .article,
            author: String? = nil,
            durationMinutes: Int? = nil,
            summary: String? = nil
        ) {
            self.id = id
            self.title = title
            self.urlString = urlString
            self.kindRaw = kind.rawValue
            self.author = author
            self.durationMinutes = durationMinutes
            self.summary = summary
        }
    }

    // MARK: AgentTrace

    @Model
    final class AgentTrace {
        @Attribute(.unique) var id: UUID = UUID()
        var stageRaw: String = AgentStage.intake.rawValue
        var model: String = ""
        var requestSummary: String?
        var responseSummary: String?
        var inputTokens: Int = 0
        var outputTokens: Int = 0
        var cachedInputTokens: Int = 0
        var durationMs: Int = 0
        var createdAt: Date = Date()

        var roadmap: Roadmap?

        init(
            id: UUID = UUID(),
            stage: AgentStage = .intake,
            model: String = "",
            requestSummary: String? = nil,
            responseSummary: String? = nil,
            inputTokens: Int = 0,
            outputTokens: Int = 0,
            cachedInputTokens: Int = 0,
            durationMs: Int = 0,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.stageRaw = stage.rawValue
            self.model = model
            self.requestSummary = requestSummary
            self.responseSummary = responseSummary
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.cachedInputTokens = cachedInputTokens
            self.durationMs = durationMs
            self.createdAt = createdAt
        }
    }
}

// MARK: - String-backed enums stored on model raw fields

enum RoadmapStatus: String, Codable, CaseIterable {
    case draft, active, completed, archived
}

enum ResourceKind: String, Codable, CaseIterable {
    case youtube, article, doc, podcast, course, video
}

enum AgentStage: String, Codable, CaseIterable {
    case intake
    case assess
    case generate
    case enrich
    case resources
    case revise
}
