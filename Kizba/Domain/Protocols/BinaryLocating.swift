//
//  BinaryLocating.swift
//  Kizba
//
//  Domain abstraction for resolving absolute paths of external
//  binaries (`pass`, `gpg`, `pinentry-mac`). Production implementation
//  is `BinaryDiscoveryService` (Phase 5).
//

import Foundation

/// Names of the external binaries Kizba may need to locate.
public enum BinaryName: String, Sendable, Hashable, CaseIterable {

    /// The `pass` password-store CLI.
    case pass

    /// GnuPG, used transitively by `pass show`.
    case gpg

    /// `pinentry-mac`, the GUI passphrase prompter.
    case pinentryMac = "pinentry-mac"
}

/// Resolves the absolute filesystem path of an external binary.
///
/// ## Threading contract
///
/// `Sendable`. Implementations cache results and may be queried from
/// any actor. ``reDetect()`` invalidates the cache so that newly
/// installed binaries can be picked up without an app restart.
///
/// ## Resolution order (per `.ai/decisions.md`)
///
/// 1. Explicit user override from ``SettingsStoring``.
/// 2. `/opt/homebrew/bin` (Apple-silicon Homebrew).
/// 3. `/usr/local/bin` (Intel Homebrew / MacPorts).
/// 4. `/usr/bin`.
/// 5. Sanitised hard-coded PATH walk. Inherited launchd PATH is
///    explicitly **not** trusted.
public protocol BinaryLocating: Sendable {

    /// Resolve `binary` to an absolute path, or `nil` if no candidate
    /// exists on disk.
    func locate(_ binary: BinaryName) async -> URL?

    /// Drop any cached resolutions so the next ``locate(_:)`` call
    /// re-walks the search order.
    func reDetect() async
}
