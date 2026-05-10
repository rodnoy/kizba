//
//  LivePassManager.swift
//  Kizba
//
//  Phase 6.5 wiring: production conformance to ``PassManaging`` that
//  composes the read paths added in earlier phases.
//
//  Listing goes through ``PasswordStoreScanning`` (filesystem traversal
//  per `.ai/decisions.md`, "Listing via PasswordStoreScanner, not
//  pass ls"). Decryption goes through ``LivePassCLI`` (which lazily
//  resolves the `pass` binary via ``BinaryLocating`` and shells out to
//  `pass show <entry>`).
//
//  Phase E.6 wired the four user-facing write methods plus the
//  ``changes`` ``AsyncStream``:
//
//  - Each successful write invalidates the scanner's cache for the
//    active store root (so the next ``listEntries()`` re-walks the FS)
//    and THEN emits a single ``StoreChange`` event to every active
//    subscriber. The order matters — subscribers that re-list in
//    response to the event must observe the post-write state.
//  - ``insert`` and ``generate`` (without `--in-place`) consult
//    ``PasswordStoreScanning/contains(path:in:)`` BEFORE the write
//    so we can emit ``StoreChange/inserted`` vs
//    ``StoreChange/updated`` correctly. The extra existence probe
//    costs at most a single `FileManager.fileExists` call (cache hit
//    when the listing is warm; one syscall otherwise) — cheap and
//    worth the typed event payload for Phase H reconciliation.
//  - On failure no event is emitted — the failed write did not change
//    on-disk state.
//
//  ## Threading contract
//
//  `actor`. The store root is sourced via a `@Sendable` closure
//  (``storeRootProvider``) so live overrides from ``SettingsStoring``
//  are honoured per call without forcing the manager itself to be
//  rebuilt. ``storeLocation()`` reads the provider synchronously and
//  is therefore `nonisolated`. ``changes`` is `nonisolated` and
//  produces a fresh ``AsyncStream`` per subscriber; subscribers join
//  / leave under actor isolation so emissions are race-free.
//  `Sendable` is satisfied via the actor model.
//
//  ## Logging
//
//  No additional `os.Logger` calls are emitted here — the underlying
//  scanner and `PassCLI` already log shape-only metadata; doubling it
//  up at this layer would only add noise.
//

import Foundation

/// Production ``PassManaging`` implementation backed by
/// ``PasswordStoreScanning`` (listing) and ``LivePassCLI`` (decryption
/// + writes).
public actor LivePassManager: PassManaging {

    /// Filesystem scanner used by ``listEntries()`` and the
    /// pre-write `existedBefore` probe in ``insert`` / ``generate``.
    private let scanner: any PasswordStoreScanning

    /// Lazy `pass` CLI wrapper used by ``show(_:)`` and the four
    /// write methods.
    private let passCLI: LivePassCLI

    /// Live provider for the active password store root. Evaluated on
    /// every public method invocation so changes to
    /// ``SettingsKeys/storePathOverride`` take effect on the next
    /// operation without an app restart.
    private let storeRootProvider: @Sendable () -> URL
    
    /// Optional watcher injected for filesystem change notifications.
    private var storeWatcher: (any StoreWatching)?

    /// Task that drains `storeWatcher.events` and forwards them into
    /// the actor via `handleWatcherEvent()`.
    private var watcherDrainTask: Task<Void, Never>? = nil

    /// Per-subscriber continuations registered against ``changes``.
    /// The map survives across mutations for the lifetime of the
    /// manager. New subscribers join via ``changes`` (registration
    /// hops onto the actor) and leave automatically when the consuming
    /// task drops the iterator (`onTermination` hops back to the
    /// actor and removes the entry).
    private var continuations: [UUID: AsyncStream<StoreChange>.Continuation] = [:]

    /// Designated initialiser.
    ///
    /// - Parameters:
    ///   - scanner: Filesystem scanner. Production wires
    ///     ``PasswordStoreScanner``; tests inject a fake.
    ///   - passCLI: Lazy `pass` CLI wrapper. Production wires the
    ///     real ``LivePassCLI``; tests inject one over a fake shell.
    ///   - storeRootProvider: Live closure returning the active store
    ///     root. Use ``LivePassManager/defaultStoreRoot`` inside the
    ///     closure to fall back to `~/.password-store` when no
    ///     override is configured.
    public init(
        scanner: any PasswordStoreScanning,
        passCLI: LivePassCLI,
        storeRootProvider: @escaping @Sendable () -> URL,
        storeWatcher: (any StoreWatching)? = nil
    ) {
        self.scanner = scanner
        self.passCLI = passCLI
        self.storeRootProvider = storeRootProvider
        self.storeWatcher = storeWatcher
    }

    /// Convenience initialiser for tests/preview wiring that have a
    /// fixed store root.
    public init(
        scanner: any PasswordStoreScanning,
        passCLI: LivePassCLI,
        storeRoot: URL,
        storeWatcher: (any StoreWatching)? = nil
    ) {
        self.init(
            scanner: scanner,
            passCLI: passCLI,
            storeRootProvider: { storeRoot },
            storeWatcher: storeWatcher
        )
    }

    /// Handle a watcher event: invalidate scanner and emit `.bulk`.
    private func handleWatcherEvent() async {
        let root = storeRootProvider()
        await scanner.invalidate(storeRoot: root)
        emit(.bulk)
    }

    /// Standard `~/.password-store` location used when no override is
    /// available from settings.
    nonisolated public static var defaultStoreRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".password-store", isDirectory: true)
    }

    // MARK: - Read

    public func listEntries() async throws -> [PassEntry] {
        // Snapshot the store root once per public call so a single
        // operation is internally consistent even if the underlying
        // setting is mutated mid-flight.
        let root = storeRootProvider()
        let paths = try await scanner.listEntries(in: root)
        // Scanner already returns deterministically sorted paths;
        // preserve order. Each entry is identified by its path —
        // `PassEntry.id` is the path itself, so identity is stable
        // across refresh.
        //
        // Domain value-type initialisers are `MainActor`-isolated by
        // default under Swift 6's strict-concurrency mode, so the
        // mapping is performed via a MainActor hop.
        return await MainActor.run {
            paths.map { PassEntry(path: $0) }
        }
    }

    public func show(_ entry: PassEntry) async throws -> PassSecret {
        // Snapshot the store root for this call and forward it as
        // `PASSWORD_STORE_DIR` so `pass show` and the scanner agree on
        // which store to hit.
        let root = storeRootProvider()
        let result = try await passCLI.show(
            entryPath: entry.path,
            passwordStoreDirOverride: root
        )
        // Compose the domain value types on the MainActor — see the
        // note in ``listEntries()`` above. The decrypted body never
        // leaves this actor hop except as an opaque ``PassSecret``.
        return await MainActor.run {
            let fields = result.metadata.map { key, value in
                PassMetadata.Field(key: key, value: value)
            }
            let metadata = PassMetadata(fields: fields, notes: result.notes)
            return PassSecret(password: result.password, metadata: metadata)
        }
    }

    nonisolated public func storeLocation() -> URL {
        storeRootProvider()
    }

    // MARK: - Write

    public func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        let root = storeRootProvider()

        // Pre-flight existence probe so the post-write event carries
        // the right typed payload (`.inserted` vs `.updated`). One
        // extra `FileManager.fileExists` per write — cheap, and
        // critical for Phase H reconciliation.
        let existedBefore = await scanner.contains(path: entry.path, in: root)

        // Build the body bytes on the MainActor: under
        // strict-concurrency / default-isolation = MainActor, the pure
        // ``PassSecretSerializer/serialize(_:)`` is MainActor-isolated
        // (it touches MainActor-isolated value-type initialisers in
        // its inputs). The serialised String is then UTF-8 encoded
        // and passed verbatim to the CLI layer, which logs only
        // `stdinByteCount` — the body bytes never reach a logger.
        let body: Data = await MainActor.run {
            Data(PassSecretSerializer.serialize(secret).utf8)
        }

        try await passCLI.insert(
            path: entry.path,
            body: body,
            force: force,
            passwordStoreDirOverride: root
        )

        await scanner.invalidate(storeRoot: root)
        emit(existedBefore ? .updated(path: entry.path) : .inserted(path: entry.path))
        return entry
    }

    public func generate(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool,
        force: Bool
    ) async throws -> PassSecret {
        let root = storeRootProvider()
        let existedBefore = await scanner.contains(path: entry.path, in: root)

        let password = try await passCLI.generate(
            path: entry.path,
            length: length,
            noSymbols: !includeSymbols,
            force: force,
            passwordStoreDirOverride: root
        )

        // `pass generate` (commit-new variant) writes a body whose
        // sole content is the new password line. The matching domain
        // value type therefore carries empty metadata.
        let secret: PassSecret = await MainActor.run {
            PassSecret(
                password: password,
                metadata: PassMetadata(fields: [], notes: nil)
            )
        }

        await scanner.invalidate(storeRoot: root)
        emit(existedBefore ? .updated(path: entry.path) : .inserted(path: entry.path))
        return secret
    }

    public func generateInPlace(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool
    ) async throws -> PassSecret {
        let root = storeRootProvider()

        // `pass generate --in-place` requires the entry to exist;
        // otherwise the CLI errors out with "is not in the password
        // store" which `PassErrorMapper.map(...,commandContext:.generate)`
        // already maps appropriately. No `existedBefore` probe is
        // needed because the only legal post-state is `.updated`.
        let password = try await passCLI.generateInPlace(
            path: entry.path,
            length: length,
            noSymbols: !includeSymbols,
            passwordStoreDirOverride: root
        )

        // The metadata block is preserved atomically by `pass` itself
        // but the CLI does not surface it on stdout. We deliberately
        // do NOT issue a follow-up `pass show` here (that would
        // trigger a second pinentry prompt within the same user
        // gesture, defeating the UX of the "regenerate" affordance).
        // Subscribers that need the post-rotation metadata re-fetch
        // via ``show(_:)`` in response to the `.updated` event below.
        let secret: PassSecret = await MainActor.run {
            PassSecret(
                password: password,
                metadata: PassMetadata(fields: [], notes: nil)
            )
        }

        await scanner.invalidate(storeRoot: root)
        emit(.updated(path: entry.path))
        return secret
    }

    public func remove(_ entry: PassEntry) async throws {
        let root = storeRootProvider()

        try await passCLI.remove(
            path: entry.path,
            passwordStoreDirOverride: root
        )

        await scanner.invalidate(storeRoot: root)
        emit(.removed(path: entry.path))
    }

    public func move(from: PassEntry, to newPath: String, force: Bool) async throws -> PassEntry {
        let root = storeRootProvider()

        try await passCLI.move(
            from: from.path,
            to: newPath,
            force: force,
            passwordStoreDirOverride: root
        )

        await scanner.invalidate(storeRoot: root)
        emit(.moved(from: from.path, to: newPath))

        return await MainActor.run {
            PassEntry(path: newPath)
        }
    }

    // MARK: - Store-change stream

    /// Returns a fresh ``AsyncStream`` per call. Each stream receives
    /// every event emitted from the moment the subscriber joins until
    /// either the manager is deallocated or the consuming task drops
    /// the iterator (which fires `onTermination` and removes the
    /// continuation). Multi-subscriber semantics mirror
    /// ``MockPassManager``.
    public nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { continuation in
            // Registration must hop onto the actor to mutate
            // `continuations` race-free. A weak self is enough here:
            // the manager is reference-typed (an actor) and the
            // closure runs at most once per subscription.
            let id = UUID()
            Task { [weak self] in
                await self?.register(id: id, continuation: continuation)
            }
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.unregister(id: id)
                }
            }
        }
    }

    private func register(id: UUID, continuation: AsyncStream<StoreChange>.Continuation) async {
        // Add the continuation under actor isolation.
        continuations[id] = continuation

        // If this is the first subscriber, start the watcher lifecycle.
        if continuations.count == 1 {
            // Lazily instantiate a production watcher if none was injected.
            if storeWatcher == nil {
                storeWatcher = FSEventsStoreWatcher()
            }

            if let watcher = storeWatcher {
                // Start the watcher at the current store root.
                await watcher.start(at: storeRootProvider())

                // Capture the watcher strongly for the drain task so it
                // survives independently of actor state. Capture `self`
                // weakly to avoid retain cycles.
                let capturedWatcher = watcher
                watcherDrainTask = Task.detached { [weak self, capturedWatcher] in
                    // Drain watcher events and forward them back to the actor.
                    for await _ in capturedWatcher.events {
                        // If the task is cancelled, stop draining.
                        if Task.isCancelled { break }
                        await self?.handleWatcherEvent()
                    }
                }
            }
        }
    }

    private func unregister(id: UUID) async {
        continuations.removeValue(forKey: id)

        // If no subscribers remain, stop and tear down the watcher so
        // it can be lazily restarted later.
        if continuations.isEmpty {
            if let watcher = storeWatcher {
                // Cancel the drain task first so it stops iterating.
                watcherDrainTask?.cancel()
                watcherDrainTask = nil
                await watcher.stop()
                storeWatcher = nil
            }
        }
    }

    /// Fan-out one ``StoreChange`` to every active subscriber. Called
    /// only from the actor's mutation methods (after the matching
    /// scanner invalidation) so subscribers that re-list in response
    /// to the event observe the post-write state.
    private func emit(_ change: StoreChange) {
        for cont in continuations.values {
            cont.yield(change)
        }
    }
}
