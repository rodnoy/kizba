//
//  PassError.swift
//  Kizba
//
//  Domain error type produced by the `PassManaging` surface and its
//  collaborators. Cases mirror the user-facing error matrix declared in
//  `.ai/plan.md` (Phase 8.5). Associated values carry only **sanitised**
//  excerpts — never raw stdout, email addresses, or hex key IDs.
//

import Foundation

/// Errors surfaced by the domain pass-management layer.
///
/// All associated `String` payloads are expected to be pre-sanitised by
/// `PassErrorMapper` (Phase 4) before reaching this type. The UI maps
/// each case to a specific affordance:
///
/// - ``binaryNotFound``        — empty state + Settings nudge.
/// - ``pinentryNotConfigured`` — banner + help link.
/// - ``decryptionFailed``      — inline error + Diagnostics deep link.
/// - ``storeNotFound``         — onboarding screen.
/// - ``timedOut``              — toast + Diagnostics.
/// - ``shellFailure``          — toast + Diagnostics.
/// - ``parsingFailed``         — Diagnostics; treated as decrypt failure
///                                in the UI.
/// - ``cancelled``             — silent (selection change, etc.).
public enum PassError: Error, Hashable, Sendable {

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
}
