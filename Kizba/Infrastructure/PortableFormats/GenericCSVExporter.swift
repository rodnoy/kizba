//
//  GenericCSVExporter.swift
//  Kizba
//
//  Serialises ``ExportRecord``s into a generic, lowest-common-
//  denominator CSV that any password manager (and the matching
//  ``GenericCSVImporter``) can re-read.
//
//  Header row uses the lowercase generic-importer names — `name`
//  (not `title`), `url` (not `website`), `totp` (not `otpauth`) —
//  so a round trip through this exporter + importer is loss-free.
//

import Foundation

public struct GenericCSVExporter: Sendable {

    public init() {}

    /// - Returns: CSV text with trailing newline. Always UTF-8 when
    ///   the caller writes it to disk.
    public func export(records: [ExportRecord]) -> String {
        var lines: [String] = []
        lines.append(CSVRow.serialize(["name", "url", "username", "password", "notes", "totp"]))

        for record in records {
            lines.append(CSVRow.serialize([
                record.path,
                record.url ?? "",
                record.username ?? "",
                record.password,
                record.notes ?? "",
                record.totp ?? "",
            ]))
        }

        return lines.joined(separator: "\n") + "\n"
    }
}
