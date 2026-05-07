//
//  ClipboardService.swift
//  Kizba
//
//  Production conformance to `ClipboardServicing` (Phase 7.1). Writes
//  values to the system pasteboard verbatim and schedules a
//  conditional auto-clear gated on a generation token plus the
//  pasteboard's `changeCount` snapshot.
//
//  ## Auto-clear gate (per `.ai/decisions.md`)
//
//  Every `copy` mints a fresh opaque token (`UUID().uuidString`) and
//  records the adapter's `changeCount` immediately after the verbatim
//  write. A detached `Task` then sleeps for the requested delay; once
//  it wakes it asks the actor whether the still-current generation
//  token matches its own AND the adapter's current `changeCount` is
//  unchanged. Only if BOTH hold does it issue a `clear()`.
//
//  This protects two distinct timelines:
//
//  1. **Newer `copy`** — supersedes the older token; the older clear
//     becomes a no-op even if its sleep had not yet been cancelled.
//  2. **External writer** — bumps `changeCount` past our snapshot, so
//     the gate refuses to wipe the user's later content.
//
//  ## Threading contract
//
//  `actor`. Conforms to `ClipboardServicing` (which is `Sendable`).
//  The pasteboard adapter is `Sendable`, called from any context;
//  the production `SystemPasteboardAdapter` hops to the main actor
//  internally because `NSPasteboard.general` is `MainActor`-bound.
//
//  ## Logging discipline (per `.ai/decisions.md` & `Log.swift`)
//
//  - Logs only sanctioned shape-only metadata via `Log.clipboard`:
//      * "copy occurred" event with public boolean shape signals,
//      * "clear attempt" outcome (cleared / token-superseded /
//        changeCount-diverged).
//  - **Never** logs the copied value, nor any portion of it, nor its
//    length. The whole point of this service is to keep secrets out
//    of process-visible state.
//
//  ## Test seam
//
//  The actor depends on a narrow `PasteboardAdapter` protocol; tests
//  inject a `FakeClipboard` (see `KizbaTests/Fixtures/FakeClipboard.swift`)
//  to drive `changeCount` deterministically without touching the real
//  system pasteboard.
//

import Foundation
import os

#if canImport(AppKit)
import AppKit
#endif

// MARK: - PasteboardAdapter

/// Narrow surface required by ``ClipboardService`` so tests can
/// substitute a deterministic double for the real `NSPasteboard`.
///
/// Implementations must be `Sendable`. Production wiring uses
/// ``SystemPasteboardAdapter``; tests use `FakeClipboard`.
internal protocol PasteboardAdapter: Sendable {

    /// Monotonic counter incremented by the underlying pasteboard
    /// every time its contents change — including writes performed
    /// by this very adapter. The auto-clear gate compares the
    /// post-write snapshot to the current value just before clearing.
    var changeCount: Int { get async }

    /// Replace the pasteboard's string contents with `value` verbatim.
    /// Implementations must not transform, prefix, suffix, or
    /// otherwise compose the value with any other field.
    func write(_ value: String) async

    /// Wipe the pasteboard's contents. Implementations should also
    /// bump `changeCount` (the system pasteboard does this naturally).
    func clear() async
}



// MARK: - SystemPasteboardAdapter

#if canImport(AppKit)

/// Production `PasteboardAdapter` backed by `NSPasteboard.general`.
///
/// `NSPasteboard` is `MainActor`-bound on macOS, so every call hops
/// to the main actor. The hop is cheap and only happens on the copy
/// / clear paths, both of which are user-driven.
struct SystemPasteboardAdapter: PasteboardAdapter {

    init() {}

    var changeCount: Int {
        get async {
            await MainActor.run { NSPasteboard.general.changeCount }
        }
    }

    func write(_ value: String) async {
        await MainActor.run {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(value, forType: .string)
        }
    }

    func clear() async {
        await MainActor.run {
            NSPasteboard.general.clearContents()
            return ()
        }
    }
}

#endif

// MARK: - ClipboardService

/// Production `ClipboardServicing` actor with token+changeCount
/// auto-clear (Phase 7.1).
public actor ClipboardService: ClipboardServicing {

    private let adapter: any PasteboardAdapter

    /// Generation token of the most recent successful `copy`. The
    /// scheduled clear-task captures its own token at write time and
    /// compares against this value before wiping.
    private var currentToken: String?

    /// `changeCount` snapshot taken immediately after the most recent
    /// successful `write`. The clear-task compares this against the
    /// adapter's live value to detect external pasteboard writers.
    private var snapshotChangeCount: Int?

    /// In-flight clear-task for the current generation, if any. New
    /// copies cancel the previous task as a courtesy — correctness
    /// already follows from the token gate, but cancellation avoids
    /// keeping a dormant `Task.sleep` alive unnecessarily.
    private var pendingClearTask: Task<Void, Never>?

    /// Designated initialiser for tests and advanced wiring; accepts
    /// any `PasteboardAdapter`. Production code should prefer the
    /// no-argument convenience initialiser below on macOS, which
    /// wires up `SystemPasteboardAdapter` automatically.
    init(adapter: any PasteboardAdapter) {
        self.adapter = adapter
    }

    #if canImport(AppKit)
    /// Convenience initialiser for production wiring on macOS.
    /// Equivalent to `init(adapter: SystemPasteboardAdapter())`.
    public init() {
        self.adapter = SystemPasteboardAdapter()
    }
    #endif

    // MARK: ClipboardServicing

    public func copy(_ value: String, clearAfter: Duration) async {
        let token = UUID().uuidString

        // Cancel any older pending clear-task. The token gate would
        // already neutralise it, but cancellation lets the dormant
        // sleeper exit promptly.
        pendingClearTask?.cancel()
        pendingClearTask = nil

        // Verbatim write — no composition with any other field, per
        // `.ai/decisions.md`.
        await adapter.write(value)

        // Snapshot the post-write changeCount; this is what the gate
        // will compare against at clear time.
        let snapshot = await adapter.changeCount
        currentToken = token
        snapshotChangeCount = snapshot

        Log.clipboard.info("clipboard copy occurred (auto-clear scheduled)")

        // Schedule the conditional clear. Detached so we never block
        // the caller. The task is owned by the actor so a later copy
        // can cancel it eagerly.
        let adapterRef = adapter
        let delay = clearAfter
        pendingClearTask = Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                // Cancelled (likely by a newer copy). Nothing to do.
                return
            }
            await self?.attemptClear(
                token: token,
                expectedChangeCount: snapshot,
                adapter: adapterRef
            )
        }
    }

    // MARK: - Private

    /// Token+changeCount gate. Runs on the actor so the comparison
    /// against `currentToken` / `snapshotChangeCount` is race-free.
    private func attemptClear(
        token: String,
        expectedChangeCount: Int,
        adapter: any PasteboardAdapter
    ) async {
        guard currentToken == token else {
            Log.clipboard.info("clipboard auto-clear skipped: token superseded")
            return
        }

        let live = await adapter.changeCount
        guard live == expectedChangeCount else {
            Log.clipboard.info("clipboard auto-clear skipped: changeCount diverged")
            return
        }

        await adapter.clear()

        // Drop the generation we just cleared so a stale repeat of
        // this method (defensive) cannot clear twice.
        currentToken = nil
        snapshotChangeCount = nil
        pendingClearTask = nil

        Log.clipboard.info("clipboard auto-clear performed")
    }
}
