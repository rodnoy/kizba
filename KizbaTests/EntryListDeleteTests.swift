//
//  EntryListDeleteTests.swift
//  KizbaTests
//
//  Phase G.5 — coverage for `EntryListModel.deleteEntry(at:)`.
//
//  Scope:
//
//  - Initial state and `canDelete` gate (selection + idle).
//  - Happy-path delete: store is mutated, selection is cleared,
//    success toast is posted, ActionHistory records the inverse,
//    `deletionState` returns to `.idle`.
//  - Undo round-trip: invoking `actionHistory.undoLast()` re-inserts
//    the entry with the original secret.
//  - `show` failure aborts the delete with no store mutation and
//    surfaces a danger toast / no ActionHistory record.
//  - `remove` failure aborts the delete with no store mutation and
//    surfaces a danger toast / no ActionHistory record.
//  - Conditional selection clear: deleting a path other than the
//    current selection does not clear the selection.
//  - `deletionState` flips to `.deleting` mid-flight and back to
//    `.idle` on completion.
//  - Re-entrant delete is a no-op (single in-flight delete).
//  - Expired Undo is a no-op (the store stays unchanged).
//
//  Toasts NEVER carry secret material (per `.ai/decisions.md`) —
//  assertions only inspect the severity / title / message / label
//  fields; the recorded `UndoableAction.delete(path:secret:)` is
//  inspected by destructuring the variant directly.
//

import XCTest
@testable import Kizba

@MainActor
final class EntryListDeleteTests: XCTestCase {

    // MARK: - Fixtures

    private let targetPath = "personal/email/gmail"
    private let otherPath = "work/aws/root"

    private func makeSecret(password: String = "p4ss") -> PassSecret {
        PassSecret(
            password: password,
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "jane@example.com")],
                notes: "rotate quarterly"
            )
        )
    }

    /// Build an `AppEnvironment` whose `passManager` is the supplied
    /// double. Other collaborators are no-op fakes — the delete
    /// pipeline only touches `passManager`.
    private func makeEnvironment(passManager: any PassManaging) -> AppEnvironment {
        AppEnvironment(
            passManager: passManager,
            clipboard: NoopClipboard(),
            settings: NoopSettings(),
            passwordGenerator: LivePasswordGenerator(),
            passCLI: nil,
            discovery: nil
        )
    }

    /// Helper: build a fresh `EntryListModel` over a `MockPassManager`
    /// pre-seeded with a single target entry. Returns the model, the
    /// hosting `AppState`, and the manager so tests can poke at the
    /// store directly.
    private func makeModelAndState(
        seedSecrets: [String: PassSecret]? = nil,
        select: String? = nil
    ) -> (EntryListModel, AppState, MockPassManager) {
        let baseSecrets = seedSecrets ?? [targetPath: makeSecret()]
        let entries = baseSecrets.keys.map { PassEntry(path: $0) }
        let manager = MockPassManager(
            entries: entries,
            secrets: baseSecrets
        )
        let env = makeEnvironment(passManager: manager)
        let state = AppState(
            passManager: manager
        )
        state.router.selectedEntryID = select
        let model = EntryListModel(environment: env, state: state)
        return (model, state, manager)
    }

    // MARK: - Initial state + canDelete

    func testInitialState_isIdle_andCannotDeleteWithoutSelection() {
        let (model, state, _) = makeModelAndState(select: nil)
        XCTAssertEqual(model.deletionState, .idle)
        XCTAssertNil(state.router.selectedEntryID)
        XCTAssertFalse(model.canDelete)
    }

    func testCanDelete_isTrue_whenSelectionPresentAndIdle() {
        let (model, state, _) = makeModelAndState(select: targetPath)
        XCTAssertEqual(model.deletionState, .idle)
        XCTAssertNotNil(state.router.selectedEntryID)
        XCTAssertTrue(model.canDelete)
    }

    // MARK: - Happy path

    func testDeleteEntry_happyPath_removesFromStore_clearsSelection_recordsUndo_postsToast_andReturnsIdle() async throws {
        let secret = makeSecret(password: "secret-to-restore")
        let (model, state, manager) = makeModelAndState(
            seedSecrets: [targetPath: secret],
            select: targetPath
        )

        // Sanity preconditions.
        let pre = try await manager.listEntries().map(\.path)
        XCTAssertEqual(pre, [targetPath])
        XCTAssertEqual(state.router.selectedEntryID, targetPath)

        await model.deleteEntry(at: targetPath)

        // State.
        XCTAssertEqual(model.deletionState, .idle)

        // Store-side mutation.
        let post = try await manager.listEntries().map(\.path)
        XCTAssertFalse(post.contains(targetPath))

        // Selection cleared.
        XCTAssertNil(state.router.selectedEntryID)

        // ActionHistory recorded the inverse.
        guard let pending = state.actionHistory.pending else {
            return XCTFail("expected pending undo action")
        }
        guard case .delete(let recordedPath, let recordedSecret) = pending.action else {
            return XCTFail("expected .delete, got \(pending.action)")
        }
        XCTAssertEqual(recordedPath, targetPath)
        XCTAssertEqual(recordedSecret, secret)

        // Toast posted.
        guard let toast = state.toastCenter.visible else {
            return XCTFail("expected visible success toast")
        }
        XCTAssertEqual(toast.severity, .success)
        XCTAssertEqual(toast.title, "Entry deleted")
        XCTAssertEqual(toast.message, targetPath)
        XCTAssertNotNil(toast.action)
        XCTAssertEqual(toast.action?.label, "Undo")
    }

    // MARK: - Undo round-trip

    func testDelete_thenUndo_restoresEntry_andClearsPending() async throws {
        let secret = makeSecret(password: "round-trip-secret")
        let (model, state, manager) = makeModelAndState(
            seedSecrets: [targetPath: secret],
            select: targetPath
        )

        await model.deleteEntry(at: targetPath)

        // Sanity post-delete.
        var listed = try await manager.listEntries().map(\.path)
        XCTAssertFalse(listed.contains(targetPath))

        // Undo.
        try await state.actionHistory.undoLast()

        listed = try await manager.listEntries().map(\.path)
        XCTAssertTrue(listed.contains(targetPath))
        let restored = try await manager.show(PassEntry(path: targetPath))
        XCTAssertEqual(restored, secret)

        // Pending cleared.
        XCTAssertNil(state.actionHistory.pending)
    }

    // MARK: - show failure aborts the delete

    func testDeleteEntry_whenShowFails_abortsWithoutMutating_andPostsDangerToast() async throws {
        // `ShowFailingPassManager.show` always throws; `remove` must
        // never be reached, so it asserts via XCTFail.
        let scripted = ShowFailingPassManager(
            error: .decryptionFailed(stderrExcerpt: "no fixture")
        )
        let env = makeEnvironment(passManager: scripted)
        let state = AppState(
            passManager: scripted,
            selectedEntryID: targetPath
        )
        let model = EntryListModel(environment: env, state: state)

        await model.deleteEntry(at: targetPath)

        // State returned to idle.
        XCTAssertEqual(model.deletionState, .idle)

        // Selection unchanged (no successful delete to follow).
        XCTAssertEqual(state.router.selectedEntryID, targetPath)

        // No undo recorded.
        XCTAssertNil(state.actionHistory.pending)

        // Danger toast posted.
        guard let toast = state.toastCenter.visible else {
            return XCTFail("expected visible danger toast")
        }
        XCTAssertEqual(toast.severity, .danger)
        XCTAssertEqual(toast.title, "Delete failed")
        // Manager-side: `remove` call counter stays at 0.
        let removeCount = await scripted.removeCallCount
        XCTAssertEqual(removeCount, 0)
    }

    // MARK: - remove failure leaves the store unchanged

    func testDeleteEntry_whenRemoveFails_abortsWithoutMutating_andPostsDangerToast() async throws {
        // `RemoveFailingPassManager.show` succeeds with a known
        // secret; `remove` always throws BEFORE mutating any state.
        let secret = makeSecret(password: "still-here")
        let scripted = RemoveFailingPassManager(
            secret: secret,
            removeError: .recipientNotFound(emailOrKeyId: "alice@example.com")
        )
        let env = makeEnvironment(passManager: scripted)
        let state = AppState(
            passManager: scripted,
            selectedEntryID: targetPath
        )
        let model = EntryListModel(environment: env, state: state)

        await model.deleteEntry(at: targetPath)

        XCTAssertEqual(model.deletionState, .idle)
        // Selection unchanged.
        XCTAssertEqual(state.router.selectedEntryID, targetPath)
        // No undo recorded — the destructive op did not complete.
        XCTAssertNil(state.actionHistory.pending)

        // Danger toast posted.
        guard let toast = state.toastCenter.visible else {
            return XCTFail("expected visible danger toast")
        }
        XCTAssertEqual(toast.severity, .danger)
        XCTAssertEqual(toast.title, "Delete failed")
    }

    // MARK: - Conditional selection clear

    func testDeleteEntry_whenSelectionDiffers_doesNotClearSelection() async throws {
        let secret = makeSecret(password: "doomed")
        // Two entries; we delete `targetPath` while `otherPath` is
        // selected. The selection should NOT be cleared.
        let (model, state, manager) = makeModelAndState(
            seedSecrets: [
                targetPath: secret,
                otherPath: makeSecret(password: "kept")
            ],
            select: otherPath
        )

        await model.deleteEntry(at: targetPath)

        // Manager-side: targetPath gone, otherPath survives.
        let listed = try await manager.listEntries().map(\.path)
        XCTAssertFalse(listed.contains(targetPath))
        XCTAssertTrue(listed.contains(otherPath))

        // Selection preserved.
        XCTAssertEqual(state.router.selectedEntryID, otherPath)

        // Toast / undo still posted (delete itself succeeded).
        XCTAssertNotNil(state.toastCenter.visible)
        XCTAssertNotNil(state.actionHistory.pending)
    }

    // MARK: - deletionState mid-flight + completion

    func testDeletionState_isDeletingMidFlight_andIdleAfterCompletion() async throws {
        // Use a slow manager so we can observe `.deleting` between
        // call start and completion.
        let scripted = SlowDeletePassManager(
            secret: makeSecret(password: "slow"),
            delay: .milliseconds(100)
        )
        let env = makeEnvironment(passManager: scripted)
        let state = AppState(
            passManager: scripted,
            selectedEntryID: targetPath
        )
        let model = EntryListModel(environment: env, state: state)

        XCTAssertEqual(model.deletionState, .idle)

        // Spawn the delete on a child task so we can observe the
        // mid-flight state.
        let task = Task { await model.deleteEntry(at: targetPath) }

        // Yield repeatedly until the model has flipped to `.deleting`
        // (the actual flip happens on the very first MainActor hop
        // inside `deleteEntry(at:)`).
        var observedDeleting = false
        let start = ContinuousClock().now
        while ContinuousClock().now - start < .milliseconds(200) {
            await Task.yield()
            if model.deletionState == .deleting {
                observedDeleting = true
                break
            }
        }
        XCTAssertTrue(observedDeleting, "deletionState never observed as .deleting")

        await task.value

        XCTAssertEqual(model.deletionState, .idle)
    }

    // MARK: - Re-entrant delete is a no-op

    func testDeleteEntry_calledTwiceInQuickSuccession_runsOnlyOnce() async throws {
        let scripted = SlowDeletePassManager(
            secret: makeSecret(password: "once"),
            delay: .milliseconds(80)
        )
        let env = makeEnvironment(passManager: scripted)
        let state = AppState(
            passManager: scripted,
            selectedEntryID: targetPath
        )
        let model = EntryListModel(environment: env, state: state)

        let first = Task { await model.deleteEntry(at: targetPath) }

        // Wait for the model to enter `.deleting`.
        let start = ContinuousClock().now
        while model.deletionState != .deleting,
              ContinuousClock().now - start < .milliseconds(200) {
            await Task.yield()
        }
        XCTAssertEqual(model.deletionState, .deleting)

        // Second call — should early-return because we are not idle.
        await model.deleteEntry(at: targetPath)

        // Wait for the first call to complete.
        await first.value
        XCTAssertEqual(model.deletionState, .idle)

        // Manager-side: exactly one `remove` invocation.
        let count = await scripted.removeCallCount
        XCTAssertEqual(count, 1)
    }

    // MARK: - Expired Undo is a no-op

    func testUndo_afterExpiry_doesNotRestoreEntry() async throws {
        let secret = makeSecret(password: "expired-undo")
        let (model, state, manager) = makeModelAndState(
            seedSecrets: [targetPath: secret],
            select: targetPath
        )

        await model.deleteEntry(at: targetPath)

        // The model recorded with the standard 10s window. For this
        // test we replace it with a very short window so the assertion
        // can run quickly; `record(_:expiresAfter:)` is idempotent —
        // it cancels the prior expiry timer and installs a fresh one.
        guard let pending = state.actionHistory.pending else {
            return XCTFail("expected pending undo action")
        }
        state.actionHistory.record(
            pending.action,
            expiresAfter: .milliseconds(50)
        )

        // Wait past the new expiry.
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertNil(state.actionHistory.pending)

        // Calling `undoLast()` after expiry must be a no-op — the
        // store stays without the deleted entry.
        try await state.actionHistory.undoLast()
        let listed = try await manager.listEntries().map(\.path)
        XCTAssertFalse(listed.contains(targetPath))
    }
}

// MARK: - Test fakes

/// Throws a single scripted `PassError` from `show`, asserts via
/// `XCTFail` if `remove` is ever called (the delete pipeline must
/// abort BEFORE invoking `remove` when `show` fails).
private actor ShowFailingPassManager: PassManaging {

    private let error: PassError
    private(set) var removeCallCount: Int = 0

    init(error: PassError) {
        self.error = error
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw error
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-show-failing")
    }
    func remove(_ entry: PassEntry) async throws {
        removeCallCount += 1
        XCTFail("ShowFailingPassManager.remove must never be called when show fails.")
    }
    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// `show` returns a fixed secret, `remove` throws a scripted
/// `PassError`. Used to drive the "remove failure leaves store
/// unchanged" path — the manager throws BEFORE actually mutating
/// any state.
private actor RemoveFailingPassManager: PassManaging {

    private let secret: PassSecret
    private let removeError: PassError

    init(secret: PassSecret, removeError: PassError) {
        self.secret = secret
        self.removeError = removeError
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        return secret
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-remove-failing")
    }
    func remove(_ entry: PassEntry) async throws {
        throw removeError
    }
    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// `show` returns a fixed secret instantly; `remove` sleeps `delay`
/// before completing successfully. Used to land assertions on the
/// in-flight `deletionState == .deleting` window and to gate the
/// re-entrant no-op test.
private actor SlowDeletePassManager: PassManaging {

    private let secret: PassSecret
    private let delay: Duration
    private(set) var removeCallCount: Int = 0

    init(secret: PassSecret, delay: Duration) {
        self.secret = secret
        self.delay = delay
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        return secret
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-slow-delete")
    }
    func remove(_ entry: PassEntry) async throws {
        removeCallCount += 1
        try await Task.sleep(for: delay)
    }
    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// No-op `ClipboardServicing` reused across the Phase G tests. Local
/// here to avoid pulling the existing copy from
/// `EntryListReconciliationTests` (which is `private`).
private struct NoopClipboard: ClipboardServicing {
    func copy(_ value: String, clearAfter: Duration) async {}
}

/// No-op `SettingsStoring` for tests that do not exercise persisted
/// preferences.
private struct NoopSettings: SettingsStoring {
    nonisolated func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? { nil }
    nonisolated func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {}
    nonisolated func removeValue(forKey key: String) {}
    nonisolated func resetAll() {}
    nonisolated func registerDefaults(_ defaults: [String : Any]) {}
}
