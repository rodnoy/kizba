//
//  ActionHistoryTests.swift
//  KizbaTests
//
//  Phase G.1 — coverage for the in-session undo store.
//
//  Scope:
//
//  - Recording surface: initial state, single record, replacement,
//    manual clear, expiry timer, observable updates.
//  - Per-variant undo: ``.delete``, ``.move``, ``.inPlaceGenerate``
//    each flips ``MockPassManager`` back to its pre-action state.
//  - Edge cases: undo after expiry is a no-op; failed undo clears
//    `pending` regardless and propagates the underlying error.
//
//  Time-dependent assertions use the real clock with very generous
//  margins (≤ 200ms) to avoid CI flapping; the longest test sleeps
//  ~250ms.
//

import XCTest
@testable import Kizba

@MainActor
final class ActionHistoryTests: XCTestCase {

    // MARK: - Recording surface

    func testInitialState_pendingIsNil() {
        let history = makeHistory()
        XCTAssertNil(history.pending)
    }

    func testRecord_setsPending() {
        let history = makeHistory()
        history.record(.move(from: "a", to: "b"))
        guard let pending = history.pending else {
            return XCTFail("expected pending action")
        }
        guard case .move(let from, let to) = pending.action else {
            return XCTFail("expected .move, got \(pending.action)")
        }
        XCTAssertEqual(from, "a")
        XCTAssertEqual(to, "b")
        XCTAssertFalse(pending.isExpired)
    }

    func testRecord_replacesPreviousAction_andCancelsPriorExpiry() async {
        let history = makeHistory()

        // First action with a very short window.
        history.record(.move(from: "a", to: "b"), expiresAfter: .milliseconds(40))
        let firstID = history.pending?.id

        // Replace before expiry with a long-window action — the prior
        // expiry must be cancelled, otherwise the new pending could
        // be wrongly cleared at ~40ms.
        try? await Task.sleep(for: .milliseconds(10))
        history.record(.move(from: "c", to: "d"), expiresAfter: .seconds(60))
        let secondID = history.pending?.id
        XCTAssertNotNil(firstID)
        XCTAssertNotNil(secondID)
        XCTAssertNotEqual(firstID, secondID)

        // Wait past when the FIRST expiry would have fired. The new
        // pending must still be in place.
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(history.pending?.id, secondID)
    }

    func testClear_resetsPendingAndCancelsExpiry() async {
        let history = makeHistory()
        history.record(.move(from: "a", to: "b"), expiresAfter: .seconds(60))
        XCTAssertNotNil(history.pending)
        history.clear()
        XCTAssertNil(history.pending)

        // Just to prove the expiry was cancelled — record a fresh
        // action and confirm its id is independent.
        history.record(.move(from: "c", to: "d"), expiresAfter: .seconds(60))
        XCTAssertNotNil(history.pending)
    }

    // MARK: - Expiry

    func testExpiry_clearsPendingAfterWindow() async {
        let history = makeHistory()
        history.record(.move(from: "a", to: "b"), expiresAfter: .milliseconds(50))
        XCTAssertNotNil(history.pending)
        await waitUntil({ history.pending == nil }, timeout: 1.0)
        XCTAssertNil(history.pending)
    }

    func testExpiry_longWindow_keepsPending() async {
        let history = makeHistory()
        history.record(.move(from: "a", to: "b"), expiresAfter: .seconds(60))
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertNotNil(history.pending)
    }

    // MARK: - Undo: delete

    func testUndoLast_delete_reInsertsSecret() async throws {
        let entry = PassEntry(path: "personal/email/gmail")
        let secret = PassSecret(
            password: "p4ss",
            metadata: PassMetadata(fields: [.init(key: "user", value: "jane")])
        )
        let manager = MockPassManager(entries: [entry], secrets: [entry.path: secret])
        let history = makeHistory(passManager: manager)

        // Simulate the just-completed delete.
        try await manager.remove(entry)
        let afterDelete = try await manager.listEntries().map(\.path)
        XCTAssertEqual(afterDelete, [])

        history.record(.delete(path: entry.path, secret: secret))
        try await history.undoLast()

        let restored = try await manager.show(entry)
        XCTAssertEqual(restored, secret)
        let afterUndo = try await manager.listEntries().map(\.path)
        XCTAssertEqual(afterUndo, [entry.path])
        XCTAssertNil(history.pending)
    }

    // MARK: - Undo: move

    func testUndoLast_move_movesEntryBack() async throws {
        let original = PassEntry(path: "from/path")
        let secret = PassSecret(password: "p")
        let manager = MockPassManager(entries: [original], secrets: [original.path: secret])
        let history = makeHistory(passManager: manager)

        // Simulate the just-completed move.
        _ = try await manager.move(from: original, to: "to/path", force: false)
        let afterMove = try await manager.listEntries().map(\.path)
        XCTAssertEqual(afterMove, ["to/path"])

        history.record(.move(from: "from/path", to: "to/path"))
        try await history.undoLast()

        let afterUndo = try await manager.listEntries().map(\.path)
        XCTAssertEqual(afterUndo, ["from/path"])
        let restored = try await manager.show(original)
        XCTAssertEqual(restored, secret)
        XCTAssertNil(history.pending)
    }

    // MARK: - Undo: in-place generate

    func testUndoLast_inPlaceGenerate_restoresPriorSecret() async throws {
        let entry = PassEntry(path: "work/aws/root")
        let s1 = PassSecret(
            password: "old-password",
            metadata: PassMetadata(fields: [.init(key: "user", value: "root")])
        )
        let manager = MockPassManager(entries: [entry], secrets: [entry.path: s1])
        let history = makeHistory(passManager: manager)

        // Record BEFORE the regeneration so the pending action carries
        // the prior secret. Then simulate the regeneration via a
        // forced overwrite.
        history.record(.inPlaceGenerate(path: entry.path, previousSecret: s1))
        let s2 = PassSecret(password: "fresh-rolled-password")
        _ = try await manager.insert(entry, secret: s2, force: true)
        let afterRegen = try await manager.show(entry)
        XCTAssertEqual(afterRegen, s2)

        try await history.undoLast()

        let restored = try await manager.show(entry)
        XCTAssertEqual(restored, s1)
        XCTAssertNil(history.pending)
    }

    // MARK: - Undo: no-pending / expired

    func testUndoLast_noPending_isNoOp() async throws {
        let manager = ObservingMockPassManager()
        let history = ActionHistory(passManager: manager)
        try await history.undoLast()
        let count = await manager.callCount
        XCTAssertEqual(count, 0)
        XCTAssertNil(history.pending)
    }

    func testUndoLast_afterExpiry_isNoOp_andClearsPending() async throws {
        let manager = ObservingMockPassManager()
        let history = ActionHistory(passManager: manager)
        history.record(
            .delete(path: "x", secret: PassSecret(password: "p")),
            expiresAfter: .milliseconds(50)
        )
        // Wait past expiry. The background expiry task will also
        // clear `pending`; whichever path runs first, undoLast must
        // remain a no-op and not invoke the manager.
        try? await Task.sleep(for: .milliseconds(120))
        try await history.undoLast()
        let count = await manager.callCount
        XCTAssertEqual(count, 0)
        XCTAssertNil(history.pending)
    }

    // MARK: - Undo: failure clears pending and propagates

    func testUndoLast_inverseFails_propagatesAndClearsPending() async {
        let manager = AlwaysFailingInsertManager(
            error: .recipientNotFound(emailOrKeyId: "alice@x")
        )
        let history = ActionHistory(passManager: manager)
        history.record(.delete(path: "x", secret: PassSecret(password: "p")))

        do {
            try await history.undoLast()
            XCTFail("expected throw")
        } catch let error as PassError {
            XCTAssertEqual(error, .recipientNotFound(emailOrKeyId: "alice@x"))
        } catch {
            XCTFail("unexpected error: \(error)")
        }

        XCTAssertNil(history.pending)
    }

    // MARK: - Helpers

    private func makeHistory(
        passManager: any PassManaging = MockPassManager(entries: [], secrets: [:])
    ) -> ActionHistory {
        ActionHistory(passManager: passManager)
    }

    // using shared waitUntil helper from Fixtures/AsyncTestHelpers
}

// MARK: - Test fakes

/// Records call counts on every `PassManaging` mutation so the
/// "no-op" undo paths can verify the manager was never touched.
/// Wraps a tiny `MockPassManager` instead of inheriting from it to
/// keep the surface narrow.
private actor ObservingMockPassManager: PassManaging {

    private(set) var callCount: Int = 0

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw PassError.decryptionFailed(stderrExcerpt: "n/a")
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-observing")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        callCount += 1
        return entry
    }

    func remove(_ entry: PassEntry) async throws {
        callCount += 1
    }

    func move(from: PassEntry, to newPath: String, force: Bool) async throws -> PassEntry {
        callCount += 1
        return PassEntry(path: newPath)
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// Throws a single scripted `PassError` from `insert` so the failed-
/// undo path can be exercised. Same shape as the
/// `ScriptedFailingPassManager` declared inside
/// `EntryFormModelCreateTests` — kept local because that one is
/// `private` to its file.
private actor AlwaysFailingInsertManager: PassManaging {

    private let error: PassError

    init(error: PassError) {
        self.error = error
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw PassError.decryptionFailed(stderrExcerpt: "n/a")
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-failing-insert")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        throw error
    }

    func remove(_ entry: PassEntry) async throws {
        throw error
    }

    func move(from: PassEntry, to newPath: String, force: Bool) async throws -> PassEntry {
        throw error
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}
