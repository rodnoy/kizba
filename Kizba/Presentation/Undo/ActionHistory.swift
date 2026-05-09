//
//  ActionHistory.swift
//  Kizba
//
//  Phase G.1 — in-session undo store for destructive writes.
//
//  Holds at most ONE pending ``UndoableAction`` at a time. The action
//  expires after a short window (default 10 seconds) and is silently
//  dropped if not undone in time. Toast Undo buttons (Phase G.3 –
//  G.5) call ``undoLast()`` which executes the inverse via
//  ``PassManaging``.
//
//  Ownership
//  ---------
//
//  Owned by ``AppState`` (NOT a global singleton, per
//  `.ai/decisions.md`). Cleared on app quit because the store is
//  in-memory only. System ``UndoManager`` integration is deferred to
//  MVP 3.
//
//  Concurrency
//  -----------
//
//  ``@Observable @MainActor final class``. All mutations of
//  ``pending`` happen on the MainActor; the inverse is awaited on the
//  same actor (``PassManaging`` calls hop off and back as needed).
//  The expiry timer runs on a child ``Task`` and re-enters the
//  MainActor before clearing ``pending``.
//
//  Failure semantics
//  -----------------
//
//  If ``undoLast()`` propagates an error from ``PassManaging``,
//  ``pending`` is cleared anyway: the undo was attempted, the user
//  has consumed the window, and there is no path forward besides
//  recording a NEW action. Callers (toast Undo button) are expected
//  to wrap the throw in `do/catch` and surface a fresh error toast
//  on failure.
//

import Foundation
import Observation

/// Single-step in-session undo coordinator for destructive writes.
@Observable
@MainActor
public final class ActionHistory {

    // MARK: - Pending action

    /// A pending undoable action together with its expiry metadata.
    /// Surfaced through ``ActionHistory/pending`` so SwiftUI views
    /// can observe whether an undo is currently available.
    public struct PendingAction: Identifiable, Sendable {
        /// Stable identity used by ``ActionHistory`` to ignore expiry
        /// callbacks belonging to a previously-superseded action.
        public let id: UUID

        /// The destructive action that can be undone.
        public let action: UndoableAction

        /// Wall-clock-independent timestamp of when the action was
        /// recorded. Uses ``ContinuousClock`` so sleep / clock-drift
        /// do not move the expiry target.
        public let recordedAt: ContinuousClock.Instant

        /// Window after which ``isExpired`` flips to `true` and the
        /// background expiry task clears this action. Defaults to
        /// 10 seconds when unspecified at the call site.
        public let expiresAfter: Duration

        /// `true` once at least ``expiresAfter`` has elapsed since
        /// ``recordedAt``. Pure / cheap — safe to call repeatedly.
        public var isExpired: Bool {
            ContinuousClock().now - recordedAt >= expiresAfter
        }
    }

    /// The currently-recorded undoable action, or `nil` when no
    /// undo is available. Observable from SwiftUI; toast Undo buttons
    /// can disable themselves by reading this.
    public private(set) var pending: PendingAction?

    // MARK: - Dependencies + scheduler

    private let passManager: any PassManaging
    private var expiryTask: Task<Void, Never>?

    // MARK: - Init

    public init(passManager: any PassManaging) {
        self.passManager = passManager
    }

    // MARK: - Recording

    /// Record `action` as the current undoable action, replacing any
    /// previously-recorded action and cancelling its expiry timer.
    /// Schedules a fresh expiry that clears ``pending`` after
    /// `expiresAfter`.
    public func record(_ action: UndoableAction, expiresAfter: Duration = .seconds(10)) {
        // Cancel any previous expiry — its captured id no longer
        // matches the (about-to-be-installed) pending action.
        expiryTask?.cancel()
        expiryTask = nil

        let recorded = PendingAction(
            id: UUID(),
            action: action,
            recordedAt: ContinuousClock().now,
            expiresAfter: expiresAfter
        )
        pending = recorded

        // Spawn the expiry timer. The Task inherits MainActor
        // isolation from this method (project default isolation is
        // MainActor) so it can mutate `pending` directly without an
        // `await`. The id check guards against a fresh `record(_:)`
        // having already replaced this action while the sleep was
        // in flight (in which case we silently exit).
        let recordedID = recorded.id
        expiryTask = Task { [weak self] in
            try? await Task.sleep(for: expiresAfter)
            guard !Task.isCancelled else { return }
            self?.expireIfStillCurrent(id: recordedID)
        }
    }

    // MARK: - Undo

    /// Execute the inverse of the currently-pending action, then
    /// clear it. No-op when there is no pending action OR the action
    /// has expired (the expired action is also cleared, so subsequent
    /// presses do nothing).
    ///
    /// - Throws: ``PassError`` from ``PassManaging`` if the inverse
    ///   write fails. ``pending`` is cleared regardless of throw —
    ///   see the type's documentation.
    public func undoLast() async throws {
        guard let pending = self.pending else { return }
        guard !pending.isExpired else {
            // Window has elapsed silently between the user clicking
            // Undo and us getting MainActor time. Drop and exit.
            self.clear()
            return
        }

        // Cancel the expiry and clear `pending` BEFORE awaiting the
        // inverse. This makes a duplicate Undo press from the toast
        // a no-op, and ensures `pending` does not appear "still
        // available" while the inverse is in flight.
        expiryTask?.cancel()
        expiryTask = nil
        self.pending = nil

        switch pending.action {
        case .delete(let path, let secret):
            let entry = PassEntry(path: path)
            _ = try await passManager.insert(entry, secret: secret, force: true)

        case .move(let from, let to):
            let original = PassEntry(path: to)
            _ = try await passManager.move(from: original, to: from, force: false)

        case .inPlaceGenerate(let path, let previousSecret):
            let entry = PassEntry(path: path)
            _ = try await passManager.insert(entry, secret: previousSecret, force: true)
        }
    }

    // MARK: - Manual clear

    /// Manually clear the pending action without performing the
    /// inverse. Cancels the expiry timer.
    public func clear() {
        expiryTask?.cancel()
        expiryTask = nil
        pending = nil
    }

    // MARK: - Internal expiry callback

    /// Called from the expiry ``Task`` once its sleep elapses. Drops
    /// ``pending`` only when its id still matches `id` — a fresh
    /// ``record(_:)`` between the sleep starting and ending will
    /// have installed a new action whose expiry we must not steal.
    private func expireIfStillCurrent(id: UUID) {
        guard pending?.id == id else { return }
        pending = nil
    }
}
