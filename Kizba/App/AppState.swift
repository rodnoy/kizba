//
//  AppState.swift
//  Kizba
//
//  Top-level observable application state for the SwiftUI vertical
//  slice. Holds only non-secret UI state — never a `PassSecret` (per
//  `.ai/decisions.md`, decrypted bodies live exclusively in the active
//  `EntryDetailModel` and are released on selection change).
//
//  Phase G.1 — `AppState` now also owns the `ActionHistory` (in-session
//  undo, ~10s window). To construct `ActionHistory` we need a
//  `PassManaging` reference, so the designated initialiser takes one
//  explicitly. A `#if DEBUG` zero-arg convenience init is provided
//  that wires a tiny empty `MockPassManager` so existing test fixtures
//  that only care about the UI state portion (`AppStateTests`,
//  `EntryListModelTests`, `EntryDetailModelTests`, etc.) keep
//  compiling without per-test churn.
//

import Foundation
import Observation

/// Identifies a single in-flight write operation tracked by
/// ``AppState/activeWriteOps``. Write models call
/// ``AppState/beginWrite(_:)`` when they enter their saving /
/// deleting / running phase and ``AppState/endWrite(_:)`` when the
/// operation terminates (success, failure, or cancellation).
///
/// The typed enum (rather than a single `Int` counter) future-proofs
/// the API: a follow-up could disable only OTHER toolbar buttons
/// while a specific op is in flight, or surface a per-op progress
/// badge. Phase G.6 only consumes the `Bool` aggregate
/// ``AppState/anyWriteInFlight``.
public enum ActiveWriteOp: Sendable, Hashable {
    /// `EntryFormModel(.create)` — the New Entry sheet's save.
    case insertNew
    /// `EntryFormModel(.edit)` — the Edit Entry sheet's save.
    case edit
    /// `RegenerateInPlaceModel` — the in-place generate sheet.
    case regenerate
    /// `MoveEntryModel` — the Move Entry sheet's save.
    case move
    /// `EntryListModel.deleteEntry` — the destructive delete pipeline.
    case delete
}

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

    /// NOTE: presentation flags and selection are now owned by
    /// ``AppRouter`` mounted at ``router``. AppState no longer
    /// declares selection or presentation proxy properties — views
    /// and view models must read/write `state.router.*` instead.

    /// Live search query bound to the sidebar's search field.
    var searchQuery: String

    /// Whether the sidebar column is collapsed in the
    /// `NavigationSplitView`.
    var isSidebarCollapsed: Bool

    /// Snapshot of the entries currently driving the sidebar list.
    /// Refreshed by the listing pipeline (Phase 4); empty until then.
    var currentEntries: [PassEntry]

    // selection is owned by `router` (see above)

    /// App-wide toast coordinator. Owned (not optional) so view
    /// models can post toasts via `appState.toastCenter.post(...)`
    /// without nil-checking. Per `.ai/decisions.md`, NOT a global
    /// singleton — every `AppState` instance gets its own.
    let toastCenter: ToastCenter

    /// In-session undo store for destructive writes (delete, move,
    /// in-place regenerate). Owned by `AppState` (NOT a global
    /// singleton). Cleared on app quit. Used by Phase G.3 – G.5
    /// to record actions and by toast Undo buttons to invoke the
    /// inverse via `PassManaging`.
    let actionHistory: ActionHistory

    /// Centralised router owning presentation flags and selection
    /// helpers. Introduced in MVP 3 Phase B.1 as a migration target
    /// for presentation state.
    var router: AppRouter = AppRouter()

    /// Optional Git status model. Wired by AppEnvironment when git
    /// integration is available for the current store.
    var gitStatusModel: GitStatusModel?

    // presentation flags are owned by `router` (see above)

    /// Set of in-flight write operations (Phase G.6). Each write
    /// model calls ``beginWrite(_:)`` when it enters its
    /// `.saving` / `.deleting` / `.running` phase and
    /// ``endWrite(_:)`` when the operation terminates (success,
    /// failure, or cancellation). The UI consumes only the boolean
    /// aggregate ``anyWriteInFlight`` to lock out other write
    /// affordances; the typed ``ActiveWriteOp`` payload is preserved
    /// for future per-op affordances (progress badge, op-aware
    /// disable rules).
    ///
    /// A `Set` (rather than a single `ActiveWriteOp?`) is used
    /// defensively: in theory two write ops could overlap (e.g. a
    /// delete in flight when a refresh-triggered write begins), and
    /// `Set` semantics make ``beginWrite(_:)`` /``endWrite(_:)``
    /// idempotent.
    private(set) var activeWriteOps: Set<ActiveWriteOp> = []

    /// Aggregate consumed by the toolbars and menu items (Phase G.6).
    /// `true` when any write op is currently in flight; the UI
    /// disables all write-side buttons while this is `true`. Read-
    /// side affordances (Refresh, Settings, Diagnostics) are
    /// intentionally NOT gated on this flag.
    var anyWriteInFlight: Bool { !activeWriteOps.isEmpty }

    /// Marks `op` as in flight. Idempotent — calling this twice with
    /// the same case has the same effect as calling it once (Set
    /// semantics). Every ``beginWrite(_:)`` MUST be paired with
    /// exactly one ``endWrite(_:)`` for the same case; the write
    /// models guarantee this via their existing state-transition
    /// discipline (success / failure / cancel paths each call
    /// ``endWrite(_:)`` exactly once).
    func beginWrite(_ op: ActiveWriteOp) {
        activeWriteOps.insert(op)
    }

    /// Marks `op` as no longer in flight. Idempotent — calling this
    /// for an op that is not in the set is a no-op (Set semantics).
    func endWrite(_ op: ActiveWriteOp) {
        activeWriteOps.remove(op)
    }

    /// Designated initialiser. `passManager` is required so
    /// ``actionHistory`` can be constructed; every other parameter
    /// has a sensible default so a fresh
    /// `AppState(passManager:)` is meaningful at app launch.
    init(
        passManager: any PassManaging,
        searchQuery: String = "",
        isSidebarCollapsed: Bool = false,
        currentEntries: [PassEntry] = [],
        toastCenter: ToastCenter = ToastCenter(),
        gitStatusModel: GitStatusModel? = nil
    ) {
        self.searchQuery = searchQuery
        self.isSidebarCollapsed = isSidebarCollapsed
        self.currentEntries = currentEntries
        self.toastCenter = toastCenter
        self.actionHistory = ActionHistory(passManager: passManager)
        self.gitStatusModel = gitStatusModel
        // `router` already initialised to a fresh `AppRouter()`; it
        // owns selection and presentation state.
    }

    #if DEBUG
    /// DEBUG-only zero-arg / partial-arg convenience initialiser used
    /// by tests and SwiftUI previews that do not care about the
    /// `PassManaging` collaborator wired into ``actionHistory``.
    /// Wires a fresh, empty ``MockPassManager``; production code
    /// MUST use the designated initialiser with the real manager
    /// from ``AppEnvironment``.
    convenience init(
        searchQuery: String = "",
        isSidebarCollapsed: Bool = false,
        currentEntries: [PassEntry] = [],
        toastCenter: ToastCenter = ToastCenter()
    ) {
        self.init(
            passManager: MockPassManager(entries: [], secrets: [:]),
            searchQuery: searchQuery,
            isSidebarCollapsed: isSidebarCollapsed,
            currentEntries: currentEntries,
            toastCenter: toastCenter,
            gitStatusModel: nil
        )
    }
    #endif
}
