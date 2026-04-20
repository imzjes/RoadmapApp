import SwiftUI

/// Top-level router. Decides whether to show onboarding, the generation
/// screen, or the main tab bar based on `FlowModel.phase`.
struct RootView: View {
    @Environment(FlowModel.self) private var flow

    var body: some View {
        ZStack {
            switch flow.phase {
            case .launch:
                LaunchView()
                    .task { flow.bootstrap() }
            case .onboarding(let step):
                OnboardingContainerView(step: step)
            case .generating:
                GeneratingView()
            case .ready:
                MainTabView()
            }
        }
        .animation(.default, value: flow.phase)
    }
}

struct LaunchView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading…")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
