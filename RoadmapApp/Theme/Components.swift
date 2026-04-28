import SwiftUI

// MARK: - Buttons

enum PrimaryButtonVariant {
    case filled
    case tinted
    case plain
}

struct PrimaryButtonStyle: ButtonStyle {
    var variant: PrimaryButtonVariant = .filled
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 50)
            .padding(.horizontal, 22)
            .background(background)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .filled: Theme.accent
        case .tinted: Theme.accentSoft
        case .plain:  Color.clear
        }
    }

    private var foreground: Color {
        switch variant {
        case .filled: return .white
        case .tinted, .plain: return Theme.accent
        }
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static func primary(_ variant: PrimaryButtonVariant = .filled, fullWidth: Bool = true) -> PrimaryButtonStyle {
        PrimaryButtonStyle(variant: variant, fullWidth: fullWidth)
    }
}

// MARK: - Chips

struct ChipButton: View {
    let label: String
    var selected: Bool = false
    var leadingSymbol: String? = nil
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if selected {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold))
                } else if let symbol = leadingSymbol {
                    Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
                }
                Text(label).font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(selected ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(
                Group {
                    if selected {
                        Capsule().fill(Theme.accent)
                    } else {
                        Capsule().fill(Color.white.opacity(0.78))
                            .overlay(Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5))
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stage pill

struct StagePill: View {
    let stage: AgentStage

    var body: some View {
        Text(stage.rawValue.uppercased())
            .font(.system(size: 9.5, weight: .heavy))
            .tracking(0.6)
            .foregroundStyle(colors.fg)
            .padding(.horizontal, 7)
            .frame(height: 18)
            .background(colors.bg, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private var colors: (bg: Color, fg: Color) {
        switch stage {
        case .intake:    return (Theme.Stage.intakeBG, Theme.Stage.intakeFG)
        case .assess:    return (Theme.Stage.assessBG, Theme.Stage.assessFG)
        case .generate:  return (Theme.Stage.generateBG, Theme.Stage.generateFG)
        case .enrich, .resources: return (Theme.Stage.enrichBG, Theme.Stage.enrichFG)
        case .revise:    return (Theme.Stage.reviseBG, Theme.Stage.reviseFG)
        }
    }
}

// MARK: - Tool chip

struct ToolChip: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "wrench").font(.system(size: 9, weight: .semibold))
            Text(name).font(.system(size: 10, weight: .semibold).monospaced())
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
        .frame(height: 16)
        .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

// MARK: - Section header

struct SectionEyebrow: View {
    let text: String
    var color: Color = .secondary

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .medium))
            .tracking(0.6)
            .foregroundStyle(color)
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let value: String
    let label: String
    let symbol: String
    var sub: String? = nil
    var emphasized: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.6)
            }
            .foregroundStyle(emphasized ? Theme.accent : .secondary)

            Text(value)
                .font(.system(size: 36, weight: .bold).monospacedDigit())
                .foregroundStyle(emphasized ? Theme.accentStrong : .primary)
                .padding(.top, 2)

            if let sub {
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 16, radius: 18, emphasized: emphasized)
    }
}

// MARK: - Status badge (Settings)

struct StatusBadge: View {
    let ok: Bool
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(ok ? Color.green : Color.red).frame(width: 6, height: 6)
            Text(label).font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(ok ? Color(red: 0x1B/255, green: 0x7A/255, blue: 0x33/255)
                            : Color(red: 0xB8/255, green: 0x32/255, blue: 0x27/255))
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(
            Capsule().fill(ok ? Color.green.opacity(0.14) : Color.red.opacity(0.12))
        )
    }
}

// MARK: - Slim phase progress dots

struct PhaseDots: View {
    let count: Int
    let doneCount: Int
    let isActive: Bool
    let isQueued: Bool

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { i in
                let done = i < doneCount
                let activeDot = isActive && i == doneCount
                Capsule()
                    .fill(color(done: done, active: activeDot))
                    .frame(width: activeDot ? 16 : 6, height: 6)
                    .animation(.easeOut(duration: 0.2), value: doneCount)
            }
        }
    }

    private func color(done: Bool, active: Bool) -> Color {
        if done || active { return Theme.accent }
        if isQueued { return Color(uiColor: .systemGray4).opacity(0.7) }
        return Color(uiColor: .systemGray5)
    }
}
