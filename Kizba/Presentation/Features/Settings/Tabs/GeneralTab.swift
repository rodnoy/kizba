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
                favoritesSection
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
                infoText: "Secrets copied to the clipboard are cleared automatically after this delay."
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
            FormFieldRow(
                label: "Menu bar",
                infoText: "Show the Kizba icon in the macOS menu bar for quick access."
            ) {
                Toggle(isOn: $model.showInMenuBar) {
                    Text("Show Kizba in menu bar")
                }
            }
        }
    }

    // MVP6 Phase G.1: Favorites visibility toggle. Placed above the
    // Recents section to mirror the sidebar order (Favorites render
    // above Recents in `SidebarView`).
    private var favoritesSection: some View {
        FormSection("Favorites") {
            FormFieldRow(
                label: "Visibility",
                infoText: "Display starred entries at the top of the sidebar."
            ) {
                Toggle(isOn: $model.showFavorites) {
                    Text("Show Favorites in Sidebar")
                }
            }
        }
    }

    private var recentsSection: some View {
        FormSection("Recents") {
            FormFieldRow(
                label: "Visibility",
                infoText: "Display recently used password entries at the top of the sidebar."
            ) {
                Toggle(isOn: $model.showRecents) {
                    Text("Show Recents in Sidebar")
                }
            }

            FormFieldRow(
                label: "Recents limit",
                infoText: "How many recent entries to show in the sidebar (3–7)."
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
