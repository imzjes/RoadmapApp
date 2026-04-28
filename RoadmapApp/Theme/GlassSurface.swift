import SwiftUI

struct GlassCardModifier: ViewModifier {
    var padding: CGFloat = 18
    var radius: CGFloat = Theme.Radius.lg
    var emphasized: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(glassBackground)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        emphasized ? Theme.accent.opacity(0.45) : Color.white.opacity(0.55),
                        lineWidth: 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    @ViewBuilder
    private var glassBackground: some View {
        if emphasized {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.85),
                    Theme.Accent.mossSoft.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .background(.regularMaterial)
        } else {
            Color.white.opacity(0.62)
                .background(.regularMaterial)
        }
    }
}

extension View {
    func glassCard(padding: CGFloat = 18, radius: CGFloat = Theme.Radius.lg, emphasized: Bool = false) -> some View {
        modifier(GlassCardModifier(padding: padding, radius: radius, emphasized: emphasized))
    }
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    var radius: CGFloat = Theme.Radius.lg
    var emphasized: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(padding: padding, radius: radius, emphasized: emphasized)
    }
}
