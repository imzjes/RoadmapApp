import SwiftUI

struct ResourceRow: View {
    let resource: Resource

    var body: some View {
        Group {
            if let url = resource.url {
                Link(destination: url) { content }
            } else {
                content
            }
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBG)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconFG)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text(resource.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let meta = metaLine {
                    Text(meta)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metaLine: String? {
        var parts: [String] = []
        if let min = resource.durationMinutes { parts.append("\(min) min") }
        if let author = resource.author { parts.append(author) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var icon: String {
        switch resource.kind {
        case .youtube, .video:  return "play.fill"
        case .article:          return "doc.text"
        case .doc:              return "book"
        case .podcast:          return "waveform"
        case .course:           return "graduationcap"
        }
    }

    private var iconBG: Color {
        switch resource.kind {
        case .youtube, .video:  return Color.red.opacity(0.14)
        case .article:          return Color.blue.opacity(0.12)
        case .doc, .course:     return Color(red: 120/255, green: 90/255, blue: 160/255).opacity(0.14)
        case .podcast:          return Theme.accentSoft
        }
    }

    private var iconFG: Color {
        switch resource.kind {
        case .youtube, .video:  return Color(red: 199/255, green: 62/255, blue: 62/255)
        case .article:          return .blue
        case .doc, .course:     return Color(red: 0x5E/255, green: 0x44/255, blue: 0x93/255)
        case .podcast:          return Theme.accent
        }
    }
}
