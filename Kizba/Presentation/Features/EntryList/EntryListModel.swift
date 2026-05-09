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
