import SwiftUI

struct GoalEntryView: View {
    @Environment(FlowModel.self) private var flow
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var flow = flow
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What do you want to learn?")
                    .font(.largeTitle.bold())
                Text("A short sentence is enough. The app will ask a few follow-ups to shape your roadmap.")
                    .foregroundStyle(.secondary)
            }

            TextField("e.g. fingerstyle guitar, basic Mandarin, Rust for web", text: $flow.goalDraft, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .textFieldStyle(.roundedBorder)
                .focused($focused)

            Spacer()

            Button {
                Task { await flow.submitGoal() }
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(flow.goalDraft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
        .onAppear { focused = true }
        .navigationTitle("New Roadmap")
        .navigationBarTitleDisplayMode(.inline)
    }
}
