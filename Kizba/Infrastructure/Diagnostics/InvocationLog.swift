//
//  InvocationLog.swift
//  Kizba
//
//  Concurrency-safe, bounded in-memory ring buffer for recent shell
//  invocations. Powers the Diagnostics view (`DiagnosticsModel`).
//
//  Hard rules (per `.ai/decisions.md` and `.ai/plan.md` Phase 8.4):
//
//  - Storage is **in-memory only** — no disk persistence.
//  - Captured `stdout` never reaches this actor (see `Invocation`).
//  - Newest-first ordering on read so the UI shows the most recent
//    activity at the top without extra sorting.
//

import Foundation

/// Protocol surface used by `ProcessShellRunner` to publish
/// invocations without taking a hard dependency on the concrete
/// `InvocationLog` actor (keeps tests cheap and the runner's API
/// minimal).
public protocol InvocationLogging: Sendable {
    func record(_ invocation: Invocation) async
}

/// Bounded ring buffer of recent ``Invocation`` records.
///
/// Backed by an `actor` so concurrent shell calls (e.g. parallel
/// `pass show` invocations) can safely append without locks at the
/// call site. The buffer is intentionally small (default 200) because
/// MVP-1 Diagnostics is a debugging aid, not a long-term audit log.
public actor InvocationLog: InvocationLogging {

    /// Maximum number of records retained. Older records are evicted
    /// in FIFO order once the limit is reached.
    public let maxEntries: Int

    /// Internal storage. Oldest-first; ``recent()`` reverses on read
    /// so callers always see newest-first.
    private var entries: [Invocation] = []

    public init(maxEntries: Int = 200) {
        // Defensive: guarantee at least one slot so `record` never has
        // to special-case a zero-sized buffer.
        self.maxEntries = max(1, maxEntries)
    }

    /// Append `invocation` to the buffer, evicting the oldest entry
    /// when the size cap is exceeded.
    public func record(_ invocation: Invocation) {
        entries.append(invocation)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    /// Snapshot of currently retained invocations, **newest first**.
    public func recent() -> [Invocation] {
        Array(entries.reversed())
    }

    /// Drop every retained invocation.
    public func clear() {
        entries.removeAll(keepingCapacity: false)
    }
}
