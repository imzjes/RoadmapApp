import SwiftData
import SwiftUI

struct TaskDetailView: View {
    @Bindable var task: LearningTask
    @Environment(\.modelContext) private var context
    @State private var showAddToCalendar = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { task.isCompleted },
                    set: { _ in RoadmapStore.shared.toggleCompletion(task) }
                )) {
                    Text(task.title).font(.headline)
                }
                if let detail = task.detail {
                    Text(detail).foregroundStyle(.secondary)
                }
            }

            Section("Details") {
                LabeledContent("Duration", value: "\(task.durationMinutes) min")
                if let scheduled = task.scheduledDate {
                    LabeledContent("Scheduled", value: scheduled, format: .dateTime.weekday().month().day())
                }
                if let completed = task.completedAt {
                    LabeledContent("Completed", value: completed, format: .dateTime.month().day().hour().minute())
                }
            }

            if !task.orderedResources.isEmpty {
                Section("Resources") {
                    ForEach(task.orderedResources) { resource in
                        ResourceRow(resource: resource)
                    }
                }
            }

            Section {
                Button {
                    showAddToCalendar = true
                } label: {
                    Label("Add to Calendar", systemImage: "calendar.badge.plus")
                }
            }
        }
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddToCalendar) {
            AddToCalendarSheet(task: task) { showAddToCalendar = false }
        }
    }
}
