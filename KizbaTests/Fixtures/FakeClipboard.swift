//
//  FakeClipboard.swift
//  KizbaTests
//
//  Two canonical clipboard test doubles, sharing a file because they
//  are easier to keep in sync side-by-side:
//
//    1. ``FakePasteboardAdapter`` — conforms to `ClipboardService`'s
//       internal `PasteboardAdapter` protocol. Used by tests that
//       exercise `ClipboardService` itself (write / clear timing,
//       changeCount races against external writers).
//
//    2. ``FakeClipboardServicing`` — conforms to `ClipboardServicing`,
//       the public domain protocol injected via `AppEnvironment`.
//       Used by tests that exercise model-level wiring without
//       caring about the underlying pasteboard mechanics.
//
//  Both fakes are `final class` + `@unchecked Sendable` (state guarded
//  by `NSLock`) because their respective protocols require `Sendable`
//  and the tests mutate / observe state from arbitrary actor contexts.
//

import Foundation
@testable import Kizba

// MARK: - FakePasteboardAdapter

/// Deterministic ``PasteboardAdapter`` double for `ClipboardService`
/// tests. Never touches `NSPasteboard.general`.
///
/// Behaviour:
///   - `write(_:)` records the value and increments `changeCount`,
///     mirroring `NSPasteboard`.
///   - `clear()` records an empty string and increments `changeCount`.
///   - Tests can simulate an external pasteboard writer by calling
///     `simulateExternalWrite(_:)`, which bumps `changeCount` without
///     going through the actor under test.
final class FakePasteboardAdapter: PasteboardAdapter, @unchecked Sendable {

    private let lock = NSLock()
    private var _changeCount: Int = 0
    private var _lastValue: String = ""

    init() {}

    // MARK: PasteboardAdapter

    var changeCount: Int {
        get async {
            lock.lock(); defer { lock.unlock() }
            return _changeCount
        }
    }

    func write(_ value: String) async {
        lock.lock(); defer { lock.unlock() }
        _lastValue = value
        _changeCount += 1
    }

    func clear() async {
        lock.lock(); defer { lock.unlock() }
        _lastValue = ""
        _changeCount += 1
    }

    // MARK: Test helpers

    /// Most recent value passed to `write` (or `""` after `clear`).
    var lastValue: String {
        lock.lock(); defer { lock.unlock() }
        return _lastValue
    }

    /// Synchronous snapshot of `changeCount` for assertions.
    var lastChangeCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _changeCount
    }

    /// Simulates an external pasteboard writer (the user, another app)
    /// by recording a new value and bumping `changeCount`. Used by
    /// the "no clear when changeCount differs" test.
    func simulateExternalWrite(_ value: String) {
        lock.lock(); defer { lock.unlock() }
        _lastValue = value
        _changeCount += 1
    }
}

// MARK: - FakeClipboardServicing

/// Deterministic ``ClipboardServicing`` double. Records every
/// `copy(_:clearAfter:)` call in order; never touches the real
/// pasteboard or schedules any clear-task.
final class FakeClipboardServicing: ClipboardServicing, @unchecked Sendable {

    /// Captured `copy` invocation.
    struct Call: Equatable, Sendable {
        let value: String
        let clearAfter: Duration
    }

    private let lock = NSLock()
    private var _calls: [Call] = []

    init() {}

    /// All recorded calls in invocation order.
    var calls: [Call] {
        lock.lock(); defer { lock.unlock() }
        return _calls
    }

    /// Most recent call, if any.
    var lastCall: Call? {
        lock.lock(); defer { lock.unlock() }
        return _calls.last
    }

    func copy(_ value: String, clearAfter: Duration) async {
        lock.lock(); defer { lock.unlock() }
        _calls.append(Call(value: value, clearAfter: clearAfter))
    }
}
