import SwiftUI

/// Full-screen progress view while the agent loop runs. Streams the live
/// assistant text and tool-use trace from the Worker so the user can see
/// what's happening (and for the course demo — visible multi-stage reasoning).
struct GeneratingView: View {
    @Environment(FlowModel.self) private var flow

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ProgressView()
                Text("Building your roadmap…").font(.headline)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(flow.liveTraces.enumerated()), id: \.offset) { _, trace in
                        AgentTraceInlineRow(dto: trace)
                    }
                    if !flow.liveAssistantText.isEmpty {
                        Text(flow.liveAssistantText)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if let err = flow.errorMessage {
                Text(err).foregroundStyle(.red).font(.footnote)
            }
        }
        .padding()
    }
}

struct AgentTraceInlineRow: View {
    let dto: AgentTraceDTO

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(dto.stage.uppercased())
                .font(.caption2.monospaced())
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(.ultraThinMaterial, in: .capsule)
            Text(dto.responseSummary ?? dto.requestSummary ?? "")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(dto.durationMs) ms")
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
        }
    }
}
