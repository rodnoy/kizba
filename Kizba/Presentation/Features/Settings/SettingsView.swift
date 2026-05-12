//
//  SettingsView.swift
//  Kizba
//
//  SwiftUI view for the Settings page. Binds to a
//  `SettingsModel` instance and exposes controls for path/binary
//  overrides, clipboard delay, and binary re-detection.
//
//  Phase C.4 migrated this view to the design system: each `Section`
//  becomes a `FormSection`, each labeled control row a `FormFieldRow`,
//  text fields adopt `.kizba`, and primary/destructive actions use
//  `KizbaButtonStyle`. The vanilla `.alert` reset confirmation is
//  replaced by the shared `.destructiveConfirmation(...)` modifier.
//
//  Native SwiftUI controls without a theme hook (`Stepper`,
//  `ProgressView`, the Settings scene container itself) are left
//  system-rendered intentionally; they pick up the parent theme through
//  standard appearance proxies.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// Settings screen bound to a `SettingsModel`.
public struct SettingsView: View {

    @State private var model: SettingsModel
    @State private var showingResetConfirmation = false

    @Environment(\.theme) private var theme

    public init(model: SettingsModel) {
        _model = State(wrappedValue: model)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                generalSection
                binariesSection
                clipboardSection
                securitySection
                gitSection
                actionsSection
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 520)
        .destructiveConfirmation(
            isPresented: $showingResetConfirmation,
            title: "Reset to Defaults?",
            message: "This will clear all overrides and restore the clipboard delay to the default value.",
            confirmLabel: "Reset"
        ) {
            model.resetToDefaults()
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Text("Version \(AppInfo.version) (\(AppInfo.build))")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                Spacer()
            }
            .padding(.vertical, theme.spacing.sm)
        }
    }

    // MARK: - Sections

    private var generalSection: some View {
        FormSection("General") {
            FormFieldRow(
                label: "Store path override",
                helpText: "Absolute path to your password store. Leave empty for the default."
            ) {
                HStack(spacing: theme.spacing.sm) {
                    TextField(
                        "Password store path override",
                        text: bindingForOptional(\.storePathOverride)
                    )
                    .textFieldStyle(.kizba)
                    pickerButton(allowsDirectories: true) { url in
                        model.storePathOverride = url.path
                    }
                }
            }
        }
    }

    private var binariesSection: some View {
        FormSection("Binaries") {
            FormFieldRow(label: "pass") {
                HStack(spacing: theme.spacing.sm) {
                    TextField(
                        "pass binary override",
                        text: bindingForOptional(\.passBinaryOverride)
                    )
                    .textFieldStyle(.kizba)
                    pickerButton(allowsDirectories: false) { url in
                        model.passBinaryOverride = url.path
                    }
                }
            }

            FormFieldRow(label: "gpg") {
                HStack(spacing: theme.spacing.sm) {
                    TextField(
                        "gpg binary override",
                        text: bindingForOptional(\.gpgBinaryOverride)
                    )
                    .textFieldStyle(.kizba)
                    pickerButton(allowsDirectories: false) { url in
                        model.gpgBinaryOverride = url.path
                    }
                }
            }

            FormFieldRow(label: "pinentry") {
                HStack(spacing: theme.spacing.sm) {
                    TextField(
                        "pinentry binary override",
                        text: bindingForOptional(\.pinentryBinaryOverride)
                    )
                    .textFieldStyle(.kizba)
                    pickerButton(allowsDirectories: false) { url in
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

                    if model.isDetectingBinaries {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Spacer()
                }
            }
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

    private var securitySection: some View {
        FormSection("Security") {
            FormFieldRow(label: "Require Touch ID for reveal", helpText: "When enabled, revealing a password prompts for Touch ID / Face ID.") {
                Toggle(isOn: $model.touchIDPerRevealEnabled) {
                    Text("Require Touch ID for password reveal")
                }
            }
        }
    }

    private var gitSection: some View {
        FormSection("Git") {
            FormFieldRow(
                label: "Operation timeout",
                helpText: "Seconds before a git pull or push operation times out."
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

    private var actionsSection: some View {
        HStack(spacing: theme.spacing.md) {
            Spacer()
            Button("Reset to Defaults") {
                showingResetConfirmation = true
            }
            .buttonStyle(.kizba(.destructive))
            .keyboardShortcut(.cancelAction)

            Button("Save") {
                model.save()
            }
            .buttonStyle(.kizba(.primary))
            .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: - Helpers

    /// Create a binding for an Optional<String> stored on the model. When
    /// the field is empty it will map to nil in the model.
    private func bindingForOptional(_ keyPath: WritableKeyPath<SettingsModel, String?>) -> Binding<String> {
        Binding<String>(
            get: { model[keyPath: keyPath] ?? "" },
            set: { newValue in
                model[keyPath: keyPath] = newValue.isEmpty ? nil : newValue
            }
        )
    }

    /// Platform-aware picker button. On macOS shows an `NSOpenPanel` and
    /// passes the selected URL to the handler. On other platforms the
    /// button is hidden (fallback to manual entry via TextField).
    @ViewBuilder
    private func pickerButton(allowsDirectories: Bool, completion: @escaping (URL) -> Void) -> some View {
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
#else
        EmptyView()
#endif
    }
}

// MARK: - Previews
#if DEBUG

struct SettingsView_Previews: PreviewProvider {
    /// Lightweight stub that always returns `nil` — no real binary lookup
    /// needed for SwiftUI previews.
    private struct PreviewDiscovery: BinaryLocating {
        func locate(_ binary: BinaryName) async -> URL? { nil }
        func reDetect() async {}
    }

    static var previews: some View {
        let env = AppEnvironment.preview()
        let model = SettingsModel(settings: env.settings, discovery: PreviewDiscovery())
        SettingsView(model: model)
    }
}
#endif
