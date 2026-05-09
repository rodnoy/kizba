//
//  PassError.swift
//  Kizba
//
//  Domain error type produced by the `PassManaging` surface and its
//  collaborators. Cases mirror the user-facing error matrix declared in
//  `.ai/plan.md` (Phase 8.5 — read; Phase D.6 — writes). Associated
//  values carry only **sanitised** excerpts — never raw stdout, email
//  addresses, or hex key IDs.
//

import Foundation

/// Errors surfaced by the domain pass-management layer.
///
/// All associated `String` payloads are expected to be pre-sanitised by
/// `PassErrorMapper` (Phase E.4) before reaching this type. The UI maps
/// each case to a specific affordance:
///
/// Read-side (MVP 1):
/// - ``binaryNotFound``        — empty state + Settings nudge.
/// - ``pinentryNotConfigured`` — banner + help link.
/// - ``decryptionFailed``      — inline error + Diagnostics deep link.
/// - ``storeNotFound``         — onboarding screen.
/// - ``timedOut``              — toast + Diagnostics.
/// - ``shellFailure``          — toast + Diagnostics.
/// - ``parsingFailed``         — Diagnostics; treated as decrypt failure
///                                in the UI.
/// - ``cancelled``             — silent (selection change, etc.).
///
/// Write-side (MVP 2 Phase D.6):
/// - ``entryAlreadyExists``    — inline banner in the form, recoverable
///                                via `force: true`.
/// - ``recipientNotFound``     — banner + onboarding hint
///                                (`.checkRecipients`).
/// - ``invalidGpgId``          — onboarding (store may not be init'd).
/// - ``sourceNotFound``        — toast + auto-refresh listing.
/// - ``writeFailed``           — toast + Diagnostics (catch-all).
/// - ``invalidLength``         — silent (form-level inline validation
///                                should catch this before it reaches
///                                here).
public enum PassError: Error, Hashable, Sendable {

    // MARK: - Read-side (MVP 1)

    /// `pass` (or another required binary) was not found on PATH and no
    /// override is configured. The associated string names the missing
    /// executable, e.g. `"pass"` or `"gpg"`.
    case binaryNotFound(String)

    /// `pinentry-mac` (or equivalent) is not installed / not configured.
    case pinentryNotConfigured

    /// `pass show` failed during GPG decryption. Excerpt is sanitised.
    case decryptionFailed(stderrExcerpt: String)

    /// The configured password store directory is missing or empty.
    case storeNotFound(path: String)

    /// The shell invocation exceeded its deadline.
    case timedOut

    /// Generic non-zero shell exit not covered by a more specific case.
    case shellFailure(exitCode: Int32, stderrExcerpt: String)

    /// `PassShowParser` could not interpret the decrypted body.
    case parsingFailed(reason: String)

    /// The work was cancelled cooperatively (e.g. user changed selection).
    case cancelled

    // MARK: - Write-side (MVP 2 Phase D.6)

    /// `pass insert` / `pass mv` refused because the destination path is
    /// already present in the store. Recoverable by retrying with
    /// `force: true`. The associated path is the existing entry path.
    case entryAlreadyExists(path: String)

    /// `gpg` could not encrypt because no public key was found for one
    /// of the recipients listed in `.gpg-id`. The associated value is a
    /// sanitised email or short key id.
    case recipientNotFound(emailOrKeyId: String)

    /// The store has no usable `.gpg-id` (missing, empty, or referencing
    /// an invalid recipient). Typically surfaces during initialisation
    /// or first write.
    case invalidGpgId

    /// A write op (`mv`, `rm`) targeted a path that no longer exists in
    /// the store — the listing is stale and the UI should reconcile.
    case sourceNotFound(path: String)

    /// Catch-all for write failures that do not match any more specific
    /// case. The `reason` is a sanitised excerpt suitable for diagnostics.
    case writeFailed(reason: String?)

    /// `pass generate` rejected the requested length (≤ 0 or larger than
    /// the configured `pass-length` cap).
    case invalidLength
}

// MARK: - Presentation hints (consumed by views & form models)

public extension PassError {

    /// `true` when the failure can be recovered in-place by the view
    /// retrying the same operation with `force: true`. Currently only
    /// ``entryAlreadyExists`` qualifies; form models render an inline
    /// `BannerView` with an "Overwrite" action when this is `true`.
    var inlineRecoverable: Bool {
        switch self {
        case .entryAlreadyExists:
            return true
        case .binaryNotFound, .pinentryNotConfigured, .decryptionFailed,
             .storeNotFound, .timedOut, .shellFailure, .parsingFailed,
             .cancelled, .recipientNotFound, .invalidGpgId,
             .sourceNotFound, .writeFailed, .invalidLength:
            return false
        }
    }

    /// Returns an onboarding hint when the failure suggests the user
    /// needs to configure something (a missing recipient, an
    /// uninitialised store). Drives the supplementary "Open Diagnostics"
    /// / "Set up store" affordance rendered next to the error banner.
    var onboardingHint: OnboardingHint? {
        switch self {
        case .recipientNotFound:
            return .checkRecipients
        case .invalidGpgId:
            return .initializeStore
        case .binaryNotFound, .pinentryNotConfigured, .decryptionFailed,
             .storeNotFound, .timedOut, .shellFailure, .parsingFailed,
             .cancelled, .entryAlreadyExists, .sourceNotFound,
             .writeFailed, .invalidLength:
            return nil
        }
    }

    /// `true` when the UI should auto-refresh the store listing because
    /// the failure proves the in-memory listing is stale (currently only
    /// ``sourceNotFound``: the entry vanished between `list` and the
    /// write op). Drives `EntryListModel` reconciliation.
    var autoRefreshes: Bool {
        switch self {
        case .sourceNotFound:
            return true
        case .binaryNotFound, .pinentryNotConfigured, .decryptionFailed,
             .storeNotFound, .timedOut, .shellFailure, .parsingFailed,
             .cancelled, .entryAlreadyExists, .recipientNotFound,
             .invalidGpgId, .writeFailed, .invalidLength:
            return false
        }
    }
}

/// Supplementary onboarding affordance attached to selected
/// ``PassError`` cases — see ``PassError/onboardingHint``.
public enum OnboardingHint: Sendable, Equatable, Hashable {

    /// `.gpg-id` lists a recipient `gpg` cannot resolve. Prompt the user
    /// to inspect Diagnostics and/or `.gpg-id` contents.
    case checkRecipients

    /// The store appears uninitialised (no usable `.gpg-id`). Prompt the
    /// user to run `pass init <gpg-id>` (or surface the equivalent
    /// in-app onboarding flow when it lands).
    case initializeStore
}
