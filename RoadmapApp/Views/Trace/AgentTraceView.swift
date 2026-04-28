import SwiftData
import SwiftUI

/// Full audit log of agent calls. Each row shows stage / model / duration on
/// line one, a short summary on line two, and token counts on line three.
/// Rows are grouped by run (onboarding day vs. weekly review day).
struct AgentTraceView: View {
    let roadmap: Roadmap
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                pageHeader

                if groupedTraces.isEmpty {
                    emptyHint
                } else {
                    ForEach(groupedTraces, id: \.label) { group in
                        TraceGroupView(
                            label: group.label,
                            when: group.when,
                            traces: group.traces
                        )
                        .padding(.bottom, 18)
                    }
                }
            }
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
                        Text("Review").font(.system(size: 17, weight: .medium))
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Agent trace")
                    .font(.system(size: 16, weight: .semibold))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Reasoning audit")
                .font(.system(size: 26, weight: .bold))
            Text("Every step the planner took. Inspect any row to see the raw I/O.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }

    private var emptyHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No traces recorded yet.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: Grouping

    private struct Group {
        let label: String
        let when: String
        let traces: [AgentTrace]
    }

    private var groupedTraces: [Group] {
        let allTraces = (roadmap.traces ?? []).sorted { $0.createdAt < $1.createdAt }
        guard !allTraces.isEmpty else { return [] }

        let cal = Calendar.current
        let buckets = Dictionary(grouping: allTraces) { trace -> Date in
            cal.startOfDay(for: trace.createdAt)
        }
        let sorted = buckets.keys.sorted(by: >)

        return sorted.enumerated().map { idx, day in
            let traces = buckets[day] ?? []
            let label: String
            if cal.isDateInToday(day) {
                label = idx == 0 ? "TODAY · LATEST RUN" : "TODAY"
            } else {
                let days = cal.dateComponents([.day], from: day, to: Date()).day ?? 0
                label = days == 1 ? "YESTERDAY" : "\(days) DAYS AGO"
            }
            let fmt = Date.FormatStyle()
                .weekday(.abbreviated).month(.abbreviated).day()
                .hour().minute()
            return Group(
                label: label,
                when: traces.first?.createdAt.formatted(fmt) ?? "",
                traces: traces
            )
        }
    }
}

// MARK: - Group

struct TraceGroupView: View {
    let label: String
    let when: String
    let traces: [AgentTrace]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    SectionEyebrow(text: label)
                    Text(when)
                        .font(.system(size: 13, weight: .medium))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(String(format: "%.1f", Double(totalMs) / 1000))s · \(traces.count) steps")
                        .font(.system(size: 11, weight: .medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text("\(totalTok.formatted(.number)) tok total")
                        .font(.system(size: 11, weight: .medium).monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(traces.enumerated()), id: \.element.id) { idx, trace in
                    TraceDetailRow(trace: trace, isLast: idx == traces.count - 1)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.Surface.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 16)
        }
    }

    private var totalMs: Int { traces.reduce(0) { $0 + $1.durationMs } }
    private var totalTok: Int { traces.reduce(0) { $0 + $1.inputTokens + $1.outputTokens } }
}

struct TraceDetailRow: View {
    let trace: AgentTrace
    let isLast: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                StagePill(stage: trace.stage)
                Text(trace.model)
                    .font(.system(size: 12, weight: .semibold).monospaced())
                Spacer()
                Text("\(trace.durationMs.formatted(.number)) ms")
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(trace.createdAt.formatted(.dateTime.hour().minute().second()))
                    .font(.system(size: 10.5, weight: .medium).monospaced())
                    .foregroundStyle(.tertiary)
            }
            if let summary = trace.responseSummary ?? trace.requestSummary {
                Text(summary)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 4) {
                Text("in").foregroundStyle(.tertiary)
                Text(trace.inputTokens.formatted(.number))
                Text("·").foregroundStyle(.tertiary)
                Text("cached").foregroundStyle(.tertiary)
                Text(trace.cachedInputTokens.formatted(.number))
                Text("·").foregroundStyle(.tertiary)
                Text("out").foregroundStyle(.tertiary)
                Text(trace.outputTokens.formatted(.number))
            }
            .font(.system(size: 10.5, weight: .medium).monospaced())
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color(uiColor: .separator).opacity(0.5)).frame(height: 0.5)
                    .padding(.leading, 16)
            }
        }
    }
}
