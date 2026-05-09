//
//  Toast.swift
//  Kizba
//
//  Value type representing a single toast posted by the app. Posted
//  through `ToastCenter.post(_:)`; rendered (when visible) by
//  `ToastOverlay` mounted at the root of `RootSplitView`.
//
//  Per `.ai/decisions.md`, toasts NEVER carry secret material —
//  password, metadata values, or notes. Only the entry path / title /
//  human-readable status is permitted in `title` / `message`.
//

import Foundation

/// A single, immutable toast value. Identity (`id`) is freshly
/// allocated per instance so two posts with otherwise-identical
/// content are still distinguishable for animation / dismissal.
///
/// `Sendable` so it can be safely passed across actor boundaries
/// (e.g. from a background save Task hopping back to MainActor to
/// post on `ToastCenter`).
public struct Toast: Identifiable, Sendable {
    public let id: UUID
    public let severity: BannerView.Severity
    public let title: String
    public let message: String?
    public let action: BannerView.BannerAction?
    public let duration: Duration

    /// Designated initialiser. `duration` defaults to **4 seconds**
    /// for non-actionable toasts and **10 seconds** for toasts that
    /// carry an `action` (the user needs more time to react to an
    /// undoable outcome).
    public init(
        severity: BannerView.Severity,
        title: String,
        message: String? = nil,
        action: BannerView.BannerAction? = nil,
        duration: Duration? = nil
    ) {
        self.id = UUID()
        self.severity = severity
        self.title = title
        self.message = message
        self.action = action
        self.duration = duration ?? (action == nil ? .seconds(4) : .seconds(10))
    }
}

extension Toast {
    /// Stable, content-derived key used by `ToastCenter` to dedup
    /// identical posts within a 1-second window. Excludes `id` and
    /// `action` (the action label / closure are not part of the
    /// "same content" identity for the user).
    var dedupKey: String {
        "\(severity)|\(title)|\(message ?? "")"
    }
}
