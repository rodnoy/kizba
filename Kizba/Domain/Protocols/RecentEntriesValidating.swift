//
//  RecentEntriesValidating.swift
//  Kizba
//
//  Filters recently-used entry paths to those that physically exist in
//  the user's password store. Injected into `RecentsModel.load()` so
//  that any path persisted in `UserDefaults` (whether by a legacy
//  schema, a stray DEBUG/preview build, or a future regression) but no
//  longer present in `~/.password-store/` is silently dropped from the
//  sidebar.
//
//  This was introduced as MVP6.H.2, the symptomatic-but-permanent fix
//  for the fixture-paths-in-Recents leak that survived the H.1 schema
//  bump (see `.ai/handoff.md`).
//

import Foundation

/// Filters recently-used paths to those that physically exist in the
/// user's password store.
///
/// `RecentsModel.load()` consults a validator after reading from its
/// ``RecentEntriesStoring`` so the UI never surfaces a path the user
/// cannot actually open. Implementations must preserve input order so
/// the newest-first invariant of the recents list is not disturbed.
///
/// ## Graceful degradation
///
/// Implementations that source their truth from a fallible backend
/// (e.g. a `pass` listing that may throw) MUST return the input array
/// unchanged on transient failure rather than wiping the user's
/// recents. A temporarily-unavailable store is preferable to a lost
/// list of recently-used paths.
public protocol RecentEntriesValidating: Sendable {

    /// Returns the subset of `paths` that exist as entries in the
    /// current store, preserving input order.
    ///
    /// - Parameter paths: Candidate recently-used paths, newest-first.
    /// - Returns: Stable filter of `paths`; entries not present in the
    ///   live store are dropped, all others retain their relative
    ///   position. On transient backend failure the implementation
    ///   returns `paths` unchanged.
    func validate(_ paths: [String]) async -> [String]
}
