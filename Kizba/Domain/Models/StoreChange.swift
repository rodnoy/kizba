//
//  StoreChange.swift
//  Kizba
//
//  Domain event emitted by `LivePassManager` after every successful
//  write to the password store. Consumed via
//  `PassManaging.changes` (Phase E.5) by the list and detail models
//  for cache invalidation and selection reconciliation (Phase H).
//
//  Foundation only — no UI, no infrastructure imports.
//

import Foundation

/// A single change applied to the password store.
///
/// Emitted exactly once per successful write op by `LivePassManager`.
/// Subscribers should treat it as a hint to invalidate / re-list / move
/// selection — the underlying filesystem is the source of truth.
///
/// `StoreChange` is intentionally **UI-origin neutral**: a `.inserted`
/// from "create new entry" is indistinguishable from a `.inserted`
/// produced by an edit (decrypt-edit-reinsert with `force: true`).
/// Disambiguation is done imperatively by `EntryFormModel` setting
/// `selectedEntryID` after success — see `.ai/decisions.md` MVP 2 §
/// "Cache invalidation".
public enum StoreChange: Sendable, Equatable, Hashable {

    /// A new entry was added at `path`.
    case inserted(path: String)

    /// An existing entry's body was rewritten in-place (`pass insert -f`
    /// against an existing path, or `pass generate --in-place`).
    case updated(path: String)

    /// An entry was removed from the store.
    case removed(path: String)

    /// An entry was renamed / relocated. `from` is the prior path, `to`
    /// the new one.
    case moved(from: String, to: String)

    /// A coarse "everything changed" signal — subscribers should re-list
    /// and reconcile selection if it survives. Reserved for cases like
    /// external store reload or reconfiguration.
    case bulk
}
