//
//  ClipboardServicing.swift
//  Kizba
//
//  Domain abstraction over the system pasteboard with token-checked
//  auto-clear. Real implementation lives in
//  `Infrastructure/Clipboard/ClipboardService.swift`; tests substitute
//  `FakeClipboard`.
//

import Foundation

/// Pasteboard service that writes secrets verbatim and auto-clears
/// them after a delay, but only if no other writer (the user, another
/// app, or a later `copy` call) has superseded the value.
///
/// ## Threading contract
///
/// `Sendable`. ``copy(_:clearAfter:)`` is `async` and may be called
/// from any actor; implementations bridge to AppKit's `NSPasteboard`
/// on the MainActor internally.
///
/// ## Security invariants (per `.ai/decisions.md`)
///
/// - Values are written **verbatim**. Implementations must never
///   compose `"key: value"` strings.
/// - Clear is gated on both a generation token and the pasteboard's
///   `changeCount` snapshot, so it cannot clobber later user content.
public protocol ClipboardServicing: Sendable {

    /// Write `value` to the system pasteboard and schedule an
    /// auto-clear after `clearAfter`.
    ///
    /// If a subsequent `copy` arrives before the clear fires, only the
    /// most recent token's clear will run. If the pasteboard is
    /// modified externally before the clear fires, the clear is
    /// cancelled.
    ///
    /// - Parameters:
    ///   - value: Exact string to place on the pasteboard. Never
    ///     transformed or composed with other fields.
    ///   - clearAfter: Delay before the auto-clear attempt.
    func copy(_ value: String, clearAfter: Duration) async
}
