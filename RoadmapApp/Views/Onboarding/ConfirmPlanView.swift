import SwiftUI

struct ConfirmPlanView: View {
    @Environment(FlowModel.self) private var flow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionEyebrow(text: "ALMOST READY", color: Theme.accent)
                .padding(.top, 60)
                .padding(.bottom, 6)

            Text("Ready to build your roadmap.")
                .font(.system(size: 30, weight: .bold))
                .padding(.bottom, 8)

            Text("I'll combine your goal with what you told me in the assessment, then draft a plan you can edit.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)

            GlassCard {
                VStack(alignment: .leading, spacing: 6) {
                    SectionEyebrow(text: "YOUR GOAL")
                    Text(flow.goalDraft)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.primary)
                }
            }

            Spacer()

            Button {
                Task { await flow.generate() }
            } label: {
                Text("Generate roadmap")
            }
            .buttonStyle(.primary())
            .padding(.bottom, 8)

            Button(role: .destructive) {
                flow.startOver()
            } label: {
                Text("Start over")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .appBackground()
        .navigationBarHidden(true)
    }
}
