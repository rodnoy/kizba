//
//  FolderNode.swift
//  Kizba
//
//  Recursive folder tree node used by the sidebar's hierarchical
//  folder listing (MVP9.3). Built by ``FolderTreeBuilder`` from a flat
//  list of ``PassEntry`` values; carries no entries itself — the
//  sidebar surfaces folders only and the middle column resolves the
//  contained entries via prefix-match on ``EntryListModel``.
//

import Foundation

/// A single folder in the sidebar tree.
///
/// ``fullPath`` is the canonical store-relative folder path (e.g.
/// ``"system/work"`` — no leading or trailing slash); ``name`` is the
/// last path component used as the display label.
///
/// Each node owns its already-sorted, fully-recursive children
/// — leaves are folders with an empty ``children`` array (they may
/// still hold direct entries; the entries live in the entry list, not
/// in the tree).
public struct FolderNode: Sendable, Equatable, Identifiable {

    /// Full path from the store root (e.g. ``"system/work"``). No
    /// leading or trailing slash. Doubles as ``id`` so SwiftUI can
    /// drive `ForEach` / selection bindings off the node directly.
    public let fullPath: String

    /// Last path component (e.g. ``"work"`` for ``"system/work"``).
    /// Used as the display name in the sidebar row.
    public let name: String

    /// Direct children, pre-sorted alphabetically (case-insensitive,
    /// ``localizedCaseInsensitiveCompare``).
    public let children: [FolderNode]

    public var id: String { fullPath }

    public init(fullPath: String, name: String, children: [FolderNode]) {
        self.fullPath = fullPath
        self.name = name
        self.children = children
    }

    /// `true` when the node has no sub-folders. Leaves may still
    /// contain direct entries (resolved by the entry-list column);
    /// the sidebar uses this flag to render a flat row instead of a
    /// `DisclosureGroup`.
    public var isLeaf: Bool { children.isEmpty }
}
