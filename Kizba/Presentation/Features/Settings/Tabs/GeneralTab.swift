//
//  GeneralTab.swift
//  Kizba
//
//  General settings tab: clipboard auto-clear delay, menu bar
//  visibility, and the Recents sidebar section. Extracted from the
//  monolithic `SettingsView` in MVP6 Phase B.3 — content moved
//  verbatim; InfoTooltip rollout lands in Phase B.4.
//

import SwiftUI

struct GeneralTab: View {

    @Bindable var model: SettingsModel

    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                clipboardSection
                menuBarSection
                recentsSection
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var clipboardSection: some View {
        FormSection("Clipboard") {
            FormFieldRow(
                label: "Auto-clear delay",
                helpText: "Seconds before a copied secret is cleared from the pasteboard."
            ) {
                HStack(spacing: theme.spacing.sm) {
                    // Native `Stepper` has no theme hook — left system-rendered
                    // intentionally; its label adopts the surrounding font.
                    Stepper(
                        value: $model.clipboardClearDelaySeconds,
                        in: SettingsKeys.clipboardClearDelayBounds,
                        step: 5
                    ) {
                        Text("\(model.clipboardClearDelaySeconds) s")
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.onSurface)
                    }
                    Spacer()
                }
            }
        }
    }

    private var menuBarSection: some View {
        FormSection("Menu Bar") {
            FormFieldRow(label: "Menu bar") {
                Toggle(isOn: $model.showInMenuBar) {
                    Text("Show Kizba in menu bar")
                }
            }
        }
    }

    private var recentsSection: some View {
        FormSection("Recents") {
            FormFieldRow(
                label: "Visibility",
                helpText: "When disabled, the Recents section is hidden from the sidebar entirely."
            ) {
                Toggle(isOn: $model.showRecents) {
                    Text("Show Recents in Sidebar")
                }
            }

            FormFieldRow(
                label: "Recents limit",
                helpText: "Maximum number of recently-viewed entries shown in the sidebar."
            ) {
                HStack(spacing: theme.spacing.sm) {
                    Stepper(
                        value: $model.recentsLimit,
                        in: SettingsKeys.recentsLimitBounds,
                        step: 1
                    ) {
                        Text("\(model.recentsLimit) entries")
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.onSurface)
                    }
                    .accessibilityLabel("Recents limit")
                    .accessibilityValue("\(model.recentsLimit) entries")
                    .accessibilityHint("Maximum number of entries kept in the sidebar Recents section")
                    Spacer()
                }
            }
        }
    }
}
