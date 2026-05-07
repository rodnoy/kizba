//
//  ClipboardServiceTests.swift
//  KizbaTests
//
//  Phase 7.2 — deterministic unit tests for `ClipboardService` using
//  `FakeClipboard`. None of these tests touch `NSPasteboard.general`.
//
//  Each test uses short delays (50–250 ms) and bounded waits to keep
//  the suite snappy while still exercising the auto-clear timeline.
//

import XCTest
@testable import Kizba

final class ClipboardServiceTests: XCTestCase {

    // MARK: - Helpers

    /// Sleep helper for tests; returns after `milliseconds` ms.
    private func sleep(milliseconds: UInt64) async {
        try? await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }

    // MARK: - 7.2 (a) verbatim write

    /// `copy` writes the value verbatim, with no `"key: value"`
    /// composition or other transformation.
    func testCopyWritesVerbatim() async {
        let fake = FakeClipboard()
        let service = ClipboardService(adapter: fake)

        // Use a long delay so the auto-clear cannot interfere with
        // the assertion below; the test never waits for it.
        await service.copy("secret-value", clearAfter: .seconds(60))

        XCTAssertEqual(fake.lastValue, "secret-value")
        XCTAssertEqual(fake.lastChangeCount, 1, "exactly one write should have occurred")
    }

    // MARK: - 7.2 (b) auto-clear when unchanged

    /// When the pasteboard is untouched between write and the
    /// scheduled clear, the service clears it.
    func testAutoClear_whenUnchanged() async {
        let fake = FakeClipboard()
        let service = ClipboardService(adapter: fake)

        await service.copy("top-secret", clearAfter: .milliseconds(80))
        XCTAssertEqual(fake.lastValue, "top-secret")
        let afterWrite = fake.lastChangeCount

        // Wait comfortably past the delay to give the detached
        // clear-task time to fire.
        await sleep(milliseconds: 300)

        XCTAssertEqual(fake.lastValue, "", "clipboard should have been cleared")
        XCTAssertEqual(
            fake.lastChangeCount, afterWrite + 1,
            "clear() should have bumped changeCount exactly once"
        )
    }

    // MARK: - 7.2 (c) no clear when changeCount diverges

    /// When the pasteboard is modified externally between write and
    /// the scheduled clear, the service must NOT clear it.
    func testNoClear_whenChangeCountDiffers() async {
        let fake = FakeClipboard()
        let service = ClipboardService(adapter: fake)

        await service.copy("alpha", clearAfter: .milliseconds(80))

        // Simulate the user copying something else from another app.
        fake.simulateExternalWrite("user-pasted-this")
        let bumped = fake.lastChangeCount

        await sleep(milliseconds: 300)

        XCTAssertEqual(
            fake.lastValue, "user-pasted-this",
            "external clipboard content must not be wiped"
        )
        XCTAssertEqual(
            fake.lastChangeCount, bumped,
            "no further changeCount bump should have occurred"
        )
    }

    // MARK: - 7.2 (d) only the latest copy clears

    /// Two copies in quick succession: only the second one's
    /// scheduled clear should run; the first must be neutralised by
    /// the token gate.
    func testMultipleCopies_onlyLatestClears() async {
        let fake = FakeClipboard()
        let service = ClipboardService(adapter: fake)

        // First copy, with a *longer* delay than the second so
        // ordering by wall-clock cannot rescue correctness — only
        // the token gate can.
        await service.copy("first", clearAfter: .milliseconds(150))

        // Second copy lands before the first delay would elapse.
        await sleep(milliseconds: 30)
        await service.copy("second", clearAfter: .milliseconds(80))
        let afterSecondWrite = fake.lastChangeCount
        XCTAssertEqual(fake.lastValue, "second")

        // Wait long enough for BOTH delays to have lapsed.
        await sleep(milliseconds: 400)

        // The second copy's clear should have run (one extra bump).
        XCTAssertEqual(fake.lastValue, "")
        XCTAssertEqual(
            fake.lastChangeCount, afterSecondWrite + 1,
            "exactly one clear should have happened (the second copy's)"
        )
    }

    // MARK: - 7.2 (e) cancellation of older clear-task on new copy

    /// Variant of (d) focusing on cancellation semantics: a newer
    /// copy must prevent the older copy's pending clear from wiping
    /// the latest value, even if the new copy uses a delay that is
    /// LONGER than what remained on the previous timer.
    func testCancellation_ofClearTask_onNewCopy() async {
        let fake = FakeClipboard()
        let service = ClipboardService(adapter: fake)

        // First copy with a short delay.
        await service.copy("first", clearAfter: .milliseconds(80))

        // New copy arrives BEFORE the first delay elapses, with a
        // generous delay. If the older clear-task were not gated by
        // the token, it would now wipe "second".
        await sleep(milliseconds: 30)
        await service.copy("second", clearAfter: .seconds(60))
        let afterSecondWrite = fake.lastChangeCount

        // Wait past the first copy's original deadline.
        await sleep(milliseconds: 200)

        XCTAssertEqual(
            fake.lastValue, "second",
            "the older clear-task must not wipe the newer value"
        )
        XCTAssertEqual(
            fake.lastChangeCount, afterSecondWrite,
            "no clear should have happened in this window"
        )
    }
}

// MARK: - FakeClipboard

/// Deterministic `PasteboardAdapter` double for `ClipboardService`
/// tests (Phase 7.2). Never touches the real system pasteboard.
///
/// Behaviour:
///   - `write(_:)` records the value and increments `changeCount`,
///     mirroring `NSPasteboard`.
///   - `clear()` records an empty string and increments `changeCount`.
///   - Tests can simulate an external pasteboard writer by calling
///     `simulateExternalWrite(_:)`, which bumps `changeCount` without
///     going through the actor under test.
///
/// File-private to avoid clashing with the unrelated `FakeClipboard`
/// helpers used by `DomainProtocolsTests` and
/// `EntryDetailModelRefinementTests` (which conform to
/// `ClipboardServicing`, not `PasteboardAdapter`).
private final class FakeClipboard: PasteboardAdapter, @unchecked Sendable {

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

    /// Simulate an external pasteboard writer (the user, another app)
    /// by recording a new value and bumping `changeCount`. Used by
    /// the "no clear when changeCount differs" test.
    func simulateExternalWrite(_ value: String) {
        lock.lock(); defer { lock.unlock() }
        _lastValue = value
        _changeCount += 1
    }
}
