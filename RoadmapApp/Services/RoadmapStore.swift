import Foundation
import SwiftData

/// Owns the SwiftData `ModelContainer` and exposes CRUD helpers the rest of
/// the app uses. Kept intentionally thin — views inject a `ModelContext` via
/// `@Environment(\.modelContext)` for ad-hoc reads.
@Observable
@MainActor
final class RoadmapStore {
    static let shared = RoadmapStore()

    let container: ModelContainer

    private init() {
        do {
            let schema = Schema(versionedSchema: SchemaLatest.self)
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            container = try ModelContainer(
                for: schema,
                migrationPlan: RoadmapMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create RoadmapStore container: \(error)")
        }
    }

    var mainContext: ModelContext { container.mainContext }

    // MARK: Fetch

    func activeRoadmap() -> Roadmap? {
        var descriptor = FetchDescriptor<Roadmap>(
            predicate: #Predicate { $0.statusRaw == "active" },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? mainContext.fetch(descriptor).first
    }

    func allRoadmaps() -> [Roadmap] {
        let descriptor = FetchDescriptor<Roadmap>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? mainContext.fetch(descriptor)) ?? []
    }

    // MARK: Mutations

    @discardableResult
    func insertRoadmap(_ roadmap: Roadmap) -> Roadmap {
        mainContext.insert(roadmap)
        roadmap.updatedAt = Date()
        try? mainContext.save()
        return roadmap
    }

    func activate(_ roadmap: Roadmap) {
        for existing in allRoadmaps() where existing.status == .active && existing.id != roadmap.id {
            existing.status = .archived
        }
        roadmap.status = .active
        roadmap.updatedAt = Date()
        try? mainContext.save()
    }

    func toggleCompletion(_ task: LearningTask) {
        task.completedAt = task.completedAt == nil ? Date() : nil
        try? mainContext.save()
    }

    func reschedule(_ task: LearningTask, to date: Date?) {
        task.scheduledDate = date
        try? mainContext.save()
    }

    func delete(_ roadmap: Roadmap) {
        mainContext.delete(roadmap)
        try? mainContext.save()
    }
}
