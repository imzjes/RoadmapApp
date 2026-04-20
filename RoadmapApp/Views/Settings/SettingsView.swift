import SwiftUI

struct SettingsView: View {
    @Environment(FlowModel.self) private var flow

    var body: some View {
        List {
            Section("Backend") {
                LabeledContent("Worker URL") {
                    Text(AppSecrets.hasValidWorkerURL ? "Configured" : "Not set")
                        .foregroundStyle(AppSecrets.hasValidWorkerURL ? .green : .orange)
                }
            }

            Section("Practice") {
                Button("Reset onboarding (debug)", role: .destructive) {
                    flow.startOver()
                }
            }

            Section("About") {
                LabeledContent("App", value: "RoadmapApp")
                LabeledContent("Schema", value: "v1")
            }
        }
        .navigationTitle("Settings")
    }
}
