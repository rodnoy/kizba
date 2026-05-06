//
//  PassManaging.swift
//  Kizba
//
//  Read-only domain surface over the `pass` password store. Per
//  `.ai/decisions.md`, MVP 1 deliberately exposes no write/git methods
//  so that accidental write paths cannot be wired in early.
//

import Foundation

/// Read-only access to a `pass`-style password store.
///
/// Implementations include the `MockPassManager` (debug fixtures) and
/// the production `PassCLI` (Phase 4) which composes
/// ``ShellCommandRunning`` with `PassShowParser` and `PassErrorMapper`.
///
/// ## Threading contract
///
/// All methods are `async` and may be invoked from any actor or task.
/// Implementations must be `Sendable` and must not assume MainActor
/// affinity. Long-running calls (notably ``show(_:)``) must honour
/// cooperative cancellation via `Task.checkCancellation()` /
/// `withTaskCancellationHandler`. Errors are surfaced as ``PassError``.
public protocol PassManaging: Sendable {

    /// Enumerate every entry in the store, sorted deterministically.
    ///
    /// - Throws: ``PassError/storeNotFound(path:)`` if the configured
    ///   store directory does not exist; ``PassError/shellFailure(_:_:)``
    ///   for unexpected I/O failures.
    func listEntries() async throws -> [PassEntry]

    /// Decrypt a single entry via `pass show`.
    ///
    /// - Parameter entry: The entry to decrypt.
    /// - Returns: The parsed ``PassSecret`` — held only by the calling
    ///   `EntryDetailModel` and released on selection change.
    /// - Throws: ``PassError`` mapped from the underlying shell / GPG
    ///   failure, or ``PassError/cancelled`` on cooperative cancellation.
    func show(_ entry: PassEntry) async throws -> PassSecret

    /// Absolute filesystem path of the active password store
    /// (typically `~/.password-store`, possibly overridden via
    /// ``SettingsStoring``).
    func storeLocation() -> URL
}
