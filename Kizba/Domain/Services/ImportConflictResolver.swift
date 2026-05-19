//
//  ImportConflictResolver.swift
//  Kizba
//
//  Pure value-type resolver that decides how each incoming
//  ``ExportRecord`` should be applied to the store given the
//  user-selected ``ImportConflictStrategy`` and a snapshot of
//  existing paths.
//
//  Stateless w.r.t. the store: callers compute `existingPaths` ONCE
//  from `passManager.listEntries()` and feed the snapshot in. The
//  resolver does not mutate `existingPaths` between calls — when the
//  caller chooses `.rename` it must thread its own running set of
//  freshly-assigned renamed paths back through subsequent resolver
//  instances. (For MVP9.4 the import driver applies records
//  sequentially and rebuilds the resolver between batches when
//  needed; the rename suffix algorithm here only consults the
//  initial snapshot.)
//

import Foundation

/// User-selected strategy for resolving import paths that already
/// exist in the destination store.
public enum ImportConflictStrategy: String, Sendable, Equatable, CaseIterable {
    /// Keep the existing entry untouched; skip the incoming record.
    case skip
    /// Replace the existing entry's body with the incoming record.
    /// Maps to `passManager.insert(force: true)` at apply time.
    case overwrite
    /// Create the incoming record under a modified path
    /// (`name-2`, `name-3`, ...). Existing entry is preserved.
    case rename
}

/// Pure resolver: ``ExportRecord`` + strategy + path snapshot →
/// either a concrete ``ResolvedAction`` or `nil` (skip).
public struct ImportConflictResolver: Sendable {

    public let strategy: ImportConflictStrategy

    /// Snapshot of every existing path in the destination store,
    /// captured by the caller BEFORE the resolver runs. Not mutated
    /// by ``resolve(_:)`` — see the type-level note above.
    public let existingPaths: Set<String>

    public init(strategy: ImportConflictStrategy, existingPaths: Set<String>) {
        self.strategy = strategy
        self.existingPaths = existingPaths
    }

    /// Resolves a single incoming record against ``existingPaths``.
    ///
    /// - Returns: the action to apply, or `nil` when the record
    ///   should be skipped entirely (strategy `.skip` on a
    ///   conflicting path).
    public func resolve(_ record: ExportRecord) -> ResolvedAction? {
        guard existingPaths.contains(record.path) else {
            // No conflict — strategy is irrelevant.
            return .create(record)
        }
        switch strategy {
        case .skip:
            return nil
        case .overwrite:
            return .overwrite(record)
        case .rename:
            let newPath = renamedPath(for: record.path)
            let renamed = ExportRecord(
                path: newPath,
                password: record.password,
                username: record.username,
                url: record.url,
                notes: record.notes,
                totp: record.totp,
                extraFields: record.extraFields
            )
            return .create(renamed)
        }
    }

    /// Computes the next available `"<original>-<n>"` path, starting
    /// from `-2` (matches Finder / pass-cli convention). Skips suffix
    /// values that already exist in the snapshot.
    private func renamedPath(for original: String) -> String {
        var suffix = 2
        while existingPaths.contains("\(original)-\(suffix)") {
            suffix += 1
        }
        return "\(original)-\(suffix)"
    }

    /// Concrete write action chosen for a single incoming record.
    public enum ResolvedAction: Sendable, Equatable {
        /// `passManager.insert(force: false)` — record may be the
        /// original (no conflict) or a rename-suffixed copy.
        case create(ExportRecord)
        /// `passManager.insert(force: true)` — overwrite the
        /// existing entry at `record.path`.
        case overwrite(ExportRecord)
    }
}
