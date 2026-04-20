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
    }

    private var content: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(resource.title)
                if let author = resource.author {
                    Text(author).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let min = resource.durationMinutes {
                Text("\(min) min").font(.caption.monospaced()).foregroundStyle(.tertiary)
            }
        }
    }

    private var icon: String {
        switch resource.kind {
        case .youtube, .video: "play.rectangle"
        case .article: "doc.text"
        case .doc: "book"
        case .podcast: "waveform"
        case .course: "graduationcap"
        }
    }
}
