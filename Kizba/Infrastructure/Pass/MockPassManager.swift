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

#if DEBUG

import Foundation

/// In-memory `PassManaging` double for previews, manual debug runs, and
/// unit tests of higher layers.
///
/// All state is captured at init time; the actor isolates concurrent
/// reads. Fixtures are deterministic — every call site sees the same
/// ordered list, the same secrets, and the same store URL.
///
/// Threading: `actor`-isolated. ``storeLocation()`` is `nonisolated`
/// because the URL is immutable after init.
public actor MockPassManager: PassManaging {

    private let entries: [PassEntry]
    private let secrets: [String: PassSecret]
    private let store: URL

    /// Designated initialiser.
    ///
    /// - Parameters:
    ///   - entries: Ordered list returned by ``listEntries()``.
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

    public func listEntries() async throws -> [PassEntry] {
        entries
    }

    public func show(_ entry: PassEntry) async throws -> PassSecret {
        guard let secret = secrets[entry.path] else {
            throw PassError.decryptionFailed(stderrExcerpt: "mock: no fixture for \(entry.path)")
        }
        return secret
    }

    public nonisolated func storeLocation() -> URL { store }
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
