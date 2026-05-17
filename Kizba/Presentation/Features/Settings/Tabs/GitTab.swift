//
//  GitTab.swift
//  Kizba
//
//  Git settings tab: operation timeout and password-store path
//  override. Extracted from `SettingsView` in MVP6 Phase B.3.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct GitTab: View {

    @Bindable var model: SettingsModel

    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                gitSection
                storeSection
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var gitSection: some View {
        FormSection("Git") {
            FormFieldRow(
                label: "Operation timeout",
                infoText: "Maximum seconds to wait for any git operation before aborting."
            ) {
                HStack(spacing: theme.spacing.sm) {
                    Stepper(
                        value: $model.gitOperationTimeoutSeconds,
                        in: SettingsKeys.gitOperationTimeoutBounds,
                        step: 5
                    ) {
                        Text("\(model.gitOperationTimeoutSeconds) s")
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.onSurface)
                    }
                    .accessibilityLabel("Git operation timeout")
                    .accessibilityValue("\(model.gitOperationTimeoutSeconds) seconds")
                    .accessibilityHint("Seconds before git operations time out")
                    Spacer()
                }
            }
        }
    }

    private var storeSection: some View {
        FormSection("Store") {
            FormFieldRow(
                label: "Store path override",
                infoText: "Override the default password-store location (~/.password-store)."
            ) {
                HStack(spacing: theme.spacing.sm) {
                    TextField(
                        "Password store path override",
                        text: bindingForOptional(\.storePathOverride)
                    )
                    .textFieldStyle(.kizba)
                    pickerButton(allowsDirectories: true, helpText: "Browse for password store directory") { url in
                        model.storePathOverride = url.path
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func bindingForOptional(_ keyPath: ReferenceWritableKeyPath<SettingsModel, String?>) -> Binding<String> {
        Binding<String>(
            get: { model[keyPath: keyPath] ?? "" },
            set: { newValue in
                model[keyPath: keyPath] = newValue.isEmpty ? nil : newValue
            }
        )
    }

    @ViewBuilder
    private func pickerButton(
        allowsDirectories: Bool,
        helpText: String,
        completion: @escaping (URL) -> Void
    ) -> some View {
#if canImport(AppKit)
        Button {
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.canChooseDirectories = allowsDirectories
            panel.allowsMultipleSelection = false
            panel.begin { response in
                guard response == .OK, let url = panel.url else { return }
                Task { @MainActor in completion(url) }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .buttonStyle(.kizba(.ghost, size: .compact))
        .accessibilityLabel("Browse")
        .help(helpText)
#else
        EmptyView()
#endif
    }
}
