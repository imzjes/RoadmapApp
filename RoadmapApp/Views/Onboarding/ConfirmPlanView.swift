import SwiftUI

struct ConfirmPlanView: View {
    @Environment(FlowModel.self) private var flow

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ready to build your roadmap.")
                .font(.title2.bold())
            Text("Goal: \(flow.goalDraft)")
                .foregroundStyle(.secondary)

            Spacer()

            Button("Generate roadmap") { flow.generate() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

            Button("Start over", role: .destructive) { flow.startOver() }
                .frame(maxWidth: .infinity)
        }
        .padding()
        .navigationTitle("Confirm")
        .navigationBarTitleDisplayMode(.inline)
    }
}
