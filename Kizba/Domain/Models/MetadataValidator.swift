//
//  MetadataValidator.swift
//  Kizba
//
//  Pure validator for the `[MetadataPair]` list edited in the entry
//  form. Enforces the structural constraints required for a clean
//  `pass` body round-trip; values are intentionally unvalidated
//  because the body format permits any character in the value
//  position (including colons and newlines for notes-style entries).
//

import Foundation

/// Validates a list of editor-side metadata pairs.
public enum MetadataValidator {

    /// Reasons a pair list may be rejected. The associated `Int` is
    /// the index of the offending pair within the input array, so
    /// the form can scroll to and highlight the row.
    public enum ValidationError: Error, Equatable, Sendable {
        case emptyKey(at: Int)
        case keyContainsColon(at: Int)
        case keyContainsNewline(at: Int)
        case duplicateKey(at: Int, conflictsWithIndexAt: Int)
    }

    /// Returns the original list on success, or the first violation
    /// encountered when iterating in order. "First" is defined by the
    /// pair index — the lowest-indexed pair that fails any rule
    /// produces the returned error.
    public static func validate(
        _ pairs: [MetadataPair]
    ) -> Result<[MetadataPair], ValidationError> {
        // First-seen index per key (case-sensitive). Populated as we
        // iterate so the duplicate error always points back to the
        // earliest occurrence.
        var firstIndexByKey: [String: Int] = [:]

        for (index, pair) in pairs.enumerated() {
            if pair.key.isEmpty {
                return .failure(.emptyKey(at: index))
            }
            if pair.key.contains(":") {
                return .failure(.keyContainsColon(at: index))
            }
            if pair.key.contains("\n") {
                return .failure(.keyContainsNewline(at: index))
            }
            if let priorIndex = firstIndexByKey[pair.key] {
                return .failure(.duplicateKey(at: index, conflictsWithIndexAt: priorIndex))
            }
            firstIndexByKey[pair.key] = index
        }

        return .success(pairs)
    }
}
