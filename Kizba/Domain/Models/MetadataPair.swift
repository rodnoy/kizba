//
//  MetadataPair.swift
//  Kizba
//
//  Mutable, identifiable key/value pair used by `SecretDraft` and the
//  Phase F entry-form editor. A `MetadataPair` is the editor-side
//  counterpart to `PassMetadata.Field`: it carries an extra `id` so
//  SwiftUI `ForEach` rows remain stable across mutations.
//
//  Security invariants (mirroring `PassSecret` — values may carry
//  sensitive data):
//  - NOT `Codable` — never serialised to disk or defaults.
//  - NOT `CustomStringConvertible` — no `description` leak.
//  - NOT `CustomDebugStringConvertible` — no `debugDescription` leak.
//

import Foundation

/// A single editable metadata entry: key + value, with a stable
/// identity for SwiftUI list diffing.
///
/// Treat the `value` as potentially sensitive — `pass` does not
/// distinguish secret from non-secret metadata, and users routinely
/// store API tokens or recovery codes alongside the password.
///
/// Equality is structural over `id + key + value` (synthesised).
public struct MetadataPair: Identifiable, Hashable, Sendable {

    public let id: UUID
    public var key: String
    public var value: String

    public init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

// MARK: - Security
//
// Do NOT add `Codable`, `CustomStringConvertible` or
// `CustomDebugStringConvertible` conformances to `MetadataPair`.
// The `value` field may carry secret material (tokens, recovery
// codes, secondary passwords) and any string-conversion or
// serialisation conformance would defeat the secret-handling
// discipline enforced for `PassSecret`.
