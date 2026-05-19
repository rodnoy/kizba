//
//  ImportPreview.swift
//  Kizba
//
//  Result of parsing an import file WITHOUT applying any writes to
//  the store. Lets the UI render a preview sheet with the per-path
//  conflict count + parse warnings so the user can pick a strategy
//  before any pass insert runs.
//
//  Pure value type — no async, no I/O, no store coupling. Importers
//  produce it; the UI consumes it; an `ImportConflictResolver`
//  derived from the chosen strategy executes against `records`.
//

import Foundation

/// Outcome of an importer's `parse(...)` call.
///
/// `conflicts` is the subset of `records` paths that already exist
/// in the destination store snapshot supplied by the caller. The
/// list is held verbatim (not transformed) so the UI can show a
/// preview such as "5 of 120 will overwrite an existing entry".
public struct ImportPreview: Sendable, Equatable {

    /// Every record successfully extracted from the source file.
    /// Records with empty password / malformed payload are filtered
    /// out at parse time and surfaced via ``parseWarnings`` instead.
    public let records: [ExportRecord]

    /// Subset of `records.map(\.path)` that collide with existing
    /// store entries. Counted via `conflictCount`; iterated for the
    /// preview list.
    public let conflicts: [String]

    /// Human-readable warnings collected during parsing — e.g.
    /// "Skipped row 7 — empty password". Rendered in the preview
    /// sheet so the user knows why the imported count is less than
    /// the row count.
    public let parseWarnings: [String]

    public init(records: [ExportRecord], conflicts: [String], parseWarnings: [String] = []) {
        self.records = records
        self.conflicts = conflicts
        self.parseWarnings = parseWarnings
    }

    /// Records that will land at a free path even under `.skip`.
    public var newCount: Int { records.count - conflicts.count }

    /// Records whose path already exists in the destination.
    public var conflictCount: Int { conflicts.count }

    /// Total parsed records (new + conflicts).
    public var totalCount: Int { records.count }
}
