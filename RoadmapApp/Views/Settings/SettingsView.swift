import SwiftUI

struct SettingsView: View {
    @Environment(FlowModel.self) private var flow

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Settings")
                    .font(.system(size: 30, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                backendSection
                practiceSection
                aboutSection
            }
            .padding(.bottom, 40)
        }
        .background(Theme.Surface.groupedBG.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var backendSection: some View {
        SettingsGroup(
            title: "BACKEND",
            footer: AppSecrets.hasValidWorkerURL
                ? "Plans and traces sync to your Worker URL."
                : "Set a Worker URL to enable plan generation and audit logs."
        ) {
            VStack(spacing: 0) {
                SettingsRow(
                    label: "Worker URL",
                    value: AppSecrets.hasValidWorkerURL ? AppSecrets.workerBaseURL : "Not set",
                    valueColor: AppSecrets.hasValidWorkerURL ? Color.primary : Color.red,
                    monospacedValue: AppSecrets.hasValidWorkerURL,
                    chevron: true
                )
                Divider().padding(.leading, 16)
                SettingsRow(
                    label: "Connection status",
                    trailing: AnyView(
                        StatusBadge(
                            ok: AppSecrets.hasValidWorkerURL,
                            label: AppSecrets.hasValidWorkerURL ? "Configured" : "Not set"
                        )
                    )
                )
                Divider().padding(.leading, 16)
                SettingsRow(
                    label: "Last sync",
                    value: AppSecrets.hasValidWorkerURL ? "—" : "—",
                    monospacedValue: true,
                    isLast: true
                )
            }
        }
    }

    private var practiceSection: some View {
        SettingsGroup(
            title: "PRACTICE",
            footer: "Wipes assessment answers and re-runs the planner from scratch."
        ) {
            Button { flow.startOver() } label: {
                SettingsRow(
                    label: "Reset onboarding",
                    sublabel: "Debug only",
                    destructive: true,
                    trailing: AnyView(
                        HStack(spacing: 8) {
                            Text("DEBUG")
                                .font(.system(size: 9.5, weight: .heavy))
                                .tracking(0.6)
                                .foregroundStyle(Theme.Stage.assessFG)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.Stage.assessBG, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    ),
                    isLast: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutSection: some View {
        SettingsGroup(title: "ABOUT") {
            VStack(spacing: 0) {
                SettingsRow(label: "App", value: "Roadmap")
                Divider().padding(.leading, 16)
                SettingsRow(label: "Schema version", value: "v1", monospacedValue: true)
                Divider().padding(.leading, 16)
                SettingsRow(label: "Build", value: buildString, monospacedValue: true, isLast: true)
            }
        }
    }

    private var buildString: String {
        let info = Bundle.main.infoDictionary
        let version = (info?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let build = (info?["CFBundleVersion"] as? String) ?? "1"
        return "\(version) (\(build))"
    }
}

struct SettingsGroup<Content: View>: View {
    var title: String
    var footer: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionEyebrow(text: title)
                .padding(.horizontal, 24)
            content()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.Surface.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 16)
            if let footer {
                Text(footer)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.top, 2)
            }
        }
    }
}

struct SettingsRow: View {
    var label: String
    var sublabel: String? = nil
    var value: String? = nil
    var valueColor: Color = .secondary
    var monospacedValue: Bool = false
    var destructive: Bool = false
    var trailing: AnyView? = nil
    var chevron: Bool = false
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(destructive ? Color.red : .primary)
                if let sublabel {
                    Text(sublabel)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let value {
                Text(value)
                    .font(monospacedValue
                          ? .system(size: 13, weight: .medium).monospaced()
                          : .system(size: 15))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if let trailing {
                trailing
            } else if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .padding(.vertical, 6)
    }
}
