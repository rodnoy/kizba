//
//  SidebarModel.swift
//  Kizba
//
//  Observable view model backing `SidebarView`. Derives the
//  deterministic, sorted list of top-level folders from the
//  `PassManaging` listing surface. Holds no secret material.
//

import Foundation
import Observation

/// A top-level sidebar row representing a single first-path-component
/// folder in the password store (e.g. `personal`, `work`, `archive`).
///
/// `id` equals `name` so the value can drive SwiftUI list selection
/// directly; the explicit struct (rather than a bare `String`) leaves
/// room for per-folder counts or icons in later phases without churn.
struct SidebarFolder: Hashable, Identifiable, Sendable {
    let name: String
    var id: String { name }
}

/// View model for `SidebarView`.
///
/// Queries `PassManaging.listEntries()` and computes the sorted set of
/// top-level folders (the first path component of each entry path).
/// Entries lacking a `/` separator (top-level entries) are skipped —
/// the sidebar surfaces folders only.
///
/// `@MainActor` because the view consumes it directly; the pass-manager
/// call is `async` and may run off-main internally, results are read
/// back on the main actor.
@Observable
@MainActor
final class SidebarModel {

    /// Sorted list of top-level folders. Empty until ``load()`` runs
    /// (or after a load that returned no entries).
    private(set) var folders: [SidebarFolder]

    private let passManager: any PassManaging

    init(passManager: any PassManaging) {
        self.passManager = passManager
        self.folders = []
    }

    /// Refresh the folder list from the pass-manager surface.
    ///
    /// On `PassError` (or any other failure) the folder list is left
    /// empty — error UI surfaces are wired in Phase 8.
    func load() async {
        do {
            let entries = try await passManager.listEntries()
            self.folders = Self.topLevelFolders(from: entries)
        } catch {
            self.folders = []
        }
    }

    /// Pure derivation: first path component of every entry, deduped
    /// and sorted ascending. Visible for testing.
    static func topLevelFolders(from entries: [PassEntry]) -> [SidebarFolder] {
        var seen = Set<String>()
        var ordered: [String] = []
        for entry in entries {
            guard let slash = entry.path.firstIndex(of: "/") else { continue }
            let head = String(entry.path[..<slash])
            guard !head.isEmpty, !seen.contains(head) else { continue }
            seen.insert(head)
            ordered.append(head)
        }
        return ordered.sorted().map { SidebarFolder(name: $0) }
    }
}
