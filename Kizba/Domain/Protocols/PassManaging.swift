//
//  PassManaging.swift
//  Kizba
//
//  Domain surface over the `pass` password store. MVP 1 was read-only;
//  MVP 2 (Phase E.5) adds the four user-facing write methods and the
//  ``StoreChange`` event stream consumed by the list / detail models
//  for cache invalidation and selection reconciliation.
//

import Foundation

/// Read + write access to a `pass`-style password store.
///
/// Implementations include the `MockPassManager` (debug fixtures) and
/// the production `LivePassManager` (Phase E.6) which composes
/// ``ShellCommandRunning`` with `PassShowParser`, `PassErrorMapper`
/// and the ``PassCLI`` write methods.
///
/// ## Threading contract
///
/// All methods are `async` and may be invoked from any actor or task.
/// Implementations must be `Sendable` and must not assume MainActor
/// affinity. Long-running calls (notably ``show(_:)``) must honour
/// cooperative cancellation via `Task.checkCancellation()` /
/// `withTaskCancellationHandler`. Errors are surfaced as ``PassError``.
///
/// ## Write surface (MVP 2)
///
/// - ``insert(_:secret:force:)``  — create or overwrite an entry.
/// - ``generate(_:length:includeSymbols:force:)`` — fresh password.
/// - ``remove(_:)`` — delete an entry.
/// - ``move(from:to:force:)`` — rename / relocate.
///
/// Each successful write emits one ``StoreChange`` on ``changes`` so
/// subscribers can invalidate caches and reconcile selection. The
/// stream is UI-origin neutral — see ``StoreChange`` for details.
public protocol PassManaging: Sendable {

    // MARK: - Read (MVP 1)

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

    // MARK: - Write (MVP 2)

    /// Create (or overwrite, when `force == true`) an entry at
    /// `entry.path` with the supplied ``PassSecret`` body.
    ///
    /// Composed under the hood as `pass insert -m [-f] <path>` with
    /// the body fed via stdin — never the two-prompt interactive
    /// form. The UI is expected to render an "Overwrite?" banner
    /// BEFORE setting `force` to `true`.
    ///
    /// - Parameters:
    ///   - entry: Target entry. Only `path` is consulted; existing
    ///     metadata is irrelevant — the secret payload is the source
    ///     of truth for the new body.
    ///   - secret: Cleartext body to encrypt and store.
    ///   - force: When `true`, silently overwrites an existing entry.
    /// - Returns: The (possibly newly-created) ``PassEntry`` for the
    ///   stored body.
    /// - Throws: ``PassError/entryAlreadyExists(path:)`` when `force`
    ///   is `false` and the path exists;
    ///   ``PassError/recipientNotFound(emailOrKeyId:)`` when `gpg`
    ///   cannot resolve a recipient from `.gpg-id`; other typed
    ///   ``PassError`` cases for shell / parser failures.
    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry

    /// Generate a fresh password (commit-new variant) at `entry.path`
    /// via `pass generate [-f] [-n] <path> <length>`.
    ///
    /// - Parameters:
    ///   - entry: Target entry.
    ///   - length: Requested password length.
    ///   - includeSymbols: When `false`, adds the `-n` flag so the
    ///     symbols class is omitted.
    ///   - force: When `true`, silently overwrites an existing entry.
    /// - Returns: The newly-generated ``PassSecret`` (password +
    ///   empty metadata).
    /// - Throws: ``PassError/invalidLength`` when `length` is
    ///   rejected; other typed ``PassError`` cases as above.
    func generate(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool,
        force: Bool
    ) async throws -> PassSecret

    /// Regenerate the password of an existing entry IN PLACE via
    /// `pass generate [-n] --in-place <path> <length>`.
    ///
    /// Unlike ``generate(_:length:includeSymbols:force:)`` (which
    /// composes a fresh body containing only the new password line
    /// and overwrites the entry, dropping any existing metadata /
    /// notes), the in-place variant rewrites only the password line
    /// and preserves the metadata block atomically. This is the
    /// "rotate the password" path consumed by the Detail toolbar
    /// 🎲 button (Phase G.3).
    ///
    /// There is no `force` flag — `pass` requires the entry to
    /// already exist. A missing entry surfaces as
    /// ``PassError/sourceNotFound(path:)``.
    ///
    /// - Parameters:
    ///   - entry: Target entry. Must already exist in the store.
    ///   - length: Requested password length.
    ///   - includeSymbols: When `false`, adds the `-n` flag so the
    ///     symbols class is omitted.
    /// - Returns: A ``PassSecret`` whose `password` is the freshly
    ///   generated value. **Metadata fields are returned EMPTY** —
    ///   the CLI does not surface the surviving metadata block,
    ///   and re-reading via ``show(_:)`` would trigger a second
    ///   pinentry prompt. Callers that need the post-rotation
    ///   metadata MUST re-fetch via ``show(_:)`` (typically the
    ///   detail view does this in response to the ``StoreChange``
    ///   event emitted by this method).
    /// - Throws: ``PassError/invalidLength`` when `length` is
    ///   rejected; ``PassError/sourceNotFound(path:)`` when `entry`
    ///   does not exist; other typed ``PassError`` cases as above.
    func generateInPlace(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool
    ) async throws -> PassSecret

    /// Remove an entry via `pass rm -f <path>`. Always uses `-f` so
    /// `pass` does not prompt for confirmation; the UI is expected to
    /// render the two-step destructive confirmation BEFORE invoking
    /// this method.
    ///
    /// - Parameter entry: Entry to delete.
    /// - Throws: ``PassError/sourceNotFound(path:)`` when the entry
    ///   does not exist (listing was stale); other typed
    ///   ``PassError`` cases as above.
    func remove(_ entry: PassEntry) async throws

    /// Move / rename an entry via `pass mv [-f] <from> <to>`.
    ///
    /// - Parameters:
    ///   - from: Source entry.
    ///   - newPath: Destination pass entry path.
    ///   - force: When `true`, silently overwrites an existing
    ///     destination.
    /// - Returns: The ``PassEntry`` describing the new location.
    /// - Throws: ``PassError/sourceNotFound(path:)`` when `from`
    ///   does not exist; ``PassError/entryAlreadyExists(path:)``
    ///   when the destination exists and `force` is `false`.
    func move(from: PassEntry, to newPath: String, force: Bool) async throws -> PassEntry

    // MARK: - Store-change stream (MVP 2)

    /// Stream of ``StoreChange`` events emitted after every successful
    /// write. Each call MUST return a fresh, independent stream so
    /// multiple subscribers can observe the same events; the actual
    /// emission is wired in `LivePassManager` (Phase E.6) and in
    /// `MockPassManager` (this file's preview / test wiring).
    ///
    /// The stream is UI-origin neutral: a `.inserted` from "create
    /// new" is indistinguishable from a `.inserted` produced by an
    /// edit. Disambiguation is done imperatively by the form layer.
    var changes: AsyncStream<StoreChange> { get }
}
