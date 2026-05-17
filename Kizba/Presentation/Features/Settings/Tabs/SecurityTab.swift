//
//  SecurityTab.swift
//  Kizba
//
//  Security settings tab. MVP6 Phase D.2 — the Touch ID toggle now
//  branches on `SettingsModel.biometricAvailability`:
//
//   * `.available`: render an interactive `Toggle` whose binding routes
//     through `await model.requestToggleBiometric(_:)` so the disable
//     path can present (and respect) the OS biometric prompt.
//   * `.unavailable(reason)`: render a disabled informational row
//     explaining why the toggle is inert. The persisted setting itself
//     is NOT auto-flipped (see `.ai/decisions.md` — MVP6.D.1) so
//     re-enabling biometrics on the system restores the previous
//     intent on next launch.
//
//  Auth failures (cancel / unavailable / failed) surface inline through
//  the `FormFieldRow` `errorText:` channel. The Settings scene does not
//  receive the root `AppState.toastCenter`, so a toast surface is not
//  reachable from here — an inline error preserves the feedback
//  contract without crossing a fresh DI boundary just for this tab.
//

import SwiftUI

struct SecurityTab: View {

    @Bindable var model: SettingsModel

    @Environment(\.theme) private var theme

    /// Last user-visible biometric failure copy. Lives on the view as
    /// `@State` (not on the model) because it is purely transient UI
    /// feedback — never persisted, never observed elsewhere. Cleared
    /// on any successful toggle attempt or when biometric availability
    /// transitions back to `.available`.
    @State private var lastBiometricError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                touchIDSection
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var touchIDSection: some View {
        FormSection("Security") {
            switch model.biometricAvailability {
            case .available:
                availableRow
            case .unavailable(let reason):
                unavailableRow(reason: reason)
            }
        }
    }

    // MARK: - Rows

    private var availableRow: some View {
        // Custom binding so a user flip routes through the guarded
        // model API instead of mutating the persisted flag directly.
        // The `set` closure spawns a detached-from-binding Task because
        // SwiftUI Binding setters are synchronous; the model itself is
        // `@MainActor` so the awaited hop stays on the main thread.
        let binding = Binding<Bool>(
            get: { model.touchIDPerRevealEnabled },
            set: { newValue in
                Task { @MainActor in
                    let result = await model.requestToggleBiometric(newValue)
                    switch result {
                    case .success:
                        lastBiometricError = nil
                    case .failure(let error):
                        lastBiometricError = Self.humanReadable(error)
                    }
                }
            }
        )

        return FormFieldRow(
            label: "Require Touch ID for reveal",
            errorText: lastBiometricError,
            infoText: "Require Touch ID authentication for every secret reveal."
        ) {
            Toggle(isOn: binding) {
                Text("Require Touch ID for password reveal")
            }
            .labelsHidden()
        }
    }

    private func unavailableRow(reason: BiometricUnavailableReason) -> some View {
        FormFieldRow(
            label: "Require Touch ID for reveal",
            infoText: "Touch ID is not available on this Mac: \(Self.reasonText(reason))."
        ) {
            Text("Unavailable")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurfaceMuted)
        }
    }

    // MARK: - Pure helpers (testable contract)

    /// Map a domain `BiometricUnavailableReason` to a short, user-facing
    /// English phrase. Phrases stay lowercase so they read naturally
    /// when interpolated into a sentence (e.g. "not available on this
    /// Mac: no biometric hardware.").
    static func reasonText(_ reason: BiometricUnavailableReason) -> String {
        switch reason {
        case .notEnrolled: return "no enrolled fingerprints"
        case .hardwareUnavailable: return "no biometric hardware"
        case .passcodeNotSet: return "device passcode not set"
        case .userDisabled: return "disabled by the user"
        case .unknown: return "biometrics unavailable"
        }
    }

    /// Map a `BiometricFailureReason` (raised inside
    /// `ToggleBiometricError.failed`) to a short English phrase.
    static func failureText(_ reason: BiometricFailureReason) -> String {
        switch reason {
        case .userFailed: return "authentication failed"
        case .systemCancel: return "cancelled by the system"
        case .appCancel: return "cancelled by the app"
        case .invalidContext: return "authentication context invalid"
        case .unknown: return "authentication failed"
        }
    }

    /// Compose a single line of feedback for a `ToggleBiometricError`,
    /// suitable for rendering through the `FormFieldRow.errorText`
    /// channel. Caller responsibility: pass through this helper rather
    /// than printing raw enum cases so the surfaced copy stays
    /// user-friendly.
    static func humanReadable(_ error: SettingsModel.ToggleBiometricError) -> String {
        switch error {
        case .unavailable(let reason):
            return "Touch ID change not applied: \(reasonText(reason))."
        case .cancelled:
            return "Touch ID change not applied: authentication cancelled."
        case .failed(let reason):
            return "Touch ID change not applied: \(failureText(reason))."
        }
    }
}
