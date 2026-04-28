import SwiftUI

struct StreakPill: View {
    let summary: StreakSummary

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13, weight: .semibold))
            Text("\(summary.current)-day streak")
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(
            Capsule().fill(Theme.accentSoft)
        )
    }
}
