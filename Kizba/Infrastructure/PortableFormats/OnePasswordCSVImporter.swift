//
//  OnePasswordCSVImporter.swift
//  Kizba
//
//  Imports a 1Password "Common Fields" CSV export. Mirrors the
//  generic CSV importer but uses 1Password's specific column names:
//
//      Title, Website, Username, Password, Notes, ...
//
//  TOTP / one-time passwords are NOT included in the standard
//  Common Fields export (1Password emits them only via the
//  proprietary 1pux archive); the field is left `nil` here.
//

import Foundation

public struct OnePasswordCSVImporter: Sendable {

    public init() {}

    /// - Parameters:
    ///   - text: Full CSV text (already decoded as UTF-8).
    ///   - existingPaths: Snapshot of the destination store paths,
    ///     used to compute the conflict list.
    /// - Throws: Reuses ``GenericCSVImporter/ImportError`` so the UI
    ///   handles 1Password failures with the same error branch.
    public func parse(text: String, existingPaths: Set<String>) throws -> ImportPreview {
        let rows = CSVRow.parseAll(text)
        guard let header = rows.first else {
            throw GenericCSVImporter.ImportError.emptyFile
        }

        let lowercaseHeader = header.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        guard let titleIdx = lowercaseHeader.firstIndex(of: "title") else {
            throw GenericCSVImporter.ImportError.missingNameColumn
        }
        guard let passwordIdx = lowercaseHeader.firstIndex(of: "password") else {
            throw GenericCSVImporter.ImportError.missingPasswordColumn
        }
        let usernameIdx = lowercaseHeader.firstIndex(of: "username")
        let websiteIdx = lowercaseHeader.firstIndex(of: "website")
        let notesIdx = lowercaseHeader.firstIndex(of: "notes")

        var records: [ExportRecord] = []
        var warnings: [String] = []

        for (rowOffset, row) in rows.dropFirst().enumerated() {
            let displayRow = rowOffset + 2
            guard row.count > max(titleIdx, passwordIdx) else {
                warnings.append("Skipped row \(displayRow) — too few columns.")
                continue
            }
            let title = row[titleIdx].trimmingCharacters(in: .whitespaces)
            let password = row[passwordIdx]
            guard !title.isEmpty, !password.isEmpty else {
                warnings.append("Skipped row \(displayRow) — empty title or password.")
                continue
            }

            let path = Self.sanitizePath(title)
            guard !path.isEmpty else {
                warnings.append("Skipped row \(displayRow) — title reduced to empty after sanitisation.")
                continue
            }

            records.append(ExportRecord(
                path: path,
                password: password,
                username: optionalField(row, usernameIdx),
                url: optionalField(row, websiteIdx),
                notes: optionalField(row, notesIdx),
                totp: nil,
                extraFields: [:]
            ))
        }

        let conflicts = records.map(\.path).filter { existingPaths.contains($0) }
        return ImportPreview(records: records, conflicts: conflicts, parseWarnings: warnings)
    }

    private func optionalField(_ row: [String], _ index: Int?) -> String? {
        guard let index, row.indices.contains(index) else { return nil }
        let trimmed = row[index].trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func sanitizePath(_ path: String) -> String {
        path
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
