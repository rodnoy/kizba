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
//  underlying snapshot. Selection-follow-up rules (e.g. "if current
//  selection was removed, clear it") are deferred to Phase H; F.5
//  guarantees only that the LIST reflects the FS state after any
//  change. The form-side `EntryFormModel.applySuccess(...)` already
//  sets `appState.selectedEntryID = newPath` imperatively before the
//  refresh handler runs.
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
    private let state: AppState

    /// Long-lived subscription to `passManager.changes`. Started by
    /// ``observeChanges()`` (typically driven by the view's `.task`
    /// modifier so cancellation is automatic on disappear) and
    /// optionally torn down by ``stop()`` for tests / programmatic
    /// detachment.
    private var changeSubscriptionTask: Task<Void, Never>?

    init(environment: AppEnvironment, state: AppState) {
        self.passManager = environment.passManager
        self.state = state
        self.allEntries = []
    }

    /// `true` when the toolbar 🗑 / `Entry > Delete Entry` menu item
    /// (⌫) should be enabled: a non-nil selection AND no in-flight
    /// delete. Phase G.6 will broaden this to a centralised
    /// `appState.anyWriteInFlight` lockout; for G.5 the delete
    /// pipeline is the only write that funnels through this model.
    var canDelete: Bool {
        guard state.selectedEntryID != nil else { return false }
        return deletionState == .idle
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

    /// Update the shared selection in `AppState`. Called by the view
    /// in response to row taps / list selection changes.
    func select(entryID: PassEntry.ID?) {
        state.selectedEntryID = entryID
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
        if state.selectedEntryID == path {
            state.selectedEntryID = nil
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
    /// **Phase F.5 reaction policy.** Every event triggers a full
    /// ``refresh()``. This is intentionally coarse: a re-list is cheap
    /// against the local FS, and Phase H will layer the selection
    /// follow-up rules (`.removed` clears selection if it matched,
    /// `.moved` follows selection from `from` → `to`, etc.) on top.
    /// F.5 only guarantees the list reflects the FS state after any
    /// change so newly-inserted entries become visible without a
    /// manual ⌘R.
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

    /// React to a single `StoreChange`. Phase F.5 maps every variant
    /// to a re-list; Phase H will refine this with selection
    /// follow-up rules.
    private func handle(_ event: StoreChange) async {
        switch event {
        case .inserted, .updated, .removed, .moved, .bulk:
            await refresh()
        }
    }
}
