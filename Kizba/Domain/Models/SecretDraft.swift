//
//  SecretDraft.swift
//  Kizba
//
//  Mutable, reference-typed working copy of a `PassSecret` used by the
//  Phase F entry-form models. Lives behind the `@MainActor` boundary
//  of `EntryFormModel`; deliberately NOT `Sendable`.
//
//  Security invariants (mirroring `PassSecret`):
//  - NOT `Codable` — never serialised to disk or defaults.
//  - NOT `CustomStringConvertible` — no `description` leak.
//  - NOT `CustomDebugStringConvertible` — no `debugDescription` leak.
//  - NOT `Sendable` — owned by a single `@MainActor` form model.
//

import Foundation
import Observation

/// In-progress, mutable representation of a `PassSecret`. The form
/// edits the draft's `password`, `metadata` and `notes` directly; on
/// save the model calls ``snapshot()`` to obtain an immutable
/// `PassSecret` value to hand to the CLI layer.
///
/// Reference semantics intentional: SwiftUI views bind to the same
/// instance the model owns, avoiding per-keystroke struct copies.
///
/// `@Observable` so SwiftUI tracks mutations of `password` /
/// `metadata` / `notes`. Without observation, proxy `Binding`s
/// reading `draft.<x>` would not invalidate the view on writes,
/// causing stale renders (e.g. typed text overwritten by the
/// previous binding read on the next forced re-render, or
/// "Add field" buttons appearing only on an unrelated redraw).
@Observable
public final class SecretDraft {

    public var password: String
    public var metadata: [MetadataPair]
    public var notes: String

    public init(
        password: String = "",
        metadata: [MetadataPair] = [],
        notes: String = ""
    ) {
        self.password = password
        self.metadata = metadata
        self.notes = notes
    }

    /// Builds a draft from an existing decrypted secret. Used by the
    /// edit flow after a `pass show` round-trip. Notes default to the
    /// empty string when the secret carries `nil`.
    public init(from secret: PassSecret) {
        self.password = secret.password
        self.metadata = secret.metadata.fields.map {
            MetadataPair(key: $0.key, value: $0.value)
        }
        self.notes = secret.metadata.notes ?? ""
    }

    /// Returns an immutable `PassSecret` value capturing the draft's
    /// current state. Subsequent mutations to the draft do not affect
    /// previously-returned snapshots — `PassSecret`/`PassMetadata` are
    /// value types and the `fields` array is copied on demand.
    public func snapshot() -> PassSecret {
        let fields = metadata.map { pair in
            PassMetadata.Field(key: pair.key, value: pair.value)
        }
        let notesValue: String? = notes.isEmpty ? nil : notes
        return PassSecret(
            password: password,
            metadata: PassMetadata(fields: fields, notes: notesValue)
        )
    }
}

// MARK: - Security
//
// Do NOT add `Codable`, `CustomStringConvertible`,
// `CustomDebugStringConvertible` or `Sendable` conformances to
// `SecretDraft`. The `password`, `metadata.value` and `notes`
// fields all hold cleartext secret material. String-conversion or
// serialisation conformances would route secrets into logs or
// defaults; `Sendable` would invite cross-actor sharing where the
// `@MainActor` form model assumes single-actor ownership.
