//
// ErrorPresentation.swift
// Kizba
//
// Small helper mapping domain PassError cases to UI presentation
// descriptors. Kept intentionally minimal and pure for easy testing.
//

import Foundation

public struct SettingsNudge: Sendable {
    public let settingKey: String
    public let title: String
    public let actionTitle: String

    public init(settingKey: String, title: String, actionTitle: String) {
        self.settingKey = settingKey
        self.title = title
        self.actionTitle = actionTitle
    }
}

public enum ErrorPresentation: Sendable {

    case emptyState(nudge: SettingsNudge)
    case banner(message: String, helpURL: URL?)
    case inlineWithDiagnostics(message: String)
    case onboarding(message: String)
    case toastWithDiagnostics(message: String)
    case silent

    public static func present(for error: PassError) -> ErrorPresentation {
        switch error {
        case let .binaryNotFound(name):
            // Map known binary names to settings keys where users can
            // provide an override.
            let key: String
            switch name.lowercased() {
            case "pass": key = SettingsKeys.passBinaryOverride
            case "gpg": key = SettingsKeys.gpgBinaryOverride
            case "pinentry", "pinentry-mac": key = SettingsKeys.pinentryBinaryOverride
            default: key = SettingsKeys.storePathOverride
            }

            let nudge = SettingsNudge(
                settingKey: key,
                title: "Required tool not found: \(name)",
                actionTitle: "Open Settings"
            )
            return .emptyState(nudge: nudge)

        case .pinentryNotConfigured:
            // Provide a help link to installation/configuration docs.
            let url = URL(string: "https://www.passwordstore.org/")
            return .banner(message: "Pinentry is not configured. You must install/configure a pinentry program to decrypt entries.", helpURL: url)

        case let .decryptionFailed(stderrExcerpt):
            return .inlineWithDiagnostics(message: stderrExcerpt)

        case let .storeNotFound(path):
            return .onboarding(message: "Password store not found at \(path). Configure a store path to continue.")

        case .timedOut:
            return .toastWithDiagnostics(message: "Operation timed out")

        case let .shellFailure(_, stderrExcerpt):
            return .toastWithDiagnostics(message: stderrExcerpt)

        case let .parsingFailed(reason):
            // Treat parsing failures like decryption failures in the UI —
            // surface diagnostics to help debugging.
            return .inlineWithDiagnostics(message: reason)

        case .cancelled:
            return .silent

        // MARK: Write-side (Phase D.6)

        case .entryAlreadyExists:
            // Form-level concern: `EntryFormModel` reads
            // `error.inlineRecoverable` directly and renders an inline
            // `BannerView` with an "Overwrite" action. No top-level
            // presentation is needed — keep it `.silent` so the global
            // toast/banner surface stays out of the way of the form.
            return .silent

        case let .recipientNotFound(emailOrKeyId):
            return .banner(
                message: "GPG cannot find a public key for recipient \(emailOrKeyId).",
                helpURL: nil
            )

        case .invalidGpgId:
            return .onboarding(
                message: "Password store is not initialised — run `pass init <gpg-id>` to set a recipient."
            )

        case let .sourceNotFound(path):
            return .toastWithDiagnostics(
                message: "Entry no longer exists: \(path)"
            )

        case let .writeFailed(reason):
            return .toastWithDiagnostics(
                message: "Could not save: \(reason ?? "unknown error")"
            )

        case .invalidLength:
            // Form-level inline validation should reject invalid lengths
            // before the request leaves the UI. If one slips through,
            // staying silent at the global surface is preferable to a
            // confusing toast — the form will keep its own inline error.
            return .silent
        }
    }
}
