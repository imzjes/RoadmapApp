import SwiftUI

struct TaskRow: View {
    let task: LearningTask
    var onToggle: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            CompletionToggle(isOn: task.isCompleted, action: onToggle)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text("\(task.durationMinutes) min")
                    if let date = task.scheduledDate {
                        Text("·").foregroundStyle(.tertiary)
                        Text(date, format: .dateTime.weekday(.abbreviated))
                    }
                    if let resource = task.orderedResources.first {
                        Text("·").foregroundStyle(.tertiary)
                        Image(systemName: resourceSymbol(resource.kind))
                            .font(.system(size: 12, weight: .regular))
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
    }

    private func resourceSymbol(_ kind: ResourceKind) -> String {
        switch kind {
        case .youtube, .video: return "play.rectangle"
        case .article:         return "doc.text"
        case .doc, .course:    return "book"
        case .podcast:         return "headphones"
        }
    }
}

struct CompletionToggle: View {
    let isOn: Bool
    var size: CGFloat = 26
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            ZStack {
                Circle()
                    .stroke(Color(uiColor: .tertiaryLabel), lineWidth: 1.5)
                    .opacity(isOn ? 0 : 1)
                Circle()
                    .fill(Color.green)
                    .opacity(isOn ? 1 : 0)
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: size, height: size)
            .animation(.easeOut(duration: 0.15), value: isOn)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}
