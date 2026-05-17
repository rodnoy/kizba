//
//  AdvancedTab.swift
//  Kizba
//
//  Advanced settings tab: pass / gpg / pinentry binary overrides
//  and the Re-detect action. Extracted from `SettingsView` in
//  MVP6 Phase B.3.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct AdvancedTab: View {

    @Bindable var model: SettingsModel

    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                binariesSection
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var binariesSection: some View {
        FormSection("Binaries") {
            FormFieldRow(
                label: "pass",
                infoText: "Absolute path to the pass binary. Leave empty for auto-detection."
            ) {
                HStack(spacing: theme.spacing.sm) {
                    TextField(
                        "pass binary override",
                        text: bindingForOptional(\.passBinaryOverride)
                    )
                    .textFieldStyle(.kizba)
                    pickerButton(allowsDirectories: false, helpText: "Browse for pass binary") { url in
                        model.passBinaryOverride = url.path
                    }
                }
            }

            FormFieldRow(
                label: "gpg",
                infoText: "Absolute path to the gpg binary. Leave empty for auto-detection."
            ) {
                HStack(spacing: theme.spacing.sm) {
                    TextField(
                        "gpg binary override",
                        text: bindingForOptional(\.gpgBinaryOverride)
                    )
                    .textFieldStyle(.kizba)
                    pickerButton(allowsDirectories: false, helpText: "Browse for gpg binary") { url in
                        model.gpgBinaryOverride = url.path
                    }
                }
            }

            FormFieldRow(
                label: "pinentry",
                infoText: "Absolute path to the pinentry binary. Leave empty for auto-detection."
            ) {
                HStack(spacing: theme.spacing.sm) {
                    TextField(
                        "pinentry binary override",
                        text: bindingForOptional(\.pinentryBinaryOverride)
                    )
                    .textFieldStyle(.kizba)
                    pickerButton(allowsDirectories: false, helpText: "Browse for pinentry binary") { url in
                        model.pinentryBinaryOverride = url.path
                    }
                }
            }

            FormFieldRow(label: "Detection") {
                HStack(spacing: theme.spacing.sm) {
                    Button("Re-detect binaries") {
                        Task { await model.reDetectBinaries() }
                    }
                    .buttonStyle(.kizba(.secondary))
                    .disabled(model.isDetectingBinaries)
                    .help("Re-detect installed binaries (pass, gpg, pinentry)")

                    if model.isDetectingBinaries {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Spacer()
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
