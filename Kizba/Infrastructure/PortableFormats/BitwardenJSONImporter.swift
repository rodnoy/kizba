//
//  BitwardenJSONImporter.swift
//  Kizba
//
//  Parses an unencrypted Bitwarden JSON export (the format produced
//  by Vault → Tools → Export Vault, "json" type) into a list of
//  ``ExportRecord`` values plus a per-store conflict snapshot.
//
//  Surface intentionally narrow: only login items (type=1) are
//  imported. Secure notes, cards, identities, and SSH keys are
//  silently dropped — they don't map onto a `pass`-style "path +
//  password + metadata" model.
//

import Foundation

/// Importer for unencrypted Bitwarden JSON exports.
public struct BitwardenJSONImporter: Sendable {

    public init() {}

    /// - Parameters:
    ///   - data: Raw bytes of the export file (UTF-8 JSON).
    ///   - existingPaths: Snapshot of the destination store paths,
    ///     used to compute the conflict list.
    /// - Returns: An ``ImportPreview`` summarising parsed records,
    ///   conflicts, and per-item warnings.
    /// - Throws: `DecodingError` if the bytes aren't valid Bitwarden
    ///   JSON; never throws on a syntactically valid but partially
    ///   incomplete payload (such items become parse warnings).
    public func parse(data: Data, existingPaths: Set<String>) throws -> ImportPreview {
        let root = try JSONDecoder().decode(BitwardenRoot.self, from: data)
        var records: [ExportRecord] = []
        var warnings: [String] = []

        // Bitwarden references folders by id; build a quick lookup.
        // The `folders` array may be absent (older exports) — defaulted
        // to empty by the DTO.
        let folderMap = Dictionary(uniqueKeysWithValues: root.folders.map { ($0.id, $0.name) })

        for item in root.items where item.type == 1 {
            guard let login = item.login else { continue }
            guard let password = login.password, !password.isEmpty else {
                warnings.append("Skipped \"\(item.name)\" — no password.")
                continue
            }

            let folderName = item.folderId.flatMap { folderMap[$0] } ?? ""
            let rawPath = folderName.isEmpty ? item.name : "\(folderName)/\(item.name)"
            let sanitized = Self.sanitizePath(rawPath)
            guard !sanitized.isEmpty else {
                warnings.append("Skipped item with empty name.")
                continue
            }

            records.append(ExportRecord(
                path: sanitized,
                password: password,
                username: Self.nilIfEmpty(login.username),
                url: Self.nilIfEmpty(login.uris?.first?.uri),
                notes: Self.nilIfEmpty(item.notes),
                totp: Self.nilIfEmpty(login.totp),
                extraFields: [:]
            ))
        }

        let conflicts = records.map(\.path).filter { existingPaths.contains($0) }
        return ImportPreview(records: records, conflicts: conflicts, parseWarnings: warnings)
    }

    // MARK: - Helpers

    /// Sanitises a Bitwarden item name into a `pass`-safe path. Pass
    /// itself rejects `:` (used by Windows drive prefixes) and `\`
    /// (treated as an escape). Whitespace is trimmed.
    static func sanitizePath(_ path: String) -> String {
        path
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func nilIfEmpty(_ s: String?) -> String? {
        guard let s else { return nil }
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Bitwarden DTOs (decode-only)

    private struct BitwardenRoot: Decodable {
        let items: [BitwardenItem]
        let folders: [BitwardenFolder]

        enum CodingKeys: String, CodingKey { case items, folders }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.items = try c.decodeIfPresent([BitwardenItem].self, forKey: .items) ?? []
            self.folders = try c.decodeIfPresent([BitwardenFolder].self, forKey: .folders) ?? []
        }
    }

    private struct BitwardenItem: Decodable {
        let name: String
        let folderId: String?
        let type: Int
        let login: BitwardenLogin?
        let notes: String?
    }

    private struct BitwardenLogin: Decodable {
        let username: String?
        let password: String?
        let uris: [BitwardenURI]?
        let totp: String?
    }

    private struct BitwardenURI: Decodable {
        let uri: String?
    }

    private struct BitwardenFolder: Decodable {
        let id: String
        let name: String
    }
}
