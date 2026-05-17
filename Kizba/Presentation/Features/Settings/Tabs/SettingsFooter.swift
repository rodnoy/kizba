//
//  SettingsFooter.swift
//  Kizba
//
//  Shared footer rendered once below the Settings `TabView`
//  (MVP6 Phase B.3). Hosts the app version on the leading edge,
//  the inline save-state label, and the Reset / Save actions on
//  the trailing edge. Replaces the prior `.safeAreaInset(.bottom)`
//  version label + the per-section `actionsSection` HStack.
//

import SwiftUI

struct SettingsFooter: View {

    @Bindable var model: SettingsModel
    let version: String
    let build: String

    @State private var showingResetConfirmation = false

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            Text("Version \(version) (\(build))")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)

            Spacer()

            saveStatusLabel

            Button("Reset to Defaults") {
                showingResetConfirmation = true
            }
            .buttonStyle(.kizba(.destructive))
            .keyboardShortcut(.cancelAction)

            Button("Save") {
                Task { await model.save() }
            }
            .buttonStyle(.kizba(.primary))
            .keyboardShortcut(.defaultAction)
            .disabled(!model.hasChanges || model.saveState == .saving)
            .help("Save settings")
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
        .destructiveConfirmation(
            isPresented: $showingResetConfirmation,
            title: "Reset to Defaults?",
            message: "This will clear all overrides and restore the clipboard delay to the default value.",
            confirmLabel: "Reset"
        ) {
            model.resetToDefaults()
        }
    }

    /// Inline footer status mirroring `SettingsModel.saveState`. Hidden
    /// while `.idle` so the row collapses to a clean Reset / Save pair
    /// at rest. Tokens follow the DS convention used by `BannerView`:
    /// `caption` typography, `onSurfaceMuted` for the transient
    /// "Saving…" state, `success` for the post-write confirmation.
    @ViewBuilder
    private var saveStatusLabel: some View {
        switch model.saveState {
        case .idle:
            EmptyView()
        case .saving:
            Text("Saving…")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)
                .accessibilityLabel("Saving settings")
        case .saved:
            Text("Saved")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.success)
                .accessibilityLabel("Settings saved")
        }
    }
}
