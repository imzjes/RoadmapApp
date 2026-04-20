import SwiftUI

/// Placeholder assessment loop. The real implementation streams questions
/// from the Worker's `/v1/assess` endpoint one turn at a time; for now we
/// render a static list so the flow navigates.
struct AssessmentView: View {
    @Environment(FlowModel.self) private var flow
    @State private var answer: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(flow.assessmentTranscript.enumerated()), id: \.offset) { _, turn in
                        if let q = turn.question {
                            Text(q).bold()
                        }
                        if let a = turn.answer {
                            Text(a).foregroundStyle(.secondary)
                        }
                    }
                    if !flow.liveAssistantText.isEmpty {
                        Text(flow.liveAssistantText).italic().foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                TextField("Your answer", text: $answer)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    flow.submitAssessmentAnswer(answer)
                    answer = ""
                }
                .disabled(answer.isEmpty)
            }

            Button("Done — generate my plan") {
                flow.finishAssessment()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .navigationTitle("Assessment")
        .navigationBarTitleDisplayMode(.inline)
    }
}
