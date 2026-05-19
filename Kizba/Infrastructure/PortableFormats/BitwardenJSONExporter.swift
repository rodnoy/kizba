//
//  BitwardenJSONExporter.swift
//  Kizba
//
//  Serialises a list of ``ExportRecord`` into the Bitwarden
//  unencrypted JSON export format. Output is suitable for re-import
//  into Bitwarden itself or into any tool that consumes the same
//  format (KeePassXC, Vaultwarden, etc).
//
//  Folder semantics: Bitwarden models folders as flat objects, not a
//  path tree. We collapse `parent/child/leaf` paths into a single
//  folder named `"parent/child"` and an item named `"leaf"`. This
//  round-trips cleanly through ``BitwardenJSONImporter`` which
//  rebuilds the same `folder/item` path on import.
//

import Foundation

public struct BitwardenJSONExporter: Sendable {

    public init() {}

    /// - Returns: Pretty-printed Bitwarden JSON bytes, UTF-8.
    public func export(records: [ExportRecord]) throws -> Data {
        var folderMap: [String: UUID] = [:]
        var folders: [BitwardenFolder] = []
        var items: [BitwardenItem] = []

        for record in records {
            let parts = record.path.split(separator: "/").map(String.init)
            let folderName = parts.count > 1 ? parts.dropLast().joined(separator: "/") : ""
            let itemName = parts.last ?? record.path

            var folderId: String? = nil
            if !folderName.isEmpty {
                if let existing = folderMap[folderName] {
                    folderId = existing.uuidString
                } else {
                    let id = UUID()
                    folderMap[folderName] = id
                    folders.append(BitwardenFolder(id: id.uuidString, name: folderName))
                    folderId = id.uuidString
                }
            }

            items.append(BitwardenItem(
                id: UUID().uuidString,
                name: itemName,
                folderId: folderId,
                type: 1, // login
                login: BitwardenLogin(
                    username: record.username,
                    password: record.password,
                    uris: record.url.map { [BitwardenURI(uri: $0)] },
                    totp: record.totp
                ),
                notes: record.notes
            ))
        }

        let root = BitwardenRoot(encrypted: false, folders: folders, items: items)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(root)
    }

    // MARK: - Encode-only DTOs

    private struct BitwardenRoot: Encodable {
        let encrypted: Bool
        let folders: [BitwardenFolder]
        let items: [BitwardenItem]
    }
    private struct BitwardenFolder: Encodable {
        let id: String
        let name: String
    }
    private struct BitwardenItem: Encodable {
        let id: String
        let name: String
        let folderId: String?
        let type: Int
        let login: BitwardenLogin
        let notes: String?
    }
    private struct BitwardenLogin: Encodable {
        let username: String?
        let password: String
        let uris: [BitwardenURI]?
        let totp: String?
    }
    private struct BitwardenURI: Encodable {
        let uri: String
    }
}
