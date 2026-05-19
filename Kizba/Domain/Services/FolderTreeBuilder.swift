//
//  FolderTreeBuilder.swift
//  Kizba
//
//  Pure derivation of a hierarchical ``FolderNode`` tree from the
//  flat list of ``PassEntry`` values returned by ``PassManaging``.
//  Intermediate folders are materialised even when no direct entries
//  live there — e.g. ``"a/b/c/leaf"`` produces nodes ``a``, ``a/b``
//  and ``a/b/c``.
//
//  MVP9.3 — wired into ``SidebarModel`` via ``folderTree``.
//

import Foundation

/// Builds a sorted hierarchical ``FolderNode`` tree from a flat
/// snapshot of entries.
///
/// The builder is intentionally stateless and pure: the same input
/// always produces the same output, the result is fully ordered, and
/// no side effects are observable. Sorting is case-insensitive
/// (``localizedCaseInsensitiveCompare``) at every nesting level so
/// the sidebar order matches Finder.
public enum FolderTreeBuilder {

    /// Build the top-level ``FolderNode`` array (each node holds its
    /// full nested subtree).
    ///
    /// Top-level entries (paths without any ``/``) contribute no
    /// folder node — they are surfaced as entries directly in the
    /// middle column. An empty input yields an empty array.
    public static func build(from entries: [PassEntry]) -> [FolderNode] {
        // Collect every unique folder path. For ``"system/work/whatever"``:
        //   folders = ["system", "system/work"]
        // (the entry's own name "whatever" is NOT a folder).
        var folderPaths = Set<String>()
        for entry in entries {
            let parts = entry.path
                .split(separator: "/", omittingEmptySubsequences: false)
                .map(String.init)
            guard parts.count > 1 else { continue }  // top-level entry — no folder
            for prefixLen in 1..<parts.count {
                let segment = parts[prefixLen - 1]
                // Skip empty path components (e.g. trailing slashes that
                // produce a "" segment). They would otherwise pollute the
                // sidebar with an unnameable node.
                if segment.isEmpty { continue }
                let folder = parts.prefix(prefixLen).joined(separator: "/")
                folderPaths.insert(folder)
            }
        }

        return buildSubtree(at: "", from: folderPaths)
    }

    /// Recursive helper: build the children of ``parentPath``
    /// (empty string for the top level).
    private static func buildSubtree(
        at parentPath: String,
        from allFolderPaths: Set<String>
    ) -> [FolderNode] {
        let parentPrefix = parentPath.isEmpty ? "" : parentPath + "/"

        // Direct children: paths that sit exactly one component below
        // ``parentPath``. We compute the relative tail and require it
        // to be non-empty and contain no further ``/``.
        let directChildren = allFolderPaths.filter { path in
            if parentPath.isEmpty {
                return !path.contains("/")
            }
            guard path.hasPrefix(parentPrefix) else { return false }
            let relative = path.dropFirst(parentPrefix.count)
            return !relative.isEmpty && !relative.contains("/")
        }

        return directChildren
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            .map { path in
                let name = path.split(separator: "/").last.map(String.init) ?? path
                let children = buildSubtree(at: path, from: allFolderPaths)
                return FolderNode(fullPath: path, name: name, children: children)
            }
    }
}
