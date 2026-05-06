//
//  EntryListModel.swift
//  Kizba
//
//  Observable view model backing `EntryListView` (middle column of the
//  root `NavigationSplitView`). Derives a filtered, sorted list of
//  `PassEntry` values from `PassManaging.listEntries()` and the
//  current `AppState` selection / search query.
//
//  Holds no secret material — `PassSecret` lives only in the active
//  `EntryDetailModel` (per `.ai/decisions.md`).
//

import Foundation
import Observation

/// View model for `EntryListView`.
///
/// Loads the full entry list from `PassManaging.listEntries()` once,
/// then derives a filtered slice (`entries`) on demand from the current
/// folder selection and search query held by `AppState`. Filtering is
/// pure, deterministic, and case-insensitive over the full entry path.
///
/// `@MainActor` because the view consumes it directly; the pass-manager
/// call is `async` and may run off-main internally, results are stored
/// back on the main actor.
@Observable
@MainActor
final class EntryListModel {

    /// Full snapshot of the store as returned by the last successful
    /// `passManager.listEntries()` call. Empty until ``refresh()`` runs.
    private(set) var allEntries: [PassEntry]

    private let passManager: any PassManaging
    private let state: AppState

    init(environment: AppEnvironment, state: AppState) {
        self.passManager = environment.passManager
        self.state = state
        self.allEntries = []
    }

    /// Filtered, sorted list driving the entry-list UI.
    ///
    /// Combines two filters:
    /// 1. Folder filter — when `AppState.selectedFolder` is set, only
    ///    entries whose top-level path component matches are kept.
    /// 2. Search filter — when `AppState.searchQuery` is non-empty,
    ///    keep entries whose full path contains the query (case
    ///    insensitive).
    var entries: [PassEntry] {
        let folder = state.selectedFolder
        let query = state.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        return allEntries.filter { entry in
            if let folder, !folder.isEmpty {
                let head: String
                if let slash = entry.path.firstIndex(of: "/") {
                    head = String(entry.path[..<slash])
                } else {
                    head = entry.path
                }
                guard head == folder else { return false }
            }
            if !query.isEmpty {
                guard entry.path.range(of: query, options: .caseInsensitive) != nil else {
                    return false
                }
            }
            return true
        }
    }

    /// Reload the underlying entry snapshot from the pass-manager.
    ///
    /// On any failure the snapshot is left empty — error UI surfaces
    /// are wired in Phase 8.
    func refresh() async {
        do {
            let loaded = try await passManager.listEntries()
            self.allEntries = loaded
        } catch {
            self.allEntries = []
        }
    }

    /// Update the shared selection in `AppState`. Called by the view
    /// in response to row taps / list selection changes.
    func select(entryID: PassEntry.ID?) {
        state.selectedEntryID = entryID
    }
}
