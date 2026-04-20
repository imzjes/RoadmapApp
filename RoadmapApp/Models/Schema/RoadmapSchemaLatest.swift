import Foundation
import SwiftData

/// Latest schema alias used by the rest of the app. When a new schema version
/// is introduced, change these typealiases and add a `MigrationPlan` stage.
typealias SchemaLatest = RoadmapSchemaV1

typealias Roadmap = RoadmapSchemaV1.Roadmap
typealias Phase = RoadmapSchemaV1.Phase
typealias LearningTask = RoadmapSchemaV1.LearningTask
typealias Resource = RoadmapSchemaV1.Resource
typealias AgentTrace = RoadmapSchemaV1.AgentTrace

/// Place to register future version→version migration stages. Empty at v1.
enum RoadmapMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [RoadmapSchemaV1.self]
    }

    static var stages: [MigrationStage] { [] }
}

// Computed conveniences on the stored raw strings so call sites can use the enum types.
extension Roadmap {
    var status: RoadmapStatus {
        get { RoadmapStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }
}

extension Resource {
    var kind: ResourceKind {
        get { ResourceKind(rawValue: kindRaw) ?? .article }
        set { kindRaw = newValue.rawValue }
    }

    var url: URL? { URL(string: urlString) }
}

extension AgentTrace {
    var stage: AgentStage {
        get { AgentStage(rawValue: stageRaw) ?? .intake }
        set { stageRaw = newValue.rawValue }
    }
}

// Sorted accessors — SwiftData to-many relationships are unordered sets.
extension Roadmap {
    var orderedPhases: [Phase] {
        (phases ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }
}

extension Phase {
    var orderedTasks: [LearningTask] {
        (tasks ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }
}

extension LearningTask {
    var orderedResources: [Resource] {
        (resources ?? []).sorted { $0.title < $1.title }
    }

    var isCompleted: Bool { completedAt != nil }
}
