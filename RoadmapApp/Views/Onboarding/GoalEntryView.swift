import SwiftUI

struct GoalEntryView: View {
    @Environment(FlowModel.self) private var flow
    @FocusState private var focused: Bool
    @State private var placeholderIndex: Int = 0

    private let placeholders: [String] = [
        "e.g. Learn classical guitar in 12 weeks",
        "e.g. Get conversational in Japanese",
        "e.g. Read 24 books this year",
        "e.g. Run a half marathon by October"
    ]

    private let suggestions: [String] = [
        "Classical guitar",
        "Conversational Japanese",
        "24 books this year"
    ]

    var body: some View {
        @Bindable var flow = flow

        VStack(alignment: .leading, spacing: 0) {
            // Logo placeholder mark
            RoadmapMark()
                .frame(width: 40, height: 40)
                .padding(.bottom, focused ? 18 : 32)

            Text("What do you\nwant to learn?")
                .font(.system(size: focused ? 28 : 34, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.bottom, 10)

            Text("A short sentence is enough — we'll ask follow-ups.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)

            ZStack(alignment: .topLeading) {
                if flow.goalDraft.isEmpty {
                    Text(placeholders[placeholderIndex])
                        .font(.system(size: 19))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .allowsHitTesting(false)
                }
                TextField("", text: $flow.goalDraft, axis: .vertical)
                    .font(.system(size: 19))
                    .lineLimit(2...4)
                    .focused($focused)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .tint(Theme.accent)
            }
            .frame(minHeight: 52, alignment: .topLeading)
            .glassCard(padding: 12, emphasized: focused)
            .padding(.bottom, 14)

            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { s in
                    Button {
                        flow.goalDraft = s
                    } label: {
                        Text(s)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(
                                Capsule().fill(Color.white.opacity(0.7))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button {
                Task { await flow.submitGoal() }
            } label: {
                Group {
                    if flow.isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Continue")
                    }
                }
            }
            .buttonStyle(.primary())
            .disabled(flow.goalDraft.trimmingCharacters(in: .whitespaces).isEmpty || flow.isProcessing)
            .padding(.bottom, 8)

            if let err = flow.errorMessage {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .padding(.bottom, 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .appBackground()
        .onAppear {
            focused = true
            startPlaceholderRotation()
        }
        .navigationBarHidden(true)
    }

    private func startPlaceholderRotation() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.2))
                if flow.goalDraft.isEmpty {
                    withAnimation(.easeInOut) {
                        placeholderIndex = (placeholderIndex + 1) % placeholders.count
                    }
                }
            }
        }
    }
}

/// Placeholder brand mark — a stylized roadmap line with three milestone dots.
struct RoadmapMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Theme.accentSoft)
            Path { path in
                path.move(to: CGPoint(x: 6, y: 28))
                path.addCurve(
                    to: CGPoint(x: 34, y: 12),
                    control1: CGPoint(x: 14, y: 8),
                    control2: CGPoint(x: 22, y: 32)
                )
            }
            .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 40, height: 40)

            Circle().fill(Theme.accentStrong).frame(width: 5, height: 5).offset(x: -14, y: 8)
            Circle().fill(Theme.accentStrong).frame(width: 5, height: 5).offset(x: 0, y: 0)
            Circle().fill(Theme.accentStrong).frame(width: 5, height: 5).offset(x: 14, y: -8)
        }
    }
}
