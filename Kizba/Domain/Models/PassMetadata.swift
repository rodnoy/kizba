//
//  PassMetadata.swift
//  Kizba
//
//  Domain value type representing the non-secret, parsed portion of a
//  `pass show` payload: ordered key/value metadata lines followed by an
//  optional free-form notes block.
//

import Foundation

/// Non-secret metadata extracted from a `pass` entry's decrypted body.
///
/// `pass show` typically returns:
///
///     <password>
///     key1: value1
///     key2: value2
///     <free-form notes...>
///
/// This type stores only the parsed metadata lines and the notes block.
/// The password itself is held separately in ``PassSecret`` and must not
/// be embedded here.
///
/// Threading: value type, trivially `Sendable`.
public struct PassMetadata: Hashable, Sendable, Codable {

    /// A single metadata line, preserving original order.
    ///
    /// The same `key` may appear multiple times — `pass` does not enforce
    /// uniqueness and we mirror that behaviour.
    public struct Field: Hashable, Sendable, Codable {
        public let key: String
        public let value: String

        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }

    /// Ordered metadata fields. May contain duplicate keys.
    public var fields: [Field]

    /// Free-form notes block, or `nil` when absent. Trailing newline is
    /// not normalised here — the parser is responsible for trimming.
    public var notes: String?

    public init(fields: [Field] = [], notes: String? = nil) {
        self.fields = fields
        self.notes = notes
    }

    /// Returns the first value for `key`, if any. Case-sensitive.
    public func firstValue(for key: String) -> String? {
        fields.first(where: { $0.key == key })?.value
    }
}
