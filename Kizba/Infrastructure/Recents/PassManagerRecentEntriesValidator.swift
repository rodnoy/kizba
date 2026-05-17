//
//  PassManagerRecentEntriesValidator.swift
//  Kizba
//
//  Live `RecentEntriesValidating` backed by `PassManaging.listEntries()`.
//  A path is valid iff a `PassEntry` with the same `path` exists in the
//  current store listing. On any listing error the validator returns
//  the input unchanged so a transient store failure does not wipe the
//  user's recently-used list (see `RecentEntriesValidating` doc).
//

import Foundation

/// Validates recent entry paths against the live
/// ``PassManaging/listEntries()`` set.
///
/// Wired in `AppEnvironment.live()` against the real ``LivePassManager``
/// and consumed by ``RecentsModel/load()``. The validator is an actor
/// so its (cheap) snapshot work runs off the main actor.
public actor PassManagerRecentEntriesValidator: RecentEntriesValidating {

    private let passManager: any PassManaging

    public init(passManager: any PassManaging) {
        self.passManager = passManager
    }

    public func validate(_ paths: [String]) async -> [String] {
        // Snapshot the current entry list; any throw degrades
        // gracefully to "keep the user's recents intact" — see the
        // `RecentEntriesValidating` doc for the rationale.
        guard let entries = try? await passManager.listEntries() else {
            return paths
        }
        let validPaths = Set(entries.map(\.path))
        return paths.filter { validPaths.contains($0) }
    }
}
