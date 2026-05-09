//
//  ToastCenter.swift
//  Kizba
//
//  Observable, MainActor-isolated coordinator that posts and auto-
//  dismisses toasts. Owned by `AppState` (NOT a global singleton —
//  per `.ai/decisions.md`). At-most-one toast is visible at a time;
//  a new post pre-empts the currently-visible toast (no stacking),
//  matching the macOS pattern.
//
//  Dedup contract: identical posts (same `(severity, title, message)`
//  triple) within 1 second of the previous post are silently dropped.
//
//  Auto-dismiss: each post spawns a sleep-then-clear `Task` whose
//  duration is read from the toast (default 4s, undoable 10s). The
//  task is cancelled on every new post and on every manual `dismiss`.
//

import Foundation
import Observation

/// Posts and tracks the currently-visible `Toast`. SwiftUI views can
/// observe `visible` to render the overlay; mutations are only safe
/// on `MainActor`, which `@MainActor` enforces.
@Observable
@MainActor
public final class ToastCenter {

    /// The currently-visible toast, or `nil` when no toast is shown.
    /// Observable from SwiftUI.
    public private(set) var visible: Toast?

    /// Track of the most recent post for dedup. `nil` until the first
    /// post. Uses `ContinuousClock` because it survives system sleep
    /// and is monotonic — neither requirement matters for a 1-second
    /// window in practice, but it documents the intent.
    private var lastDedup: (key: String, postedAt: ContinuousClock.Instant)?

    /// In-flight auto-dismiss task. Cancelled on every new post and
    /// on every manual `dismiss(_:)`.
    private var currentDismissTask: Task<Void, Never>?

    /// The dedup window — identical posts within this many seconds of
    /// the previous one are silently dropped.
    private static let dedupWindow: Duration = .seconds(1)

    public init() {
        self.visible = nil
    }

    /// Post a toast. Drops the post silently if it duplicates the
    /// previous post (same `severity`, `title`, `message`) within
    /// 1 second; otherwise replaces the currently-visible toast and
    /// schedules auto-dismissal after `toast.duration`.
    public func post(_ toast: Toast) {
        let key = toast.dedupKey
        let now = ContinuousClock().now

        if let last = lastDedup,
           last.key == key,
           last.postedAt.duration(to: now) < Self.dedupWindow {
            // Within dedup window — drop silently. Do not refresh the
            // window, otherwise a stream of identical posts would
            // suppress forever.
            return
        }

        // Cancel any pending auto-dismiss for the previous toast and
        // pre-empt it.
        currentDismissTask?.cancel()
        currentDismissTask = nil

        visible = toast
        lastDedup = (key: key, postedAt: now)

        let duration = toast.duration
        let postedID = toast.id
        currentDismissTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            guard let self else { return }
            // Only clear if the same toast is still on screen — a
            // newer post would have replaced it and cancelled this
            // task already, but this guard makes the contract robust
            // against scheduling edge cases.
            if self.visible?.id == postedID {
                self.visible = nil
            }
        }
    }

    /// Manually dismiss the currently-visible toast if its `id`
    /// matches `id`. No-op otherwise — protects against late callers
    /// from a previous toast that has already been pre-empted.
    public func dismiss(_ id: UUID) {
        guard visible?.id == id else { return }
        currentDismissTask?.cancel()
        currentDismissTask = nil
        visible = nil
    }
}
