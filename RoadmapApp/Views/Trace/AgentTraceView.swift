import SwiftData
import SwiftUI

/// Displays every `AgentTrace` recorded for a roadmap — the course demo
/// screen. Shows stage, model, tokens in/out, and duration per call.
struct AgentTraceView: View {
    let roadmap: Roadmap

    var body: some View {
        let traces = (roadmap.traces ?? []).sorted { $0.createdAt < $1.createdAt }
        List {
            Section {
                LabeledContent("Total calls", value: "\(traces.count)")
                LabeledContent("Input tokens", value: "\(traces.reduce(0) { $0 + $1.inputTokens })")
                LabeledContent("Output tokens", value: "\(traces.reduce(0) { $0 + $1.outputTokens })")
                LabeledContent("Cached input", value: "\(traces.reduce(0) { $0 + $1.cachedInputTokens })")
            }
            ForEach(traces) { trace in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(trace.stage.rawValue.uppercased())
                            .font(.caption.monospaced())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.ultraThinMaterial, in: .capsule)
                        Text(trace.model).font(.caption.monospaced()).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(trace.durationMs) ms").font(.caption.monospaced()).foregroundStyle(.tertiary)
                    }
                    if let summary = trace.responseSummary ?? trace.requestSummary {
                        Text(summary).font(.footnote)
                    }
                    Text("in: \(trace.inputTokens) / cached: \(trace.cachedInputTokens) / out: \(trace.outputTokens)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Agent Trace")
        .navigationBarTitleDisplayMode(.inline)
    }
}
