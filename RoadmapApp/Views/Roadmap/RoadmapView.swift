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
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct RoadmapDetailView: View {
    let roadmap: Roadmap

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                summaryHeader
                overallProgressStrip
                phaseSections.padding(.horizontal, 16)
            }
            .padding(.bottom, 110)
        }
        .background(Theme.Surface.groupedBG.ignoresSafeArea())
        .navigationDestination(for: UUID.self) { id in
            if let task = roadmap.orderedPhases.flatMap(\.orderedTasks).first(where: { $0.id == id }) {
                TaskDetailView(task: task)
            }
        }
    }

    // MARK: Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionEyebrow(text: weekCountLabel, color: Theme.accent)
                .padding(.bottom, 4)
            Text(roadmap.title ?? roadmap.goal)
                .font(.system(size: 28, weight: .bold))
                .padding(.bottom, 6)
            if let summary = roadmap.summary {
                Text(summary)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 14)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 70)
    }

    private var weekCountLabel: String {
        let weeks = roadmap.orderedPhases.reduce(0) { $0 + $1.targetWeeks }
        return weeks > 0 ? "\(weeks)-WEEK ROADMAP" : "ROADMAP"
    }

    // MARK: Overall progress

    private var overallProgressStrip: some View {
        HStack(spacing: 10) {
            ProgressBar(progress: total > 0 ? Double(done) / Double(total) : 0)
                .frame(height: 5)
            Text("\(done) / \(total)")
                .font(.system(size: 12, weight: .medium).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }

    // MARK: Phase sections

    private var phaseSections: some View {
        VStack(spacing: 12) {
            ForEach(Array(roadmap.orderedPhases.enumerated()), id: \.element.id) { idx, phase in
                PhaseSectionView(
                    phase: phase,
                    phaseNumber: idx + 1,
                    state: phaseState(for: phase, index: idx),
                    expanded: phaseState(for: phase, index: idx) == .active
                )
            }
        }
    }

    private func phaseState(for phase: Phase, index: Int) -> PhaseSectionView.State {
        let allDone = !phase.orderedTasks.isEmpty && phase.orderedTasks.allSatisfy(\.isCompleted)
        if allDone { return .done }
        let activeIndex = roadmap.orderedPhases.firstIndex { ph in
            ph.orderedTasks.contains { !$0.isCompleted }
        } ?? 0
        return index == activeIndex ? .active : .queued
    }

    // MARK: Stats

    private var total: Int {
        roadmap.orderedPhases.reduce(0) { $0 + $1.orderedTasks.count }
    }

    private var done: Int {
        roadmap.orderedPhases.flatMap(\.orderedTasks).filter(\.isCompleted).count
    }
}

// MARK: - Phase section

struct PhaseSectionView: View {
    enum State { case done, active, queued }

    let phase: Phase
    let phaseNumber: Int
    let state: State
    let expanded: Bool
    @Environment(FlowModel.self) private var flow

    var body: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, 16).padding(.top, 14)
            dotsRow.padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
            if expanded {
                Divider().background(Color.white.opacity(0.4))
                taskList
                if !hasResources {
                    enrichButton
                }
            }
        }
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .opacity(state == .queued ? 0.62 : 1)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(numberFill)
                    .frame(width: 32, height: 32)
                if state == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text(String(format: "%02d", phaseNumber))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(state == .queued ? Color.secondary.opacity(0.7) : Color.white)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 8) {
                    Text(phase.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(state == .queued ? Color.secondary : .primary)
                    if state == .active {
                        Text("NOW")
                            .font(.system(size: 9.5, weight: .heavy))
                            .tracking(0.6)
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }
                if let summary = phase.summary {
                    Text(summary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var dotsRow: some View {
        HStack(spacing: 10) {
            PhaseDots(
                count: phase.orderedTasks.count,
                doneCount: doneCount,
                isActive: state == .active,
                isQueued: state == .queued
            )
            Text(countLabel)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    private var taskList: some View {
        VStack(spacing: 0) {
            ForEach(Array(phase.orderedTasks.enumerated()), id: \.element.id) { idx, task in
                NavigationLink(value: task.id) {
                    HStack(spacing: 12) {
                        CompletionToggle(
                            isOn: task.isCompleted,
                            size: 18
                        ) { RoadmapStore.shared.toggleCompletion(task) }
                        Text(task.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(task.isCompleted ? Color.secondary : .primary)
                            .strikethrough(task.isCompleted, color: .secondary)
                        Spacer(minLength: 8)
                        Text("\(task.durationMinutes)m")
                            .font(.system(size: 12, weight: .medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                if idx < phase.orderedTasks.count - 1 {
                    Divider().padding(.leading, 46)
                }
            }
        }
        .background(Color.white.opacity(0.5))
    }

    @ViewBuilder
    private var background: some View {
        switch state {
        case .active:
            LinearGradient(
                colors: [Color.white.opacity(0.85), Theme.accentSoft.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .background(.regularMaterial)
        case .done:
            Color.white.opacity(0.78).background(.regularMaterial)
        case .queued:
            Color.white.opacity(0.55).background(.regularMaterial)
        }
    }

    private var borderColor: Color {
        switch state {
        case .active: return Theme.accent.opacity(0.45)
        default:      return Color.white.opacity(0.55)
        }
    }

    private var numberFill: Color {
        switch state {
        case .done:   return .green
        case .active: return Theme.accent
        case .queued: return Color(uiColor: .systemGray5)
        }
    }

    private var doneCount: Int { phase.orderedTasks.filter(\.isCompleted).count }

    private var countLabel: String {
        switch state {
        case .done:   return "Complete"
        case .active: return "\(doneCount) of \(phase.orderedTasks.count)"
        case .queued: return "\(phase.orderedTasks.count) tasks"
        }
    }

    private var hasResources: Bool {
        phase.orderedTasks.contains { !($0.resources ?? []).isEmpty }
    }

    private var enrichButton: some View {
        VStack(spacing: 0) {
            Button {
                Task { await flow.enrichPhase(phase) }
            } label: {
                HStack(spacing: 8) {
                    if flow.isProcessing {
                        ProgressView().tint(Theme.accent).controlSize(.small)
                        Text("Searching the web…").font(.system(size: 13, weight: .medium))
                    } else {
                        Image(systemName: "sparkles").font(.system(size: 13, weight: .semibold))
                        Text("Find resources for this phase").font(.system(size: 13, weight: .medium))
                    }
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .disabled(flow.isProcessing)

            if let err = flow.errorMessage {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.06))
            }
        }
    }
}
