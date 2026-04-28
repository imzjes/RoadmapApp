import SwiftUI

/// Full-screen "agent thinking" view shown while the planner runs.
/// Centered indicator + a rolling log of stage pills, summaries, durations.
/// Driven by `FlowModel.liveTraces` once the Worker is wired up.
struct GeneratingView: View {
    @Environment(FlowModel.self) private var flow

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                Color.clear
                Button("Cancel") {
                    flow.startOver()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.trailing, 18)
                .padding(.top, 64)
            }
            .frame(height: 0)

            ThinkingIndicator()
                .padding(.top, 76)

            VStack(spacing: 4) {
                Text(headline)
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(subline)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            traceLog
                .padding(.horizontal, 16)
                .padding(.top, 4)

            if let err = flow.errorMessage {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Theme.Accent.mossSoft,
                    Theme.Accent.mossMid.opacity(0.55),
                    Color(uiColor: .systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var traceLog: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    if flow.liveTraces.isEmpty {
                        ForEach(GeneratingView.placeholderTrace, id: \.id) { row in
                            TraceLogRow(stage: row.stage, text: row.text, ms: row.ms, tool: row.tool, fresh: row.fresh)
                        }
                    } else {
                        ForEach(Array(flow.liveTraces.enumerated()), id: \.offset) { idx, dto in
                            TraceLogRow(
                                stage: AgentStage(rawValue: dto.stage) ?? .intake,
                                text: dto.responseSummary ?? dto.requestSummary ?? "",
                                ms: dto.durationMs,
                                tool: nil,
                                fresh: idx == flow.liveTraces.count - 1
                            )
                        }
                    }
                    ShimmerRow().padding(.vertical, 8).padding(.horizontal, 16)
                }
                .padding(.vertical, 14)
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.08),
                        .init(color: .black, location: 0.92),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(maxHeight: .infinity)
        .glassCard(padding: 0, radius: 18)
    }

    private var headline: String {
        switch flow.liveTraces.last?.stage {
        case "generate": return "Drafting your roadmap"
        case "enrich":   return "Looking things up"
        default:         return "Reading what you told me"
        }
    }

    private var subline: String {
        switch flow.liveTraces.last?.stage {
        case "generate": return "Sketching weeks, sessions, and sequencing."
        case "enrich":   return "Cross-checking sources so the plan holds up."
        default:         return "Picking apart the goal before I plan."
        }
    }

    private struct PlaceholderRow: Identifiable {
        let id = UUID()
        let stage: AgentStage
        let text: String
        let ms: Int
        var tool: String? = nil
        var fresh: Bool = false
    }

    private static let placeholderTrace: [PlaceholderRow] = [
        .init(stage: .intake, text: "Parsed goal · constraints · level", ms: 312),
        .init(stage: .assess, text: "Located in skill graph · 4 prereqs cleared", ms: 188),
        .init(stage: .assess, text: "Identified 3 gap areas: foundation, technique, repertoire", ms: 246),
        .init(stage: .generate, text: "Drafting weeks 1–4 (foundation block)", ms: 1104),
        .init(stage: .generate, text: "Sequencing daily sessions around your week", ms: 415, fresh: true)
    ]
}

// MARK: - Pieces

struct TraceLogRow: View {
    let stage: AgentStage
    let text: String
    let ms: Int
    var tool: String? = nil
    var fresh: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            StagePill(stage: stage)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let tool {
                    ToolChip(name: tool)
                }
            }
            Spacer(minLength: 0)
            Text("\(ms) ms")
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .opacity(fresh ? 1 : 0.85)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

struct ShimmerRow: View {
    @State private var on = false
    var body: some View {
        HStack(spacing: 9) {
            RoundedRectangle(cornerRadius: 5).fill(Color.gray.opacity(0.10)).frame(width: 28, height: 18)
            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.10)).frame(height: 11)
            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.10)).frame(width: 36, height: 11)
        }
        .opacity(on ? 1 : 0.6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                on = true
            }
        }
    }
}

struct ThinkingIndicator: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
                .frame(width: 96, height: 96)
                .scaleEffect(pulse ? 1.15 : 0.8)
                .opacity(pulse ? 0 : 0.9)
                .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: false), value: pulse)
            Circle()
                .stroke(Theme.accent.opacity(0.55), lineWidth: 1)
                .frame(width: 72, height: 72)
                .scaleEffect(pulse ? 1.15 : 0.8)
                .opacity(pulse ? 0 : 0.9)
                .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: false).delay(0.65), value: pulse)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Accent.mossMid, Theme.accent, Theme.accentStrong],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 38, height: 38)
                .shadow(color: Theme.accent.opacity(0.35), radius: 6, y: 4)
                .scaleEffect(pulse ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: pulse)
        }
        .frame(width: 96, height: 96)
        .onAppear { pulse = true }
    }
}
