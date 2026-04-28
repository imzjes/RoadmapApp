import SwiftData
import SwiftUI

struct WeeklyReviewView: View {
    @Query(sort: \Roadmap.updatedAt, order: .reverse) private var roadmaps: [Roadmap]

    var body: some View {
        Group {
            if let roadmap = roadmaps.first(where: { $0.status == .active }) ?? roadmaps.first {
                ReviewBody(roadmap: roadmap)
            } else {
                ContentUnavailableView(
                    "Nothing to review yet",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Come back after a week of practice.")
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ReviewBody: View {
    let roadmap: Roadmap
    @Environment(FlowModel.self) private var flow
    @State private var lastClassification: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                statRow.padding(.horizontal, 16).padding(.top, 4)
                weekStrip.padding(.horizontal, 16).padding(.top, 12)
                insight.padding(.horizontal, 20).padding(.top, 18)
                primaryAction.padding(.horizontal, 20).padding(.top, 16)
                agentTraceRow.padding(.horizontal, 20).padding(.top, 24)
            }
            .padding(.bottom, 110)
        }
        .background(
            LinearGradient(
                colors: [Theme.Accent.mossSoft, Theme.Surface.groupedBG],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionEyebrow(text: weekLabel, color: Theme.accent)
            Text("Weekly Review")
                .font(.system(size: 30, weight: .bold))
                .padding(.top, 4)
            Text("How last week went, and what to change next.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 70)
        .padding(.bottom, 18)
    }

    // MARK: Stats

    private var statRow: some View {
        HStack(spacing: 10) {
            StatTile(
                value: "\(stats.tasksDone)/\(stats.tasksPlanned)",
                label: "Tasks completed",
                symbol: "checkmark.square",
                sub: stats.tasksPlanned == 0 ? "—" : "\(Int(Double(stats.tasksDone) / Double(stats.tasksPlanned) * 100))% of plan",
                emphasized: true
            )
            StatTile(
                value: "\(streak.current)",
                label: "Current streak",
                symbol: "flame",
                sub: streak.current == 1 ? "day · keep going" : "days in a row"
            )
        }
    }

    // MARK: Week strip

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                SectionEyebrow(text: "THIS WEEK")
                Spacer()
                Text("\(stats.activeDays) days active")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    let on = stats.dayPattern[i]
                    VStack(spacing: 5) {
                        Capsule()
                            .fill(on ? Theme.accent : Color(uiColor: .systemGray5))
                            .frame(height: 4)
                        Text(weekdayLetter(i))
                            .font(.system(size: 9.5, weight: .medium))
                            .tracking(0.4)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.5)
                )
        )
    }

    private func weekdayLetter(_ i: Int) -> String {
        ["M", "T", "W", "T", "F", "S", "S"][i]
    }

    // MARK: Insight

    private var insight: some View {
        let isHeavy = stats.tasksDone >= 5
        let title = isHeavy
            ? "Strong week. Momentum is real."
            : (stats.tasksDone == 0 ? "A quiet week — that's okay." : "Small week — that's real life.")
        let body = isHeavy
            ? "You're outpacing the plan. Keep this rhythm and we'll pull the next milestone forward."
            : "We can shrink next week's plan to keep momentum without overcommitting. Want to revise?"
        return VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
            Text(body)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Primary action

    private var primaryAction: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    let notes = "Tasks done this week: \(stats.tasksDone) of \(stats.tasksPlanned). Active days: \(stats.activeDays). User has not flagged any specific concerns."
                    lastClassification = await flow.revise(notes: notes)
                }
            } label: {
                Group {
                    if flow.isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "wand.and.stars").font(.system(size: 17, weight: .semibold))
                            Text("Revise my plan")
                        }
                    }
                }
            }
            .buttonStyle(.primary())
            .disabled(flow.isProcessing)

            if let classification = lastClassification {
                Text(reviseFeedback(classification))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.accent)
            } else {
                Text(stats.tasksDone >= 5 ? "Push the pace, or hold steady." : "I'll shrink scope so this week feels doable.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if let err = flow.errorMessage {
                Text(err).font(.system(size: 12)).foregroundStyle(.red)
            }
        }
    }

    private func reviseFeedback(_ classification: String) -> String {
        switch classification.lowercased() {
        case "none":  return "Nothing to change — keep going."
        case "small": return "Small tweaks queued. Open Roadmap to see them."
        case "deep":  return "Deeper revision in progress. Open Roadmap to review."
        default:      return "Revision: \(classification)."
        }
    }

    // MARK: Agent trace row

    private var agentTraceRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionEyebrow(text: "BEHIND THE PLAN")
            NavigationLink {
                AgentTraceView(roadmap: roadmap)
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Theme.Stage.enrichBG)
                            .frame(width: 32, height: 32)
                        Image(systemName: "terminal")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.Stage.enrichFG)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Agent trace")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                        Text("Every reasoning step from this week's planning.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.Surface.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Computed stats

    private var stats: WeekStats { WeekStats.compute(roadmap: roadmap) }
    private var streak: StreakSummary { StreakEngine().summary(for: roadmap) }
    private var weekLabel: String {
        let cal = Calendar.current
        let now = Date()
        let weekStart = cal.date(byAdding: .day, value: -6, to: now) ?? now
        let fmt = Date.FormatStyle().month(.abbreviated).day()
        return "WEEK OF \(weekStart.formatted(fmt).uppercased()) – \(now.formatted(fmt).uppercased())"
    }
}

private struct WeekStats {
    var tasksDone: Int
    var tasksPlanned: Int
    var activeDays: Int
    var dayPattern: [Bool] // Mon..Sun

    static func compute(roadmap: Roadmap) -> WeekStats {
        let cal = Calendar.current
        let now = Date()
        let weekStart = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now

        let allTasks = roadmap.orderedPhases.flatMap(\.orderedTasks)
        let weekTasks = allTasks.filter { task in
            guard let scheduled = task.scheduledDate else { return false }
            return scheduled >= weekStart && scheduled <= now
        }
        let weekDone = weekTasks.filter(\.isCompleted)

        var pattern = Array(repeating: false, count: 7)
        for task in allTasks {
            guard let date = task.completedAt, date >= weekStart, date <= now else { continue }
            // Map Monday→0..Sunday→6
            let weekday = cal.component(.weekday, from: date) // Sun=1..Sat=7
            let idx = (weekday + 5) % 7
            pattern[idx] = true
        }

        let activeDays = pattern.filter { $0 }.count
        return WeekStats(
            tasksDone: weekDone.count,
            tasksPlanned: max(weekTasks.count, weekDone.count),
            activeDays: activeDays,
            dayPattern: pattern
        )
    }
}
