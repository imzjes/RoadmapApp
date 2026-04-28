import SwiftUI

/// Adaptive assessment screen.
///
/// Each question's `kind` from the worker drives the input affordance:
/// - `.closedChips`     → chip-only single-select + Continue
/// - `.chipsPlusOther`  → chips + "Other…" chip that reveals an inline text field
/// - `.open`            → text input only, no chips
struct AssessmentView: View {
    @Environment(FlowModel.self) private var flow
    @State private var draft: String = ""
    @State private var selectedChip: String? = nil
    @State private var otherExpanded: Bool = false
    @FocusState private var inputFocused: Bool

    private var entries: [AssessmentEntry] { flow.assessment }
    private var activeIndex: Int? { entries.lastIndex(where: { $0.answer == nil }) }
    private var current: AssessmentEntry? {
        guard let i = activeIndex else { return nil }
        return entries[i]
    }
    private var transcript: [AssessmentEntry] {
        guard let active = activeIndex else { return entries }
        return Array(entries.prefix(active))
    }
    private var turnIndex: Int { activeIndex ?? max(entries.count - 1, 0) }
    private var isFinal: Bool { entries.count >= 4 }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    transcriptList

                    if let q = current {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(q.question)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, transcript.isEmpty ? 8 : 4)

                        affordance(for: q)

                        if isFinal { finalizeHint }
                    } else if flow.isProcessing {
                        ProgressView().padding(.top, 24)
                    }

                    if let err = flow.errorMessage {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            bottomDock
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .appBackground()
        .navigationBarHidden(true)
        .onChange(of: current?.id) { _, _ in
            draft = ""
            selectedChip = nil
            otherExpanded = false
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.accent)
                    .frame(width: 28, height: 28)
                Text("R").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Roadmap").font(.system(size: 13, weight: .semibold))
                Text("Calibrating · question \(min(turnIndex + 1, 6)) of ~5")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<6, id: \.self) { i in
                    Capsule()
                        .fill(i <= turnIndex ? Theme.accent : Color(uiColor: .systemGray5))
                        .frame(width: i == turnIndex ? 16 : 6, height: 6)
                        .animation(.easeOut(duration: 0.2), value: turnIndex)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 12)
    }

    // MARK: Transcript

    @ViewBuilder
    private var transcriptList: some View {
        if !transcript.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(transcript) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.question)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                        if let answer = entry.answer {
                            HStack {
                                Spacer(minLength: 32)
                                Text(answer)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        UnevenRoundedRectangle(
                                            cornerRadii: .init(topLeading: 16, bottomLeading: 16, bottomTrailing: 4, topTrailing: 16),
                                            style: .continuous
                                        )
                                        .fill(Theme.accent.opacity(0.14))
                                    )
                            }
                        }
                    }
                    .opacity(0.62)
                }
            }
        }
    }

    // MARK: Affordance

    @ViewBuilder
    private func affordance(for entry: AssessmentEntry) -> some View {
        switch entry.kind {
        case .closedChips:
            chipGrid(entry: entry, includeOther: false)
        case .chipsPlusOther:
            VStack(alignment: .leading, spacing: 8) {
                chipGrid(entry: entry, includeOther: true)
                if otherExpanded {
                    inlineTextInput(placeholder: "Tell me in your own words…")
                        .padding(.top, 4)
                }
            }
        case .open:
            inlineTextInput(placeholder: "Type your answer…")
        }
    }

    private func chipGrid(entry: AssessmentEntry, includeOther: Bool) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(entry.suggestions, id: \.self) { chip in
                ChipButton(
                    label: chip,
                    selected: !otherExpanded && selectedChip == chip
                ) {
                    selectedChip = chip
                    otherExpanded = false
                }
            }
            if includeOther {
                ChipButton(
                    label: "Other…",
                    selected: otherExpanded,
                    leadingSymbol: otherExpanded ? nil : "plus"
                ) {
                    otherExpanded.toggle()
                    if otherExpanded {
                        selectedChip = nil
                        inputFocused = true
                    }
                }
            }
        }
    }

    private func inlineTextInput(placeholder: String) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField(placeholder, text: $draft, axis: .vertical)
                .font(.system(size: 16))
                .focused($inputFocused)
                .lineLimit(1...4)
                .padding(.leading, 14)
                .padding(.vertical, 8)

            Button {
                submit()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(draft.isEmpty ? Color(uiColor: .tertiaryLabel) : .white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(draft.isEmpty ? Color(uiColor: .systemGray5) : Theme.accent))
            }
            .padding(8)
            .disabled(draft.isEmpty || flow.isProcessing)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(inputFocused ? Theme.accent.opacity(0.55) : Color.black.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    // MARK: Finalize hint

    private var finalizeHint: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Theme.accent).frame(width: 26, height: 26)
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("I have enough to draft your plan.")
                    .font(.system(size: 13, weight: .semibold))
                Text("Answer this last one or skip ahead.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.accentSoft.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.accent.opacity(0.4), lineWidth: 0.5)
                )
        )
    }

    // MARK: Bottom dock

    private var bottomDock: some View {
        VStack(spacing: 10) {
            if let q = current {
                switch q.kind {
                case .closedChips:
                    Button { submit() } label: {
                        Group {
                            if flow.isProcessing { ProgressView().tint(.white) } else { Text("Continue") }
                        }
                    }
                    .buttonStyle(.primary())
                    .disabled(selectedChip == nil || flow.isProcessing)
                case .chipsPlusOther:
                    Button { submit() } label: {
                        Group {
                            if flow.isProcessing { ProgressView().tint(.white) } else { Text("Continue") }
                        }
                    }
                    .buttonStyle(.primary())
                    .disabled((otherExpanded ? draft.isEmpty : selectedChip == nil) || flow.isProcessing)
                case .open:
                    EmptyView()
                }
            }

            Button {
                flow.finishAssessment()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .semibold))
                    Text("Done — build my plan")
                        .font(.system(size: 13, weight: isFinal ? .semibold : .medium))
                }
                .foregroundStyle(isFinal ? Theme.accent : .secondary)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(
                    Capsule().fill(isFinal ? Theme.accentSoft : Color.clear)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 22)
        .background(
            Color(uiColor: .systemGroupedBackground).opacity(0.78)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(uiColor: .separator).opacity(0.6))
                        .frame(height: 0.5)
                }
        )
    }

    // MARK: Submission

    private func submit() {
        guard let q = current else { return }
        let answer: String
        switch q.kind {
        case .closedChips:
            answer = selectedChip ?? ""
        case .chipsPlusOther:
            answer = otherExpanded ? draft : (selectedChip ?? "")
        case .open:
            answer = draft
        }
        guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task { await flow.submitAssessmentAnswer(answer) }
    }
}

// MARK: - Simple flow layout (chips wrap)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                totalHeight += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        let maxX = bounds.maxX
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
