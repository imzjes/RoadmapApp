import SwiftUI

struct StreakPill: View {
    let summary: StreakSummary

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill").foregroundStyle(.orange)
            Text("\(summary.current) d")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.ultraThinMaterial, in: .capsule)
    }
}
