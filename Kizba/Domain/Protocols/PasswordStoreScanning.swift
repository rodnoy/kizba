//
//  PasswordStoreScanning.swift
//  Kizba
//
//  Domain protocol for password-store filesystem scanning. Listing
//  via filesystem traversal is the sanctioned strategy per
//  `.ai/decisions.md` ("Listing via PasswordStoreScanner, not pass ls").
//

import Foundation

/// Enumerates entries inside a `pass`-style password store by walking
/// the filesystem (not by spawning `pass ls`).
///
/// Implementations are expected to:
/// - ignore the `.git` directory and `.gpg-id` marker files,
/// - include only files whose final extension is `.gpg`
///   (case-insensitive),
/// - return entry paths relative to `storeRoot`, with the trailing
///   `.gpg` extension stripped, in a deterministic order.
///
/// ## Threading contract
///
/// All methods are `async`-friendly and may be invoked from any actor
/// or task. Conforming types must be `Sendable`. Implementations are
/// permitted (and encouraged) to be `actor`s so that the internal
/// cache can be mutated without external locking.
public protocol PasswordStoreScanning: Sendable {

    /// Enumerate every `.gpg` entry under `storeRoot`, returning a
    /// deterministically sorted list of relative entry paths (POSIX
    /// `/` separators, final `.gpg` extension stripped).
    ///
    /// - Parameter storeRoot: absolute file URL of the password store
    ///   root directory.
    /// - Throws: ``PassError/storeNotFound(path:)`` if `storeRoot`
    ///   does not exist or is not a directory.
    func listEntries(in storeRoot: URL) async throws -> [String]

    /// Cheap existence/type check for `storeRoot`. Returns `true` iff
    /// the URL points at an existing directory.
    func validateStoreRoot(_ storeRoot: URL) async -> Bool

    /// Drop any cached enumeration result for `storeRoot`. The next
    /// ``listEntries(in:)`` call will re-walk the filesystem.
    func invalidate(storeRoot: URL) async
}
