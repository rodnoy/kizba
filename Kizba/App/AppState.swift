//
//  AppState.swift
//  Kizba
//
//  Top-level observable application state for the SwiftUI vertical
//  slice. Holds only non-secret UI state — never a `PassSecret` (per
//  `.ai/decisions.md`, decrypted bodies live exclusively in the active
//  `EntryDetailModel` and are released on selection change).
//

import Foundation
import Observation

/// Observable, MainActor-isolated root state for the Kizba window.
///
/// State management uses the Observation framework (`@Observable`)
/// rather than `ObservableObject` — per-property change tracking and
/// no `@Published` boilerplate.
///
/// `@MainActor` is enforced because every consumer is a SwiftUI view
/// or view model bound to the main run loop. Background producers
/// (e.g. `PassManaging.listEntries()` results) hop to MainActor before
/// mutating this type.
@Observable
@MainActor
final class AppState {

    /// Currently selected entry's identity, or `nil` when nothing is
    /// selected. Matches `PassEntry.ID` (which is `String` — the
    /// `pass`-style relative path).
    var selectedEntryID: PassEntry.ID?

    /// Live search query bound to the sidebar's search field.
    var searchQuery: String

    /// Whether the sidebar column is collapsed in the
    /// `NavigationSplitView`.
    var isSidebarCollapsed: Bool

    /// Snapshot of the entries currently driving the sidebar list.
    /// Refreshed by the listing pipeline (Phase 4); empty until then.
    var currentEntries: [PassEntry]

    /// Currently selected top-level folder name (e.g. `"work"`), or
    /// `nil` when no folder is selected. Drives the middle (entry
    /// list) column.
    var selectedFolder: String?

    /// App-wide toast coordinator. Owned (not optional) so view
    /// models can post toasts via `appState.toastCenter.post(...)`
    /// without nil-checking. Per `.ai/decisions.md`, NOT a global
    /// singleton — every `AppState` instance gets its own.
    let toastCenter: ToastCenter

    /// Whether the `NewEntrySheet` is presented. Owned by `AppState`
    /// so any surface in the main window can request the sheet —
    /// the toolbar `+` button on `EntryListView`, the `Entry > New
    /// Entry…` menu item (⌘N), or any future affordance — without
    /// each one threading its own `@State` Bool. The sheet is
    /// hosted by `EntryListView` (the natural anchor for a
    /// "create" affordance in the entry list column).
    var isNewEntrySheetPresented: Bool

    /// Designated initialiser. All parameters default to empty / unset
    /// state so a fresh `AppState()` is meaningful at app launch.
    init(
        selectedEntryID: PassEntry.ID? = nil,
        searchQuery: String = "",
        isSidebarCollapsed: Bool = false,
        currentEntries: [PassEntry] = [],
        selectedFolder: String? = nil,
        toastCenter: ToastCenter = ToastCenter(),
        isNewEntrySheetPresented: Bool = false
    ) {
        self.selectedEntryID = selectedEntryID
        self.searchQuery = searchQuery
        self.isSidebarCollapsed = isSidebarCollapsed
        self.currentEntries = currentEntries
        self.selectedFolder = selectedFolder
        self.toastCenter = toastCenter
        self.isNewEntrySheetPresented = isNewEntrySheetPresented
    }
}
