import SwiftData
import SwiftUI

struct WeeklyReviewView: View {
    @Query(sort: \Roadmap.updatedAt, order: .reverse) private var roadmaps: [Roadmap]

    var body: some View {
        let activeRoadmap = roadmaps.first(where: { $0.status == .active }) ?? roadmaps.first

        List {
            if let roadmap = activeRoadmap {
                Section("Week in review") {
                    LabeledContent("Tasks completed", value: "\(completedThisWeek(roadmap))")
                    LabeledContent("Current streak", value: "\(StreakEngine().summary(for: roadmap).current) d")
                }

                Section {
                    NavigationLink("See agent trace") {
                        AgentTraceView(roadmap: roadmap)
                    }
                }

                Section {
                    Button("Revise my plan") {
                        // Wired up in a later pass — triggers AgentClient.runRevise.
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ContentUnavailableView(
                    "Nothing to review yet",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Come back after a week of practice.")
                )
            }
        }
        .navigationTitle("Weekly Review")
    }

    private func completedThisWeek(_ roadmap: Roadmap) -> Int {
        let cal = Calendar.current
        let weekStart = cal.date(byAdding: .day, value: -7, to: .now) ?? .now
        return roadmap.orderedPhases
            .flatMap(\.orderedTasks)
            .filter { ($0.completedAt ?? .distantPast) >= weekStart }
            .count
    }
}
