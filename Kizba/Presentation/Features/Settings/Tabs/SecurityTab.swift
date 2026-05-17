//
//  SecurityTab.swift
//  Kizba
//
//  Security settings tab. Currently hosts the per-reveal Touch ID
//  toggle moved verbatim from the monolithic `SettingsView` (MVP6
//  Phase B.3). The full Touch ID rework is scheduled for Phase D.
//

import SwiftUI

struct SecurityTab: View {

    @Bindable var model: SettingsModel

    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                touchIDSection
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var touchIDSection: some View {
        FormSection("Security") {
            FormFieldRow(
                label: "Require Touch ID for reveal",
                infoText: "Require Touch ID authentication for every secret reveal."
            ) {
                Toggle(isOn: $model.touchIDPerRevealEnabled) {
                    Text("Require Touch ID for password reveal")
                }
            }
        }
    }
}
