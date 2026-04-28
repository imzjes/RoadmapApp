import SwiftData
import SwiftUI

struct TaskDetailView: View {
    @Bindable var task: LearningTask
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showAddToCalendar = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                phaseEyebrow
                titleAndToggle
                if let detail = task.detail {
                    Text(detail)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }

                section(label: "DETAILS") { detailsBlock }
                if !task.orderedResources.isEmpty {
                    section(label: "RESOURCES") {
                        VStack(spacing: 8) {
                            ForEach(task.orderedResources) { resource in
                                ResourceRow(resource: resource)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Theme.Surface.card)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
                                            )
                                    )
                            }
                        }
                    }
                }
                section(label: "SCHEDULE") {
                    Button {
                        showAddToCalendar = true
                    } label: {
                        addToCalendarRow
                    }
                    .buttonStyle(.plain)
                }
                if task.isCompleted { loggedFooter }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Theme.Surface.groupedBG.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold))
                        Text("Roadmap").font(.system(size: 17, weight: .medium))
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .sheet(isPresented: $showAddToCalendar) {
            AddToCalendarSheet(task: task) { showAddToCalendar = false }
        }
    }

    // MARK: Eyebrow

    private var phaseEyebrow: some View {
        Group {
            if let phase = task.phase, let roadmap = phase.roadmap {
                let idx = (roadmap.orderedPhases.firstIndex(where: { $0.id == phase.id }) ?? 0) + 1
                SectionEyebrow(
                    text: "PHASE \(String(format: "%02d", idx)) · \(phase.title.uppercased())",
                    color: Theme.accent
                )
            } else {
                SectionEyebrow(text: "TASK", color: Theme.accent)
            }
        }
    }

    // MARK: Title

    private var titleAndToggle: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(task.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .strikethrough(task.isCompleted, color: .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            CompletionToggle(isOn: task.isCompleted, size: 38) {
                RoadmapStore.shared.toggleCompletion(task)
            }
        }
    }

    // MARK: Details block

    private var detailsBlock: some View {
        VStack(spacing: 0) {
            DetailRow(symbol: "clock", label: "Duration", value: "\(task.durationMinutes) min")
            if let scheduled = task.scheduledDate {
                Divider().padding(.leading, 56)
                DetailRow(
                    symbol: "calendar",
                    label: "Scheduled",
                    value: scheduled.formatted(.dateTime.weekday().month(.abbreviated).day())
                )
            }
            if let completed = task.completedAt {
                Divider().padding(.leading, 56)
                DetailRow(
                    symbol: "checkmark.circle.fill",
                    label: "Completed",
                    value: completed.formatted(.dateTime.month().day().hour().minute()),
                    accent: .completed
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: Add to calendar row

    private var addToCalendarRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.accentSoft)
                    .frame(width: 28, height: 28)
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            Text("Add to Calendar")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.Surface.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    // MARK: Logged footer

    private var loggedFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .bold))
            Text("Logged to your streak")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Color(red: 0x1B/255, green: 0x7A/255, blue: 0x33/255))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.green.opacity(0.10))
        )
    }

    // MARK: Section helper

    @ViewBuilder
    private func section<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionEyebrow(text: label)
            content()
        }
    }
}

struct DetailRow: View {
    enum Accent { case none, completed }

    let symbol: String
    let label: String
    let value: String
    var accent: Accent = .none

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accent == .completed ? Color.green.opacity(0.14) : Color(uiColor: .tertiarySystemFill))
                    .frame(width: 28, height: 28)
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent == .completed ? Color.green : Color.secondary)
            }
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
