//
//  BinaryDiscoveryService.swift
//  Kizba
//
//  Production conformance to `BinaryLocating` (Phase 5.1). Resolves
//  the absolute path of an external binary (`pass`, `gpg`,
//  `pinentry-mac`) by walking a deterministic, sanitised search order
//  and caches the result for subsequent lookups within the lifetime
//  of the actor.
//
//  ## Resolution order (per `.ai/decisions.md` & `BinaryLocating`)
//
//  1. Explicit override — `overridePaths[name]`, when supplied and
//     present on disk as an executable file.
//  2. Fixed well-known directories, in order:
//     `/opt/homebrew/bin` → `/usr/local/bin` → `/usr/bin`.
//  3. Sanitised PATH walk. PATH is read from the supplied
//     `pathOverride` if provided, otherwise from the parent
//     environment. Empty entries, duplicates, relative paths and any
//     entry containing `..` are dropped before the walk.
//  4. `nil` if nothing matched.
//
//  ## Concurrency contract
//
//  `actor`. The cache is internal actor state and therefore safe to
//  query from any context. `BinaryLocating` declares the protocol
//  itself `Sendable`; the actor satisfies that conformance trivially.
//
//  ## Logging discipline (per `.ai/decisions.md` & `Log.swift`)
//
//  - Logs only sanctioned metadata via `Log.discovery`:
//      * binary name (public — already a public enum case label),
//      * cache hit boolean (public),
//      * resolved path (`.private`).
//  - Never logs raw PATH strings, environment values or directory
//    contents.
//  - No raw stdout calls; no direct os.Logger instantiation
//    outside `Log.swift` (enforced by `SourceGrepTests`).
//

import Foundation
import os

// MARK: - FileExistenceChecking

/// Narrow file-system surface required by ``BinaryDiscoveryService``.
/// A protocol rather than a direct dependency on `FileManager` so
/// tests can inject a deterministic `FakeFileExistenceChecker`
/// without touching the real disk.
public protocol FileExistenceChecking: Sendable {

    /// Whether `path` denotes a file that the current process is
    /// allowed to execute. Production implementations should consult
    /// `FileManager.isExecutableFile(atPath:)`.
    ///
    /// `nonisolated` so that ``BinaryDiscoveryService`` (an actor)
    /// may call it without hopping to the main actor under the
    /// project-wide `default-isolation=MainActor` setting.
    nonisolated func isExecutableFile(atPath path: String) -> Bool
}

/// Default `FileExistenceChecking` backed by `FileManager.default`.
///
/// `FileManager.default` is documented as thread-safe for the read-
/// only operations we use, so this struct can be `Sendable`.
public struct DefaultFileExistenceChecker: FileExistenceChecking {

    public init() {}

    public nonisolated func isExecutableFile(atPath path: String) -> Bool {
        FileManager.default.isExecutableFile(atPath: path)
    }
}

// MARK: - BinaryDiscoveryService

/// Caching, actor-isolated implementation of ``BinaryLocating``.
public actor BinaryDiscoveryService: BinaryLocating {

    // MARK: Stored state

    /// Per-name explicit override **resolver**, evaluated lazily on
    /// every cache miss. A closure (rather than a frozen dictionary)
    /// lets the discovery service stay in sync with live changes from
    /// the Settings UI without forcing callers to re-construct the
    /// service. The closure is `@Sendable` so it can be invoked from
    /// the actor's isolation domain.
    private let overrideProvider: @Sendable () -> [BinaryName: URL]

    /// Optional PATH replacement. `nil` means "read PATH from the
    /// parent process environment at lookup time". An empty string
    /// is honoured verbatim (it sanitises down to an empty list).
    private let pathOverride: String?

    /// Reader used for `getenv("PATH")`. Hoisted onto the actor so
    /// tests can inject a deterministic snapshot of `ProcessInfo`.
    private let environmentReader: @Sendable () -> [String: String]

    /// File-system existence/executability check. Injected for
    /// determinism; defaults to ``DefaultFileExistenceChecker``.
    private let fileChecker: any FileExistenceChecking

    /// Resolved-path cache. The optional payload distinguishes
    /// "looked up and found nothing" (`Optional<URL>.none`) from
    /// "never looked up" (key absent).
    private var cache: [BinaryName: URL?] = [:]

    // MARK: Tunables

    /// Hard-coded preferred directories, walked in order. Apple-
    /// silicon Homebrew first, Intel Homebrew second, system third.
    nonisolated static let wellKnownDirectories: [String] = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/usr/bin",
    ]

    // MARK: Init

    /// Designated initialiser.
    ///
    /// - Parameters:
    ///   - overrideProvider: closure returning the current per-binary
    ///     overrides. Evaluated lazily on every cache miss so the
    ///     service can honour live edits made through Settings without
    ///     being reconstructed. Each URL is verified through
    ///     `fileChecker` before being returned. Defaults to "no
    ///     overrides".
    ///   - pathOverride: optional PATH value to use in lieu of the
    ///     parent environment's `PATH`. Pass `nil` in production.
    ///   - environmentReader: snapshot of the process environment.
    ///     Defaults to `ProcessInfo.processInfo.environment` evaluated
    ///     at each call.
    ///   - fileChecker: file-existence dependency. Defaults to
    ///     ``DefaultFileExistenceChecker``.
    public init(
        overrideProvider: @escaping @Sendable () -> [BinaryName: URL] = { [:] },
        pathOverride: String? = nil,
        environmentReader: @escaping @Sendable () -> [String: String] = {
            ProcessInfo.processInfo.environment
        },
        fileChecker: any FileExistenceChecking = DefaultFileExistenceChecker()
    ) {
        self.overrideProvider = overrideProvider
        self.pathOverride = pathOverride
        self.environmentReader = environmentReader
        self.fileChecker = fileChecker
    }

    // MARK: BinaryLocating

    public func locate(_ binary: BinaryName) async -> URL? {
        if let cached = cache[binary] {
            Log.discovery.debug(
                "locate cache hit name=\(binary.rawValue, privacy: .public) found=\(cached != nil, privacy: .public)"
            )
            return cached
        }

        let resolved = resolve(binary)
        cache[binary] = resolved

        if let resolved {
            Log.discovery.info(
                "locate resolved name=\(binary.rawValue, privacy: .public) path=\(resolved.path, privacy: .private)"
            )
        } else {
            Log.discovery.info(
                "locate miss name=\(binary.rawValue, privacy: .public)"
            )
        }
        return resolved
    }

    public func reDetect() async {
        cache.removeAll(keepingCapacity: true)
        Log.discovery.info("reDetect cache cleared")
    }

    // MARK: - Resolution

    /// Walk the discovery order for `binary` without consulting the
    /// cache. Pure with respect to actor state; `cache` is updated
    /// only by ``locate(_:)``.
    private func resolve(_ binary: BinaryName) -> URL? {
        let name = binary.rawValue

        // 1. Explicit override (resolved live each time the cache
        // misses — keeps the service in sync with Settings edits).
        let overrides = overrideProvider()
        if let override = overrides[binary] {
            if fileChecker.isExecutableFile(atPath: override.path) {
                return override
            }
            // An override that does not exist on disk is treated as
            // "user misconfiguration" — we deliberately do NOT fall
            // back to system locations, so the caller surfaces the
            // misconfiguration instead of silently using a different
            // binary. Per `.ai/decisions.md`: explicit > implicit.
            return nil
        }

        // 2. Well-known directories, in order.
        for dir in Self.wellKnownDirectories {
            if let url = candidate(in: dir, name: name) {
                return url
            }
        }

        // 3. Sanitised PATH walk.
        for dir in sanitisedPathDirectories() {
            if Self.wellKnownDirectories.contains(dir) {
                // Already probed in step 2 — do not re-stat.
                continue
            }
            if let url = candidate(in: dir, name: name) {
                return url
            }
        }

        // 4. Nothing matched.
        return nil
    }

    /// Build the candidate `<dir>/<name>` URL and return it iff the
    /// file checker considers it an executable file.
    private func candidate(in directory: String, name: String) -> URL? {
        let path = directory.hasSuffix("/")
            ? directory + name
            : directory + "/" + name
        guard fileChecker.isExecutableFile(atPath: path) else { return nil }
        return URL(fileURLWithPath: path)
    }

    /// Split, de-duplicate and sanitise the PATH source.
    ///
    /// Sanitisation rules:
    /// - Empty entries are dropped (POSIX treats them as "current
    ///   directory"; we never want that).
    /// - Relative paths (anything that does not start with `/`) are
    ///   dropped.
    /// - Any entry containing a `..` component is dropped (defence-
    ///   in-depth against path-traversal-style PATH injection).
    /// - Duplicate entries collapse to their first occurrence so the
    ///   returned order matches caller expectations.
    func sanitisedPathDirectories() -> [String] {
        let raw: String
        if let pathOverride {
            raw = pathOverride
        } else {
            raw = environmentReader()["PATH"] ?? ""
        }

        var seen = Set<String>()
        var out: [String] = []
        for entry in raw.split(separator: ":", omittingEmptySubsequences: false) {
            let s = String(entry)
            if s.isEmpty { continue }
            guard s.hasPrefix("/") else { continue }
            // Reject any `..` segment. Use path-component split so
            // that a directory legitimately named e.g. `..foo` is not
            // dropped.
            let components = s.split(separator: "/", omittingEmptySubsequences: true)
            if components.contains(where: { $0 == ".." }) { continue }
            if seen.insert(s).inserted {
                out.append(s)
            }
        }
        return out
    }
}
