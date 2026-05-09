//
//  PasswordStoreScanner.swift
//  Kizba
//
//  Filesystem-based implementation of ``PasswordStoreScanning``.
//
//  Per `.ai/decisions.md`, listing is performed by traversing the
//  password store directly with `FileManager.enumerator` rather than
//  by parsing `pass ls` output (which is locale-/format-dependent).
//
//  ## Logging discipline
//
//  Entry paths and store locations are themselves potentially
//  sensitive — never log them with `.public`. The scanner only emits
//  shape-only signals (result count, cache hit boolean) at `.public`,
//  and any path bytes are interpolated with `privacy: .private`.
//

import Foundation
import os

/// Concurrency-safe `FileManager`-backed scanner.
///
/// The scanner is an `actor` so that the in-memory cache can be
/// mutated without external locking. The actual filesystem walk runs
/// inside the actor — that is acceptable here because callers always
/// reach the scanner via `await` from a non-MainActor context (the
/// `PassCLI` listing path in Phase 6.5).
public actor PasswordStoreScanner: PasswordStoreScanning {

    // MARK: - Stored state

    nonisolated private let ignoredDirectoryNames: Set<String>

    /// Cache keyed by the standardised absolute path of the store
    /// root. We use `path` (a `String`) rather than `URL` because two
    /// `URL`s that resolve to the same on-disk location can compare
    /// non-equal (trailing slash, `file://` vs `file:///`, etc.).
    private var cache: [String: [String]] = [:]

    /// Hoisted `FileManager` accessor. `FileManager` is not
    /// `Sendable`, so it cannot cross the actor boundary as a stored
    /// property under strict concurrency. We deliberately use the
    /// process-wide default — the scanner does not need test-time
    /// FileManager substitution: tests exercise the real filesystem
    /// via per-test temporary directories.
    private var fileManager: FileManager { .default }

    // MARK: - Init

    /// - Parameter ignoreList: directory-component names to skip while
    ///   walking. Defaults to `[".git"]`. The `.gpg-id` marker file is
    ///   always ignored regardless of this list.
    public init(ignoreList: [String] = [".git"]) {
        self.ignoredDirectoryNames = Set(ignoreList)
    }

    // MARK: - PasswordStoreScanning

    public func listEntries(in storeRoot: URL) async throws -> [String] {
        let key = storeRoot.standardizedFileURL.path

        if let cached = cache[key] {
            Log.discovery.debug(
                "PasswordStoreScanner cache hit (count=\(cached.count, privacy: .public))"
            )
            return cached
        }

        guard validateStoreRoot(storeRoot) else {
            Log.discovery.error(
                "PasswordStoreScanner: store root missing at \(key, privacy: .private)"
            )
            throw PassError.storeNotFound(path: key)
        }

        let entries = try walk(storeRoot: storeRoot)
        cache[key] = entries

        Log.discovery.debug(
            "PasswordStoreScanner walked store (count=\(entries.count, privacy: .public))"
        )
        return entries
    }

    public func validateStoreRoot(_ storeRoot: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let path = storeRoot.standardizedFileURL.path
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return false
        }
        return isDirectory.boolValue
    }

    public func invalidate(storeRoot: URL) {
        let key = storeRoot.standardizedFileURL.path
        cache.removeValue(forKey: key)
    }

    public func contains(path: String, in storeRoot: URL) async -> Bool {
        // Fast path: when the cache is warm, a `Set` membership check
        // is faster than a `FileManager` syscall and avoids the cost
        // of a stat on a possibly-encrypted volume.
        let key = storeRoot.standardizedFileURL.path
        if let cached = cache[key] {
            return cached.contains(path)
        }
        // Fallback: O(1) `fileExists` probe on the resolved `.gpg`
        // URL. Used when the scanner has never been listed against
        // this store root (e.g. straight after process start) and on
        // any call that follows a cache invalidation.
        let url = storeRoot
            .standardizedFileURL
            .appendingPathComponent(path + ".gpg")
        return fileManager.fileExists(atPath: url.path)
    }

    // MARK: - Internals

    private func walk(storeRoot: URL) throws -> [String] {
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey]
        guard
            let enumerator = fileManager.enumerator(
                at: storeRoot.standardizedFileURL,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles],
                errorHandler: nil
            )
        else {
            // `enumerator(at:...)` returns nil only if the URL cannot
            // be enumerated at all — surface as storeNotFound so the
            // caller can fall back to onboarding UI.
            throw PassError.storeNotFound(path: storeRoot.path)
        }

        var collected: [String] = []

        while let next = enumerator.nextObject() as? URL {
            // Hard-skip `.git` (and any other configured directory
            // names) by descending check on the last component. We
            // use `skipDescendants()` so we don't pay for the subtree.
            let lastComponent = next.lastPathComponent
            if ignoredDirectoryNames.contains(lastComponent) {
                enumerator.skipDescendants()
                continue
            }

            // Defensive: also drop any URL whose path components
            // contain an ignored directory name. `skipsHiddenFiles`
            // already hides `.git`, but the option only checks the
            // hidden flag — explicit ignore-list keeps semantics
            // independent of the OS hidden-flag heuristics.
            if next.pathComponents.contains(where: ignoredDirectoryNames.contains) {
                continue
            }

            // Only regular files are candidate entries.
            let values = try? next.resourceValues(forKeys: Set(resourceKeys))
            guard values?.isRegularFile == true else { continue }

            // Skip the `.gpg-id` marker file regardless of location.
            if lastComponent == ".gpg-id" { continue }

            // Only `.gpg` files (case-insensitive on the extension).
            guard next.pathExtension.lowercased() == "gpg" else { continue }

            guard let entry = EntryPathConverter.entryPath(
                from: next,
                storeRoot: storeRoot
            ) else { continue }

            collected.append(entry)
        }

        // Deterministic sort. `localizedStandardCompare` produces a
        // human-friendly ordering that is stable across runs.
        collected.sort { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
        return collected
    }
}
