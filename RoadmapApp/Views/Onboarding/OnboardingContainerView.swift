import SwiftUI

struct OnboardingContainerView: View {
    let step: OnboardingStep

    var body: some View {
        NavigationStack {
            switch step {
            case .goal:
                GoalEntryView()
            case .assessment:
                AssessmentView()
            case .confirm:
                ConfirmPlanView()
            }
        }
    }
}
