//
//  MockPassManager.swift
//  Kizba
//
//  Debug-only in-memory implementation of `PassManaging`. Seeded with a
//  small, deterministic corpus of fixture entries so the SwiftUI vertical
//  slice (Phase 2.2 – 2.6) and previews can be exercised without touching
//  a real `pass`/`gpg`/`pinentry` toolchain.
//
//  Per `.ai/decisions.md` and Phase 9.1 of the plan, this type is gated
//  behind `#if DEBUG` so that release binaries contain neither the
//  fixture passwords nor the mock implementation.
//
//  Phase E.5 expanded the surface to cover the four MVP 2 write methods
//  (`insert`, `generate`, `remove`, `move`) and the ``changes``
//  ``AsyncStream`` so form / list models built in Phase F can be
//  exercised against the mock without touching `LivePassManager`.
//  Mutations are performed in-memory under the actor's isolation and
//  every successful write fans out the corresponding ``StoreChange``
//  to every active subscriber.
//

#if DEBUG

import Foundation

/// In-memory `PassManaging` double for previews, manual debug runs, and
/// unit tests of higher layers.
///
/// Threading: `actor`-isolated. ``storeLocation()`` is `nonisolated`
/// because the URL is immutable after init. ``changes`` is
/// `nonisolated` and creates a fresh stream per subscriber; subscribers
/// are tracked under actor isolation so emissions are race-free.
public actor MockPassManager: PassManaging {

    private var entries: [PassEntry]
    private var secrets: [String: PassSecret]
    private let store: URL

    /// Per-subscriber continuations. The set survives across mutations
    /// for the lifetime of the manager. New subscribers join via
    /// ``changes`` and leave automatically when the consuming task
    /// drops the iterator.
    private var continuations: [UUID: AsyncStream<StoreChange>.Continuation] = [:]

    /// Designated initialiser.
    ///
    /// - Parameters:
    ///   - entries: Ordered list returned by ``listEntries()``. Stored
    ///     mutably so write methods can extend / shrink the corpus.
    ///   - secrets: Map keyed by ``PassEntry/path``. Entries without a
    ///     matching secret will throw ``PassError/decryptionFailed(stderrExcerpt:)``
    ///     from ``show(_:)`` — this mirrors a real-world "missing key"
    ///     failure and lets tests cover that branch deterministically.
    ///   - storeLocation: Reported by ``storeLocation()``. Defaults to a
    ///     stable fake path under `/tmp` so previews render predictably.
    public init(
        entries: [PassEntry],
        secrets: [String: PassSecret],
        storeLocation: URL = URL(fileURLWithPath: "/tmp/kizba-mock-store")
    ) {
        self.entries = entries
        self.secrets = secrets
        self.store = storeLocation
    }

    // MARK: - Read

    public func listEntries() async throws -> [PassEntry] {
        // Preserve insertion order so the existing fixture-corpus
        // tests (which pin first / last entries) stay green. Newly
        // inserted entries land at the end; deleted entries vanish
        // from the array.
        return entries
    }

    public func show(_ entry: PassEntry) async throws -> PassSecret {
        guard let secret = secrets[entry.path] else {
            throw PassError.decryptionFailed(stderrExcerpt: "mock: no fixture for \(entry.path)")
        }
        return secret
    }

    public nonisolated func storeLocation() -> URL { store }

    // MARK: - Write

    public func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        let exists = secrets[entry.path] != nil
        if exists && !force {
            throw PassError.entryAlreadyExists(path: entry.path)
        }

        secrets[entry.path] = secret
        if !exists {
            entries.append(entry)
            emit(.inserted(path: entry.path))
        } else {
            emit(.updated(path: entry.path))
        }
        return entry
    }

    public func generate(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool,
        force: Bool
    ) async throws -> PassSecret {
        let exists = secrets[entry.path] != nil
        if exists && !force {
            throw PassError.entryAlreadyExists(path: entry.path)
        }

        // Deterministic, recognisable shape — preview/unit tests don't
        // care about actual entropy, and this avoids pulling in the
        // CSPRNG (or its statistical bias smoke tests) into mock
        // territory. Format mirrors `LivePasswordGenerator`'s charset
        // toggle in spirit but is not a real password.
        //
        // Domain value-type initialisers are MainActor-isolated under
        // strict concurrency, so the construction is performed via a
        // MainActor hop — same pattern as ``LivePassManager``.
        let fakePassword = "GEN_\(length)_\(includeSymbols ? "sym" : "nosym")"
        let secret: PassSecret = await MainActor.run {
            PassSecret(
                password: fakePassword,
                metadata: PassMetadata(fields: [], notes: nil)
            )
        }

        secrets[entry.path] = secret
        if !exists {
            entries.append(entry)
            emit(.inserted(path: entry.path))
        } else {
            emit(.updated(path: entry.path))
        }
        return secret
    }

    public func generateInPlace(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool
    ) async throws -> PassSecret {
        // The in-place variant requires the entry to already exist.
        // A missing entry mirrors the production CLI's "is not in the
        // password store" stderr → ``PassError/sourceNotFound(path:)``
        // mapping (see `PassErrorMapper`, command context `.generate`).
        guard let existing = secrets[entry.path] else {
            throw PassError.sourceNotFound(path: entry.path)
        }

        // Deterministic, recognisable shape — identical scheme to
        // ``generate(_:length:includeSymbols:force:)`` so test
        // assertions can pin both paths the same way. The metadata
        // block from the prior secret is preserved verbatim, mirroring
        // `pass generate --in-place`'s atomic metadata-preserving
        // behaviour.
        let fakePassword = "GEN_INPLACE_\(length)_\(includeSymbols ? "sym" : "nosym")"
        let updated: PassSecret = await MainActor.run {
            PassSecret(password: fakePassword, metadata: existing.metadata)
        }

        secrets[entry.path] = updated
        emit(.updated(path: entry.path))

        // Return the SAME shape as the live manager: new password +
        // empty metadata (callers re-fetch via ``show(_:)`` if they
        // need the surviving block; tests can also peek at the
        // mutated `secrets` dict directly).
        return await MainActor.run {
            PassSecret(
                password: fakePassword,
                metadata: PassMetadata(fields: [], notes: nil)
            )
        }
    }

    public func remove(_ entry: PassEntry) async throws {
        guard secrets[entry.path] != nil else {
            throw PassError.sourceNotFound(path: entry.path)
        }
        secrets.removeValue(forKey: entry.path)
        entries.removeAll(where: { $0.path == entry.path })
        emit(.removed(path: entry.path))
    }

    public func move(from: PassEntry, to newPath: String, force: Bool) async throws -> PassEntry {
        guard let value = secrets[from.path] else {
            throw PassError.sourceNotFound(path: from.path)
        }
        if secrets[newPath] != nil && !force {
            throw PassError.entryAlreadyExists(path: newPath)
        }

        secrets.removeValue(forKey: from.path)
        secrets[newPath] = value
        entries.removeAll(where: { $0.path == from.path || $0.path == newPath })
        let newEntry: PassEntry = await MainActor.run {
            PassEntry(path: newPath)
        }
        entries.append(newEntry)

        emit(.moved(from: from.path, to: newPath))
        return newEntry
    }

    // MARK: - Store-change stream

    /// Returns a fresh `AsyncStream<StoreChange>` per call. Each stream
    /// receives every event emitted from the moment the subscriber
    /// joins until either the manager is deallocated or the consuming
    /// task drops the iterator (which fires `onTermination` and
    /// removes the continuation).
    public nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { continuation in
            // The actor hop is required to mutate `continuations`
            // safely. Capturing `self` in a Task is fine — the manager
            // is reference-typed (an actor) and the closure is only
            // invoked once per subscription.
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

    private func register(id: UUID, continuation: AsyncStream<StoreChange>.Continuation) {
        continuations[id] = continuation
    }

    private func unregister(id: UUID) {
        continuations.removeValue(forKey: id)
    }

    /// Fan-out a single change to every active subscriber. Called only
    /// from the actor's mutation methods so ordering matches the order
    /// in which mutations land.
    private func emit(_ change: StoreChange) {
        for cont in continuations.values {
            cont.yield(change)
        }
    }
}

// MARK: - Deterministic fixture corpus

extension MockPassManager {

    /// 20-entry preview corpus, spread across three folders
    /// (`personal/`, `work/`, `archive/`). Fixture composition exercises:
    ///
    /// - Password-only entries (no metadata, no notes).
    /// - Entries with rich `PassMetadata` (multiple fields + notes).
    /// - One entry whose name contains special characters
    ///   (`personal/email/jane+filter@example.com`).
    /// - One entry with an empty path component (`personal/empty-name/`)
    ///   producing an empty `name` to cover that edge case in the UI.
    /// - Sequential `createdAt` timestamps spaced by exactly 60 seconds
    ///   from a fixed base date — surfaced via the `created` metadata
    ///   field on entries that have metadata.
    ///
    /// All UUIDs and timestamps are derived from fixed seeds so tests
    /// are stable across runs and hosts.
    public static let fixtures: (entries: [PassEntry], secrets: [String: PassSecret]) = {

        // Stable base date: 2026-01-01T00:00:00Z. Spacing: 60s per entry.
        let base = Date(timeIntervalSince1970: 1_767_225_600)
        let formatter: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()

        // Each tuple: (path, password, optional metadata fields, optional notes).
        // Index into the array also drives the `created` timestamp.
        let raw: [(String, String, [PassMetadata.Field], String?)] = [
            // personal/* — 7 entries, one with special chars, one empty-name.
            ("personal/email/gmail",
             "p4ss-personal-gmail",
             [.init(key: "user", value: "jane.doe@example.com"),
              .init(key: "url",  value: "https://mail.google.com")],
             "Recovery codes stored offline."),
            ("personal/email/jane+filter@example.com",
             "p4ss-special-chars-!@#$%^&*()",
             [.init(key: "user", value: "jane+filter@example.com")],
             nil),
            ("personal/bank/checking",
             "0000-1111-2222-3333",
             [.init(key: "user",  value: "jane.doe"),
              .init(key: "url",   value: "https://bank.example/login"),
              .init(key: "phone", value: "+1-555-0100")],
             "Last rotated 2025-12-01."),
            ("personal/wifi/home",
             "correct horse battery staple",
             [],
             nil),
            ("personal/wifi/guest",
             "guest-pass-2026",
             [],
             nil),
            ("personal/empty-name/",
             "edge-case-empty-leaf",
             [],
             "Entry whose last path component is empty — UI edge case."),
            ("personal/notes/diary",
             "diary-key",
             [],
             "Multi-line\nnotes block\nwith blank line\n\nincluded."),

            // work/* — 8 entries, mix of password-only and metadata-rich.
            ("work/aws/root",
             "aws-root-MFA-required",
             [.init(key: "user",     value: "root@example-org.aws"),
              .init(key: "url",      value: "https://signin.aws.amazon.com"),
              .init(key: "mfa",      value: "yubikey-5c-nfc")],
             "Break-glass account. Use only with two-person rule."),
            ("work/aws/ci",
             "aws-ci-deploy-key",
             [.init(key: "user", value: "ci-deployer"),
              .init(key: "url",  value: "https://signin.aws.amazon.com")],
             nil),
            ("work/github/personal-token",
             "ghp_FixtureTokenForPreviewsOnly0001",
             [.init(key: "user",   value: "jane-doe-work"),
              .init(key: "scopes", value: "repo, read:org")],
             nil),
            ("work/github/org-bot",
             "ghp_FixtureTokenForPreviewsOnly0002",
             [.init(key: "user", value: "example-org-bot")],
             nil),
            ("work/vpn/office",
             "vpn-office-shared",
             [],
             nil),
            ("work/jira/admin",
             "jira-admin-2026",
             [.init(key: "user", value: "jane.doe@example-org"),
              .init(key: "url",  value: "https://example-org.atlassian.net")],
             nil),
            ("work/db/postgres-prod",
             "pg-prod-DO-NOT-SHARE",
             [.init(key: "user", value: "kizba_admin"),
              .init(key: "host", value: "db-prod-1.internal:5432")],
             "Read-write. Audited."),
            ("work/db/postgres-readonly",
             "pg-readonly",
             [.init(key: "user", value: "kizba_reader"),
              .init(key: "host", value: "db-prod-ro.internal:5432")],
             nil),

            // archive/* — 5 entries, mostly password-only legacy.
            ("archive/old-laptop/login",
             "legacy-laptop-pw",
             [],
             nil),
            ("archive/old-laptop/disk-encryption",
             "legacy-fde-key-2019",
             [],
             "Retired hardware. Keep for forensic recovery only."),
            ("archive/services/forum",
             "forum-2018",
             [.init(key: "user", value: "jane_doe_2018")],
             nil),
            ("archive/services/newsletter",
             "newsletter-unsub-key",
             [],
             nil),
            ("archive/services/ftp",
             "ftp-legacy-pw",
             [.init(key: "user", value: "anonymous"),
              .init(key: "host", value: "ftp.example.test")],
             "Plain FTP. Do not reuse credentials."),
        ]

        var entries: [PassEntry] = []
        var secrets: [String: PassSecret] = [:]
        entries.reserveCapacity(raw.count)
        secrets.reserveCapacity(raw.count)

        for (index, row) in raw.enumerated() {
            let (path, password, fields, notes) = row
            entries.append(PassEntry(path: path))

            // Inject a deterministic `created` field on entries that
            // already carry metadata; leave password-only entries
            // entirely metadata-free to preserve that fixture variant.
            let timestamp = base.addingTimeInterval(TimeInterval(index * 60))
            let stampedFields: [PassMetadata.Field]
            if fields.isEmpty {
                stampedFields = []
            } else {
                stampedFields = fields + [
                    .init(key: "created", value: formatter.string(from: timestamp))
                ]
            }

            let metadata = PassMetadata(fields: stampedFields, notes: notes)
            secrets[path] = PassSecret(password: password, metadata: metadata)
        }

        return (entries, secrets)
    }()

    /// Convenience factory for SwiftUI previews and quick wiring in
    /// `AppEnvironment.preview()` (Phase 2.2).
    public static func preview() -> MockPassManager {
        let (entries, secrets) = fixtures
        return MockPassManager(entries: entries, secrets: secrets)
    }
}

#endif
