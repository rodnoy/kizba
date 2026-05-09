//
//  UndoableAction.swift
//  Kizba
//
//  Phase G.1 — value type describing a single reversible destructive
//  write recorded by ``ActionHistory``. Each case carries the data
//  needed to perform its inverse via ``PassManaging``:
//
//  - ``delete(path:secret:)``        → re-insert with `force: true`.
//  - ``move(from:to:)``               → move back from `to` to `from`.
//  - ``inPlaceGenerate(path:previousSecret:)``
//                                     → re-insert the prior secret with
//                                       `force: true`.
//
//  Security
//  --------
//
//  ``delete`` and ``inPlaceGenerate`` carry a ``PassSecret`` payload
//  (which holds the cleartext password). The value lives ONLY in the
//  in-memory ``ActionHistory`` window (default 10 seconds) and is
//  cleared when the app quits or when the window expires. It is
//  never persisted, never serialised, and never logged.
//
//  ``UndoableAction`` inherits the same security non-conformances as
//  ``PassSecret``:
//
//  - NOT ``Codable``                 (no on-disk serialisation).
//  - NOT ``CustomStringConvertible`` (no `description` / leak via
//                                     `"\(action)"` interpolation).
//  - NOT ``CustomDebugStringConvertible``.
//  - NOT ``Equatable`` / ``Hashable`` (would force comparing
//                                     ``PassSecret`` payloads).
//
//  Run-time non-conformance is enforced by ``UndoableActionTests``.
//

import Foundation

/// A reversible destructive write that ``ActionHistory`` can undo
/// within its expiry window. Carries the minimum payload needed to
/// execute the inverse via ``PassManaging``.
public enum UndoableAction: Sendable {

    /// User deleted the entry at `path`. Inverse: re-insert the
    /// captured ``PassSecret`` body with `force: true`.
    case delete(path: String, secret: PassSecret)

    /// User moved an entry from `from` to `to`. Inverse: move the
    /// entry back from `to` to `from` (no force needed — `from` was
    /// just emptied by the original move; if a third party has
    /// re-occupied it the inverse will surface the collision).
    case move(from: String, to: String)

    /// User regenerated the password in-place at `path`. The
    /// `previousSecret` carries the body BEFORE the regeneration —
    /// the inverse re-inserts it with `force: true`, restoring the
    /// prior password and metadata.
    case inPlaceGenerate(path: String, previousSecret: PassSecret)
}
