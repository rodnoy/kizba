//
//  GenericCSVImporter.swift
//  Kizba
//
//  Imports a generic CSV password export. Recognises the column
//  names produced by Chrome / Safari / Firefox / Brave password
//  managers and a smattering of generic password-store exporters.
//
//  Header row is required. Column matching is case-insensitive.
//  Required columns: `name` (alias `title`) and `password`. Optional:
//  `username`, `url` (alias `website`), `notes`, `totp` (alias
//  `otpauth`).
//

import Foundation

public struct GenericCSVImporter: Sendable {

    public init() {}

    /// - Parameters:
    ///   - text: Full CSV text (already decoded as UTF-8).
    ///   - existingPaths: Snapshot of the destination store paths,
    ///     used to compute the conflict list.
    /// - Throws: ``ImportError`` for missing required structure
    ///   (empty file, missing required columns).
    public func parse(text: String, existingPaths: Set<String>) throws -> ImportPreview {
        let rows = CSVRow.parseAll(text)
        guard let header = rows.first else {
            throw ImportError.emptyFile
        }

        let lowercaseHeader = header.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        guard let nameIdx = lowercaseHeader.firstIndex(where: { $0 == "name" || $0 == "title" }) else {
            throw ImportError.missingNameColumn
        }
        guard let passwordIdx = lowercaseHeader.firstIndex(of: "password") else {
            throw ImportError.missingPasswordColumn
        }
        let usernameIdx = lowercaseHeader.firstIndex(of: "username")
        let urlIdx = lowercaseHeader.firstIndex(where: { $0 == "url" || $0 == "website" })
        let notesIdx = lowercaseHeader.firstIndex(of: "notes")
        let totpIdx = lowercaseHeader.firstIndex(where: { $0 == "totp" || $0 == "otpauth" })

        var records: [ExportRecord] = []
        var warnings: [String] = []

        for (rowOffset, row) in rows.dropFirst().enumerated() {
            // Display row numbers are 1-based AND include the header row.
            let displayRow = rowOffset + 2
            guard row.count > max(nameIdx, passwordIdx) else {
                warnings.append("Skipped row \(displayRow) — too few columns.")
                continue
            }
            let name = row[nameIdx].trimmingCharacters(in: .whitespaces)
            let password = row[passwordIdx]
            guard !name.isEmpty else {
                warnings.append("Skipped row \(displayRow) — empty name.")
                continue
            }
            guard !password.isEmpty else {
                warnings.append("Skipped \"\(name)\" — empty password.")
                continue
            }

            let path = Self.sanitizePath(name)
            guard !path.isEmpty else {
                warnings.append("Skipped row \(displayRow) — name reduced to empty after sanitisation.")
                continue
            }

            records.append(ExportRecord(
                path: path,
                password: password,
                username: optionalField(row, usernameIdx),
                url: optionalField(row, urlIdx),
                notes: optionalField(row, notesIdx),
                totp: optionalField(row, totpIdx),
                extraFields: [:]
            ))
        }

        let conflicts = records.map(\.path).filter { existingPaths.contains($0) }
        return ImportPreview(records: records, conflicts: conflicts, parseWarnings: warnings)
    }

    // MARK: - Helpers

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

    /// Failures surfaced to the UI as inline error text in the Data
    /// tab. Recoverable: user can pick a different file.
    public enum ImportError: Error, Equatable {
        case emptyFile
        case missingNameColumn
        case missingPasswordColumn
    }
}
