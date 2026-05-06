//
//  PassEntry.swift
//  Kizba
//
//  Domain value type identifying a single entry in the password store.
//  An entry is the metadata-only descriptor (path); its decrypted body
//  is a separate `PassSecret` produced on demand by `PassManaging.show`.
//

import Foundation

/// A single addressable entry in the password store, identified by the
/// `pass`-style relative path (without the `.gpg` suffix).
///
/// Example: `"work/aws/root"` for `~/.password-store/work/aws/root.gpg`.
///
/// `PassEntry` deliberately carries **no** secret material — only the
/// path and derived display fields. The decrypted body is fetched lazily
/// via ``PassManaging`` and returned as ``PassSecret``.
public struct PassEntry: Hashable, Sendable, Codable, Identifiable {

    /// `pass`-style relative path, e.g. `"work/aws/root"`. Forward
    /// slashes denote folders; never ends in `.gpg`.
    public let path: String

    public init(path: String) {
        self.path = path
    }

    /// Stable identity for SwiftUI lists.
    public var id: String { path }

    /// Last path component — what the entry list shows as the row title.
    public var name: String {
        guard let slash = path.lastIndex(of: "/") else { return path }
        return String(path[path.index(after: slash)...])
    }

    /// Folder path (everything before the final `/`), or `""` for
    /// top-level entries.
    public var folder: String {
        guard let slash = path.lastIndex(of: "/") else { return "" }
        return String(path[..<slash])
    }
}
