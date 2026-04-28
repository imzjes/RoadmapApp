import SwiftData
import SwiftUI

struct TodayView: View {
    @Query(sort: \Roadmap.updatedAt, order: .reverse) private var roadmaps: [Roadmap]
    @Environment(\.modelContext) private var context

    /// All tasks belonging to the active roadmap (or the most recent if none
    /// is active). We compute this from the roadmaps query rather than a
    /// separate `@Query<LearningTask>` so stale tasks from deleted roadmaps
    /// can't bleed in.
    private var tasks: [LearningTask] {
        guard let roadmap = activeRoadmap else { return [] }
        return roadmap.orderedPhases.flatMap(\.orderedTasks)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                if !todaysTasks.isEmpty {
                    progressCard.padding(.horizontal, 20).padding(.top, 4)
                    pathSectionLabel
                    taskList.padding(.horizontal, 16)
                    upNextCard.padding(.horizontal, 20).padding(.top, 20)
                } else {
                    EmptyTodayBlock().padding(.top, 32)
                }
            }
            .padding(.bottom, 110)
        }
        .background(Theme.Surface.groupedBG.ignoresSafeArea())
        .navigationDestination(for: UUID.self) { id in
            if let task = tasks.first(where: { $0.id == id }) {
                TaskDetailView(task: task)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                SectionEyebrow(text: weekdayString)
                Text(monthDayString)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.primary)
            }
            Spacer()
            if !todaysTasks.isEmpty, let roadmap = activeRoadmap {
                StreakPill(summary: StreakEngine().summary(for: roadmap))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 70)
        .padding(.bottom, 12)
    }

    // MARK: Progress card

    private var progressCard: some View {
        let total = todaysTasks.count
        let done = todaysTasks.filter(\.isCompleted).count
        let phase = activeRoadmap?.orderedPhases.first { phase in
            phase.orderedTasks.contains { !$0.isCompleted }
        }

        return GlassCard(emphasized: true) {
            VStack(alignment: .leading, spacing: 4) {
                if let phase, let roadmap = activeRoadmap {
                    let phaseIndex = (roadmap.orderedPhases.firstIndex(where: { $0.id == phase.id }) ?? 0) + 1
                    let phaseCount = roadmap.orderedPhases.count
                    SectionEyebrow(
                        text: "MILESTONE \(String(format: "%02d", phaseIndex)) OF \(String(format: "%02d", phaseCount))",
                        color: Theme.accent
                    )
                    Text(phase.title)
                        .font(.system(size: 22, weight: .bold))
                        .padding(.bottom, 4)
                }
                Text("\(done) of \(total) done today")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 14)

                ProgressBar(progress: total == 0 ? 0 : Double(done) / Double(total))
                    .frame(height: 6)
            }
        }
    }

    // MARK: Path section

    private var pathSectionLabel: some View {
        SectionEyebrow(text: "TODAY'S PATH")
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 8)
    }

    private var taskList: some View {
        VStack(spacing: 0) {
            ForEach(Array(todaysTasks.enumerated()), id: \.element.id) { i, task in
                NavigationLink(value: task.id) {
                    TaskRow(task: task) {
                        RoadmapStore.shared.toggleCompletion(task)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                if i < todaysTasks.count - 1 {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.Surface.card)
        )
    }

    // MARK: Up next

    private var upNextCard: some View {
        GlassCard(padding: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Tomorrow at 7:30 AM")
                        .font(.system(size: 15, weight: .medium))
                    Text(upNextSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: Computed data

    private var activeRoadmap: Roadmap? {
        roadmaps.first(where: { $0.status == .active }) ?? roadmaps.first
    }

    private var todaysTasks: [LearningTask] {
        let today = Calendar.current.startOfDay(for: .now)
        let scheduled = tasks.filter {
            guard let d = $0.scheduledDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: today)
        }
        if !scheduled.isEmpty { return scheduled }
        // Demo fallback: show the first incomplete tasks of the active phase.
        guard let roadmap = activeRoadmap else { return [] }
        let activePhase = roadmap.orderedPhases.first { phase in
            phase.orderedTasks.contains { !$0.isCompleted }
        }
        return activePhase?.orderedTasks.prefix(3).map { $0 } ?? []
    }

    private var weekdayString: String {
        Date.now.formatted(.dateTime.weekday(.wide))
    }

    private var monthDayString: String {
        Date.now.formatted(.dateTime.month(.abbreviated).day())
    }

    private var upNextSubtitle: String {
        guard let next = tasks.first(where: { !$0.isCompleted && !todaysTasks.contains($0) }) else {
            return "Continue when you're ready"
        }
        return "\(next.title) · \(next.durationMinutes) min"
    }
}

// MARK: - Empty state

struct EmptyTodayBlock: View {
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .strokeBorder(Theme.accent.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 156, height: 156)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.9), Theme.accentSoft.opacity(0.6), Theme.accentMid.opacity(0.4)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                Image(systemName: "leaf")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Theme.accent.opacity(0.85))
            }

            VStack(spacing: 4) {
                Text("Nothing scheduled")
                    .font(.system(size: 22, weight: .bold))
                Text("A rest day, or your roadmap hasn't reached this date yet. Visit Roadmap to plan ahead.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                // Navigate handled by tab — no-op here
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "map").font(.system(size: 14, weight: .semibold))
                    Text("Open Roadmap").font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 16)
                .frame(height: 38)
                .background(Capsule().fill(Theme.accentSoft))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Progress bar

struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.06))
                Capsule().fill(Theme.accent)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
                    .animation(.easeOut(duration: 0.42), value: progress)
            }
        }
    }
}
