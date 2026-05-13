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
//  Phase F.5 — subscribes to `PassManaging.changes` so any successful
//  write (insert / update / remove / move / bulk) re-fetches the
//  underlying snapshot.
//
//  Phase H.1 — adds per-event selection reconciliation rules on top
//  of the F.5 re-list. The contract is intentionally split between
//  the centralised handler (this file) and the imperative selection
//  setting performed by individual write models:
//
//  - `.inserted(path:)` — the centralised handler does NOT touch
//    `appState.selectedEntryID`. The event is UI-origin neutral:
//    a `.inserted` from "create new entry" is indistinguishable from
//    a `.inserted` produced by an edit (which Mock currently does not
//    emit, but which a future write path could). The write model
//    that produced the insert knows its own intent and sets the
//    selection imperatively (see `EntryFormModel.applySuccess` in
//    `.create` mode). See `.ai/decisions.md` MVP 2 § "Cache
//    invalidation".
//  - `.updated(path:)` — selection unchanged. `EntryDetailModel`
//    runs its own `pass.changes` subscription and re-fetches the
//    secret if the updated path matches the current selection
//    (see `EntryDetailModel.observeChanges()`).
//  - `.moved(from:to:)` — if the selection was on `from`, it
//    follows to `to`. The imperative set in
//    `MoveEntryModel.applySuccess` already does this; the
//    centralised rule is idempotent and serves as a safety net.
//  - `.removed(path:)` — if the selection was on `path`, it is
//    cleared. `EntryListModel.deleteEntry(at:)` already clears it
//    imperatively; the centralised rule is idempotent.
//  - `.bulk` — re-list, then preserve the selection if it survives
//    the new entries snapshot, otherwise clear.
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

    /// Discrete delete-pipeline phase (Phase G.5). `idle` while no
    /// delete is in flight; `deleting` while ``deleteEntry(at:)`` is
    /// running. The view binds the toolbar 🗑 button's `.disabled`
    /// to ``canDelete`` (which folds in this state + the selection
    /// gate), and a re-entrant ``deleteEntry(at:)`` call early-
    /// returns when the model is already `.deleting`.
    enum DeletionState: Sendable, Equatable {
        case idle
        case deleting
    }

    /// Current delete-pipeline phase. Mutated only by
    /// ``deleteEntry(at:)``.
    private(set) var deletionState: DeletionState = .idle

    private let passManager: any PassManaging
    private let searchEngine: any EntrySearching
    private let state: AppState

    /// Ordered IDs returned by the search engine for the current
    /// non-empty query.
    private var searchResultIDs: [String] = []

    /// In-flight debounced search task (`performSearch`).
    private var currentSearchTask: Task<Void, Never>?

    /// Long-lived subscription to `passManager.changes`. Started by
    /// ``observeChanges()`` (typically driven by the view's `.task`
    /// modifier so cancellation is automatic on disappear) and
    /// optionally torn down by ``stop()`` for tests / programmatic
    /// detachment.
    private var changeSubscriptionTask: Task<Void, Never>?

    init(environment: AppEnvironment, state: AppState) {
        self.passManager = environment.passManager
        self.searchEngine = environment.searchEngine
        self.state = state
        self.allEntries = []
    }

    /// `true` when the toolbar 🗑 / `Entry > Delete Entry` menu item
    /// (⌫) should be enabled: a non-nil selection AND no in-flight
    /// delete. Phase G.6 will broaden this to a centralised
    /// `appState.anyWriteInFlight` lockout; for G.5 the delete
    /// pipeline is the only write that funnels through this model.
    var canDelete: Bool {
        guard state.router.selectedEntryID != nil else { return false }
        return deletionState == .idle
    }

    /// Filtered, sorted list driving the entry-list UI.
    ///
    /// Two filtering modes, mutually exclusive:
    /// 1. **Search active** (`AppState.searchQuery` non-empty after
    ///    trim) — search spans the WHOLE store. The folder filter is
    ///    bypassed so users can find an entry without first having to
    ///    navigate to its folder. Match is a case-insensitive
    ///    substring over the full entry path.
    /// 2. **No search** — folder filter applies: when
    ///    `AppState.selectedFolder` is non-empty, only entries whose
    ///    top-level path component matches are kept; otherwise every
    ///    entry is returned.
    ///
    /// The folder scope is restored automatically when the search
    /// query is cleared.
    var entries: [PassEntry] {
        let query = state.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        if !query.isEmpty {
            let entriesByID = Dictionary(uniqueKeysWithValues: allEntries.map { ($0.id, $0) })
            return searchResultIDs.compactMap { id in
                entriesByID[id]
            }
        }

        let folder = state.router.selectedFolder
        return allEntries.filter { entry in
            guard let folder, !folder.isEmpty else { return true }
            let head: String
            if let slash = entry.path.firstIndex(of: "/") {
                head = String(entry.path[..<slash])
            } else {
                head = entry.path
            }
            return head == folder
        }
    }

    /// Reload the underlying entry snapshot from the pass-manager.
    ///
    /// Cooperatively cancellable: if the surrounding `Task` is
    /// cancelled before or after the listing completes, the previous
    /// snapshot is preserved so the UI never observes a transient
    /// empty state caused by cancellation. On any thrown failure the
    /// snapshot is cleared — error UI surfaces are wired in Phase 8.
    func refresh() async {
        if Task.isCancelled { return }
        do {
            let loaded = try await passManager.listEntries()
            if Task.isCancelled { return }
            self.allEntries = loaded
        } catch is CancellationError {
            return
        } catch {
            if Task.isCancelled { return }
            self.allEntries = []
        }
    }

    /// Trigger debounced search for the current `state.searchQuery`.
    ///
    /// Cancels the previous in-flight search task, applies a short
    /// debounce, then updates `searchResultIDs` with the ordered
    /// `SearchResult.id` values returned by the search engine.
    func performSearch() async {
        currentSearchTask?.cancel()

        let task = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(150))
                guard let self else { return }

                let query = self.state.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else {
                    self.searchResultIDs = []
                    return
                }

                let results = try await self.searchEngine.search(query)
                self.searchResultIDs = results.map(\.id)
            } catch is CancellationError {
                return
            } catch {
                guard let self else { return }
                self.searchResultIDs = []
            }
        }

        currentSearchTask = task
        await task.value
    }

    /// Update the shared selection in `AppState`. Called by the view
    /// in response to row taps / list selection changes.
    func select(entryID: PassEntry.ID?) {
        state.router.selectedEntryID = entryID
    }

    // MARK: - Delete (Phase G.5)

    /// Delete the entry at `path` after the user has confirmed via
    /// the C.1 ``destructiveConfirmation`` dialog. Captures the
    /// current secret BEFORE removing it so an ``ActionHistory``
    /// undo can restore the body verbatim, then calls
    /// ``PassManaging/remove(_:)`` (which uses `pass rm -f` under
    /// the hood — the UI's two-step confirmation is the only
    /// confirmation gate).
    ///
    /// Re-entrancy: if ``deletionState == .deleting`` (a prior
    /// delete is still in flight) the call early-returns. Callers
    /// (toolbar / menu) should also gate on ``canDelete``.
    ///
    /// Failure modes:
    /// - ``show(_:)`` throws → refuse to delete; the body cannot be
    ///   captured for undo, so deleting it would be irrecoverable.
    ///   Posts a `.danger` toast and leaves ``deletionState ==
    ///   .idle``.
    /// - ``remove(_:)`` throws → posts a `.danger` toast carrying
    ///   the user-facing error message; the store is unchanged
    ///   (the manager throws BEFORE deleting).
    ///
    /// On success:
    /// - Clears `appState.selectedEntryID` if it was equal to
    ///   `path` (defensive selection follow-up; Phase H will
    ///   centralise this via `.removed` events).
    /// - Records ``UndoableAction/delete(path:secret:)`` in the
    ///   shared `ActionHistory` with the standard 10-second window.
    /// - Posts a `.success` toast carrying an "Undo" action that
    ///   calls ``ActionHistory/undoLast()``. Per
    ///   `.ai/decisions.md`, the toast carries only the entry path
    ///   — never secret material.
    func deleteEntry(at path: String) async {
        // Re-entrancy guard. The toolbar / menu also gate on
        // `canDelete`, so this is the second line of defence.
        guard deletionState == .idle else { return }

        deletionState = .deleting
        // Phase G.6 — mark the delete op as in flight so the
        // toolbars / menu items disable other write surfaces. The
        // op is released on every exit branch below (early returns
        // on `show` / `remove` failure, success) via the `defer`
        // block.
        state.beginWrite(.delete)
        defer { state.endWrite(.delete) }
        let entry = PassEntry(path: path)

        // Capture the secret for undo BEFORE removing the entry.
        // If `show` fails (decryption error, missing fixture, etc.)
        // we refuse to delete: an irrecoverable destructive op is
        // not what the user signed up for.
        let secret: PassSecret
        do {
            secret = try await passManager.show(entry)
        } catch {
            deletionState = .idle
            state.toastCenter.post(
                Toast(
                    severity: .danger,
                    title: "Delete failed",
                    message: "Could not load secret for undo at \(path)."
                )
            )
            return
        }

        // Remove the entry. On failure the store is unchanged —
        // surface a danger toast and exit.
        do {
            try await passManager.remove(entry)
        } catch let passError as PassError {
            deletionState = .idle
            state.toastCenter.post(
                Toast(
                    severity: .danger,
                    title: "Delete failed",
                    message: Self.userFacingMessage(for: passError)
                )
            )
            return
        } catch {
            // Defensive — `PassManaging` is contractually typed-throw
            // `PassError`, but we wrap the generic case in case the
            // contract ever loosens.
            deletionState = .idle
            state.toastCenter.post(
                Toast(
                    severity: .danger,
                    title: "Delete failed",
                    message: "Unexpected error while deleting \(path)."
                )
            )
            return
        }

        // Defensive selection follow-up. Phase H will centralise
        // this via the `.removed` event; for G.5 the imperative
        // path mirrors G.4 (selection follows move).
        if state.router.selectedEntryID == path {
            state.router.selectedEntryID = nil
        }

        // Record the inverse FIRST so the toast's Undo action has
        // something to consume, THEN post the toast.
        state.actionHistory.record(
            .delete(path: path, secret: secret),
            expiresAfter: .seconds(10)
        )

        // Capture the action history reference into a local so the
        // closure does not need to capture `self` — keeps the
        // Sendable check on `BannerAction` clean and avoids retain
        // cycles via the model.
        let history = state.actionHistory
        let undoAction = BannerView.BannerAction(label: "Undo") {
            // Fire-and-forget. `ActionHistory.undoLast()` clears
            // `pending` even on failure (per its contract), so the
            // user can move on. A future polish pass could surface
            // the failure as a fresh error toast.
            Task { try? await history.undoLast() }
        }

        state.toastCenter.post(
            Toast(
                severity: .success,
                title: "Entry deleted",
                // Per `.ai/decisions.md`, toasts NEVER carry secret
                // material — only the entry path is permitted.
                message: path,
                action: undoAction
            )
        )

        deletionState = .idle
    }

    /// Short, user-facing message for a `PassError` surfaced through
    /// the delete-failure toast. The CLI/stderr excerpt is
    /// deliberately omitted — toasts must not carry secret material
    /// and the Diagnostics view is the right place for raw output.
    private static func userFacingMessage(for error: PassError) -> String {
        switch error {
        case .sourceNotFound(let path):
            return "The entry \(path) is no longer in the store."
        case .recipientNotFound(let id):
            return "GPG cannot find a public key for \(id)."
        case .invalidGpgId:
            return "The store's GPG recipients are not configured."
        case .entryAlreadyExists(let path):
            return "An entry already exists at \(path)."
        case .invalidLength:
            return "The requested length was rejected."
        case .writeFailed(let reason):
            if let reason, !reason.isEmpty {
                return "Delete failed: \(reason)."
            }
            return "Delete failed."
        case .timedOut:
            return "The operation timed out."
        case .shellFailure(let exitCode, _):
            return "pass exited with code \(exitCode)."
        case .decryptionFailed:
            return "Decryption failed."
        case .parsingFailed(let reason):
            return "Could not parse pass output: \(reason)"
        case .storeNotFound(let path):
            return "Password store not found at \(path)."
        case .binaryNotFound(let name):
            return "Required binary \(name) was not found."
        case .pinentryNotConfigured:
            return "pinentry is not configured."
        case .cancelled:
            return "Cancelled."
        // Git-side (MVP 4)
        case .gitNotInitialized:
            return "Git is not initialised in the password store."
        case .gitNoRemote:
            return "No git remote configured."
        case .gitAuthFailed:
            return "Git authentication failed."
        case .gitConflict(let paths):
            if let paths, !paths.isEmpty {
                return "Merge conflict in: \(paths.joined(separator: ", "))"
            }
            return "Merge conflict occurred."
        case .gitNetworkUnavailable:
            return "Network unavailable. Check your connection."
        case .gitRejected(let reason):
            return "Push rejected: \(reason)"
        }
    }

    // MARK: - StoreChange subscription (Phase F.5)

    /// Subscribe to `passManager.changes` and re-fetch the entry
    /// snapshot on every event.
    ///
    /// Intended to be driven by the hosting view's `.task { await
    /// model.observeChanges() }` so the subscription's lifetime matches
    /// the view: SwiftUI cancels the surrounding task on disappear,
    /// the `for await` loop sees the cancellation and exits cleanly.
    ///
    /// Calling this method while a subscription is already active is a
    /// no-op — the existing subscription is preserved so we don't drop
    /// in-flight events. To explicitly tear the subscription down (for
    /// example in tests) call ``stop()`` first.
    ///
    /// **Phase F.5 / H.1 reaction policy.** Every event triggers a
    /// full ``refresh()``. F.5 guarantees the list reflects the FS
    /// state after any change so newly-inserted entries become
    /// visible without a manual ⌘R; Phase H.1 layers per-event
    /// selection reconciliation on top (see ``handle(_:)`` for the
    /// rule table).
    func observeChanges() async {
        // Avoid double-subscribing; if a prior call wired a task,
        // simply yield back to the caller. The existing task already
        // governs the subscription lifetime.
        guard changeSubscriptionTask == nil else { return }

        // Snapshot the stream up-front so the `for await` loop is
        // owned by the spawned task — this lets the task be cancelled
        // (and the iterator dropped) cleanly when the view disappears.
        let stream = passManager.changes

        let task = Task { [weak self] in
            for await event in stream {
                if Task.isCancelled { return }
                guard let self else { return }
                await self.handle(event)
            }
        }
        changeSubscriptionTask = task

        // Block the caller (the view's `.task`) until the subscription
        // task completes. SwiftUI cancels the surrounding task on view
        // disappear; cancellation propagates here and we forward it to
        // the subscription task before returning.
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }

        // Drop the reference once the task has exited so a future
        // `observeChanges()` call can re-subscribe.
        changeSubscriptionTask = nil
    }

    /// Cancel the active changes subscription (if any). Idempotent.
    /// Tests use this to prove that events after `stop()` no longer
    /// drive a refresh; in production, view-disappear cancellation is
    /// the usual lifecycle.
    func stop() {
        changeSubscriptionTask?.cancel()
        changeSubscriptionTask = nil
    }

    // MARK: - Private

    /// React to a single `StoreChange`. Phase F.5 mapped every
    /// variant to a re-list; Phase H.1 adds per-event selection
    /// reconciliation:
    ///
    /// - `.inserted` — re-list. Selection is NOT touched here:
    ///   `StoreChange` is UI-origin neutral (an insert from create
    ///   vs. edit looks identical), so the write model that
    ///   produced the insert is responsible for setting selection
    ///   imperatively if its intent calls for it.
    ///   `EntryFormModel(.create).applySuccess` already does this.
    /// - `.updated` — re-list. Selection unchanged.
    ///   `EntryDetailModel` re-fetches via its own subscription.
    /// - `.moved(from, to)` — re-list, then if `selectedEntryID ==
    ///   from`, follow it to `to`. Idempotent w.r.t. the imperative
    ///   set in `MoveEntryModel.applySuccess`.
    /// - `.removed(path)` — re-list, then if `selectedEntryID ==
    ///   path`, clear it. Idempotent w.r.t. the imperative clear in
    ///   `EntryListModel.deleteEntry`.
    /// - `.bulk` — re-list, then clear the selection if it no
    ///   longer matches any surviving entry; otherwise leave it
    ///   alone.
    private func handle(_ event: StoreChange) async {
        switch event {
        case .inserted:
            await refresh()

        case .updated:
            await refresh()

        case .moved(let from, let to):
            await refresh()
            if state.router.selectedEntryID == from {
                state.router.selectedEntryID = to
            }

        case .removed(let path):
            await refresh()
            if state.router.selectedEntryID == path {
                state.router.selectedEntryID = nil
            }

        case .bulk:
            await refresh()
            if let selected = state.router.selectedEntryID,
               !allEntries.contains(where: { $0.path == selected }) {
                state.router.selectedEntryID = nil
            }
        }
    }
}
