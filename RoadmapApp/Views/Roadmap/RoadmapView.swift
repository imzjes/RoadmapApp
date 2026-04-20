import SwiftData
import SwiftUI

struct RoadmapView: View {
    @Query(sort: \Roadmap.updatedAt, order: .reverse) private var roadmaps: [Roadmap]

    var body: some View {
        Group {
            if let roadmap = roadmaps.first(where: { $0.status == .active }) ?? roadmaps.first {
                RoadmapDetailView(roadmap: roadmap)
            } else {
                ContentUnavailableView(
                    "No roadmap yet",
                    systemImage: "map",
                    description: Text("Finish onboarding to generate your first plan.")
                )
            }
        }
        .navigationTitle("Roadmap")
    }
}

struct RoadmapDetailView: View {
    let roadmap: Roadmap

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(roadmap.title ?? roadmap.goal).font(.title2.bold())
                    if let summary = roadmap.summary {
                        Text(summary).foregroundStyle(.secondary)
                    }
                }
            }
            ForEach(roadmap.orderedPhases) { phase in
                Section(phase.title) {
                    if let summary = phase.summary {
                        Text(summary).font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(phase.orderedTasks) { task in
                        NavigationLink(value: task.id) {
                            TaskRow(task: task)
                        }
                    }
                }
            }
        }
        .navigationDestination(for: UUID.self) { id in
            if let task = roadmap.orderedPhases.flatMap(\.orderedTasks).first(where: { $0.id == id }) {
                TaskDetailView(task: task)
            }
        }
    }
}
