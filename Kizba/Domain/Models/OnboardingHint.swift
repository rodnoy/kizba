//
//  OnboardingHint.swift
//  Kizba
//
//  Supplementary onboarding affordance attached to selected
//  ``PassError`` cases — see ``PassError/onboardingHint``.
//
//  Extracted from `PassError.swift` (MVP4 fix-pack v1, Fix 9) per the
//  original A.3 plan: keep one type per file in `Domain/Models/`.
//

import Foundation

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

    /// The user's store appears to be a git repository or needs a remote
    /// configured. Prompt them to set up a remote or initialise git.
    case configureGitRemote

    /// Open a terminal at the store root so the user can resolve conflicts
    /// or run git commands manually.
    case openTerminalAtStore
}
