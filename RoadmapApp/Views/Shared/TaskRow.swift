import SwiftUI

struct TaskRow: View {
    let task: LearningTask

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.isCompleted ? .green : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                HStack(spacing: 6) {
                    Text("\(task.durationMinutes) min")
                    if let date = task.scheduledDate {
                        Text("·").foregroundStyle(.tertiary)
                        Text(date, format: .dateTime.month().day())
                    }
                    if !(task.resources ?? []).isEmpty {
                        Text("·").foregroundStyle(.tertiary)
                        Image(systemName: "book")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .contentShape(.rect)
    }
}
