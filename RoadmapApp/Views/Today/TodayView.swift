import SwiftData
import SwiftUI

struct TodayView: View {
    @Query(sort: \LearningTask.orderIndex) private var tasks: [LearningTask]
    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            if todaysTasks.isEmpty {
                ContentUnavailableView(
                    "Nothing scheduled",
                    systemImage: "calendar",
                    description: Text("Pull a task from your roadmap or wait for tomorrow's plan.")
                )
            } else {
                Section("Today") {
                    ForEach(todaysTasks) { task in
                        NavigationLink(value: task.id) {
                            TaskRow(task: task)
                        }
                    }
                }
            }
        }
        .navigationTitle(Date.now, format: .dateTime.weekday(.wide).month().day())
        .navigationDestination(for: UUID.self) { id in
            if let task = tasks.first(where: { $0.id == id }) {
                TaskDetailView(task: task)
            }
        }
    }

    private var todaysTasks: [LearningTask] {
        let today = Calendar.current.startOfDay(for: .now)
        return tasks.filter {
            guard let d = $0.scheduledDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: today)
        }
    }
}
