//
//  ConcurrentWriteLockoutTests.swift
//  KizbaTests
//
//  Phase G.6 — toolbar lockout coverage. Each write model (create,
//  edit, regenerate, move, delete) must:
//
//  1. Mark its op as in flight on `AppState.activeWriteOps` BEFORE
//     suspending on the manager call (so observers see
//     `anyWriteInFlight == true` while the operation is running).
//  2. Release the op on EVERY exit path — success, failure, or
//     cancellation — so the begin/end pair stays balanced.
//
//  These tests exercise the AppState contract directly (Set
//  semantics, idempotence) and then for each of the five write models
//  drive a `slow-fake` scenario that lets the test land assertions
//  while the operation is in flight.
//
//  The "slow-fake" pattern (delay the manager call so the in-flight
//  state is observable from the test) mirrors the Phase F.2 / G.4 /
//  G.5 fakes (`SlowPassManager`, `SlowDeletePassManager`, etc.). Each
//  fake here is local to this file so the duplication stays
//  contained; if Phase H ends up needing the same shape, a shared
//  `Fixtures/SlowPassManager.swift` is the right consolidation.
//

import XCTest
@testable import Kizba

@MainActor
final class ConcurrentWriteLockoutTests: XCTestCase {

    // MARK: - AppState API contract

    func testAppState_initialState_anyWriteInFlightIsFalse_andSetIsEmpty() {
        let state = AppState()
        XCTAssertFalse(state.anyWriteInFlight)
        XCTAssertTrue(state.activeWriteOps.isEmpty)
    }

    func testBeginWrite_isIdempotent_setHoldsOneElement() {
        let state = AppState()
        state.beginWrite(.insertNew)
        state.beginWrite(.insertNew)

        XCTAssertEqual(state.activeWriteOps.count, 1)
        XCTAssertTrue(state.activeWriteOps.contains(.insertNew))
        XCTAssertTrue(state.anyWriteInFlight)
    }

    func testEndWrite_isIdempotent_setRemainsEmpty() {
        let state = AppState()
        state.beginWrite(.delete)
        state.endWrite(.delete)
        state.endWrite(.delete)

        XCTAssertTrue(state.activeWriteOps.isEmpty)
        XCTAssertFalse(state.anyWriteInFlight)
    }

    func testMultipleConcurrentOps_areTrackedIndependently() {
        let state = AppState()

        // Synthetic — the UI prevents this in practice (lockout) but
        // the Set semantics MUST handle two distinct ops cleanly.
        state.beginWrite(.insertNew)
        state.beginWrite(.delete)
        XCTAssertTrue(state.anyWriteInFlight)
        XCTAssertEqual(state.activeWriteOps.count, 2)

        // Releasing one leaves the other in flight.
        state.endWrite(.insertNew)
        XCTAssertTrue(state.anyWriteInFlight)
        XCTAssertEqual(state.activeWriteOps, [.delete])

        // Releasing the second drops the lockout.
        state.endWrite(.delete)
        XCTAssertFalse(state.anyWriteInFlight)
    }

    // MARK: - EntryFormModel(.create)

    func testEntryFormCreate_save_marksInsertNewInFlight_thenReleasesOnSuccess() async {
        let manager = SlowInsertPassManager(delay: .milliseconds(120))
        let state = AppState()
        let model = EntryFormModel(
            mode: .create,
            passManager: manager,
            toastCenter: state.toastCenter,
            appState: state
        )
        model.path = "newentry"
        model.draft.password = "p"

        XCTAssertFalse(state.anyWriteInFlight)

        model.save()

        // While in flight: lockout active and op identifies as insertNew.
        try? await Task.sleep(for: .milliseconds(30))
        XCTAssertTrue(state.anyWriteInFlight)
        XCTAssertTrue(state.activeWriteOps.contains(.insertNew))
        XCTAssertEqual(state.activeWriteOps.count, 1)

        // Wait past the slow insert's natural completion deadline.
        await waitUntil(timeout: 1.0) { !state.anyWriteInFlight }
        XCTAssertFalse(state.anyWriteInFlight)
        XCTAssertTrue(state.activeWriteOps.isEmpty)
    }

    func testEntryFormCreate_save_releasesOpOnFailure() async {
        let manager = ScriptedFailingInsertPassManager(
            error: .recipientNotFound(emailOrKeyId: "alice@x"),
            delay: .milliseconds(80)
        )
        let state = AppState()
        let model = EntryFormModel(
            mode: .create,
            passManager: manager,
            toastCenter: state.toastCenter,
            appState: state
        )
        model.path = "newentry"
        model.draft.password = "p"

        model.save()

        try? await Task.sleep(for: .milliseconds(20))
        XCTAssertTrue(state.anyWriteInFlight)
        XCTAssertTrue(state.activeWriteOps.contains(.insertNew))

        await waitUntil(timeout: 1.0) { !state.anyWriteInFlight }
        XCTAssertFalse(state.anyWriteInFlight)
    }

    func testEntryFormCreate_cancel_releasesLockoutSynchronously() async {
        let manager = SlowInsertPassManager(delay: .milliseconds(300))
        let state = AppState()
        let model = EntryFormModel(
            mode: .create,
            passManager: manager,
            toastCenter: state.toastCenter,
            appState: state
        )
        model.path = "newentry"
        model.draft.password = "p"

        model.save()
        try? await Task.sleep(for: .milliseconds(30))
        XCTAssertTrue(state.anyWriteInFlight)

        model.cancel()
        // Synchronous release: the lockout is gone the moment the
        // user clicks Cancel — they should be able to start a new
        // write right away.
        XCTAssertFalse(state.anyWriteInFlight)

        // And the cancelled task's deferred end MUST NOT
        // double-release (which would be a no-op anyway via Set
        // semantics, but verify the count stays at 0 once the
        // cancelled task fully unwinds).
        try? await Task.sleep(for: .milliseconds(400))
        XCTAssertFalse(state.anyWriteInFlight)
    }

    func testEntryFormCreate_handleDismissal_releasesLockoutSynchronously() async {
        let manager = SlowInsertPassManager(delay: .milliseconds(300))
        let state = AppState()
        let model = EntryFormModel(
            mode: .create,
            passManager: manager,
            toastCenter: state.toastCenter,
            appState: state
        )
        model.path = "newentry"
        model.draft.password = "p"

        model.save()
        try? await Task.sleep(for: .milliseconds(30))
        XCTAssertTrue(state.anyWriteInFlight)

        model.handleDismissal()
        XCTAssertFalse(state.anyWriteInFlight)
    }

    // MARK: - EntryFormModel(.edit)

    func testEntryFormEdit_save_marksEditInFlight() async {
        let entry = PassEntry(path: "personal/email/gmail")
        let initialSecret = PassSecret(password: "old")
        let manager = SlowEditPassManager(
            entry: entry,
            initialSecret: initialSecret,
            insertDelay: .milliseconds(120)
        )
        let state = AppState()
        let model = EntryFormModel(
            mode: .edit(originalPath: entry.path),
            passManager: manager,
            toastCenter: state.toastCenter,
            appState: state
        )

        // Wait for the initial `.show` to complete (load phase).
        await waitUntilEditing(model: model, timeout: 1.0)
        XCTAssertEqual(model.state, .editing)
        XCTAssertFalse(state.anyWriteInFlight, "load is not a write op")

        model.draft.password = "new"
        model.save()

        try? await Task.sleep(for: .milliseconds(30))
        XCTAssertTrue(state.anyWriteInFlight)
        XCTAssertTrue(
            state.activeWriteOps.contains(.edit),
            "edit save should map to .edit (not .insertNew); got \(state.activeWriteOps)"
        )

        await waitUntil(timeout: 1.0) { !state.anyWriteInFlight }
        XCTAssertFalse(state.anyWriteInFlight)
    }

    // MARK: - RegenerateInPlaceModel

    func testRegenerateInPlace_marksRegenerateInFlight_thenReleasesOnSuccess() async {
        let entry = PassEntry(path: "personal/site")
        let priorSecret = PassSecret(password: "prior")
        let manager = SlowRegeneratePassManager(
            entry: entry,
            priorSecret: priorSecret,
            generateDelay: .milliseconds(120)
        )
        let state = AppState()
        let model = RegenerateInPlaceModel(
            entry: entry,
            passManager: manager,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )

        let task = Task { await model.regenerate() }

        // While in flight: lockout active and op identifies as regenerate.
        try? await Task.sleep(for: .milliseconds(30))
        XCTAssertTrue(state.anyWriteInFlight)
        XCTAssertTrue(state.activeWriteOps.contains(.regenerate))

        await task.value
        XCTAssertFalse(state.anyWriteInFlight)
    }

    func testRegenerateInPlace_releasesOpOnShowFailure() async {
        // `show` failure aborts the rotation outright. The op must
        // still be released on the early-return path.
        let entry = PassEntry(path: "personal/site")
        let manager = ShowFailingRegeneratePassManager(
            error: .decryptionFailed(stderrExcerpt: "no key")
        )
        let state = AppState()
        let model = RegenerateInPlaceModel(
            entry: entry,
            passManager: manager,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )

        await model.regenerate()
        XCTAssertFalse(state.anyWriteInFlight)
    }

    // MARK: - MoveEntryModel

    func testMoveEntry_save_marksMoveInFlight_thenReleasesOnSuccess() async {
        let original = PassEntry(path: "old/path")
        let manager = SlowMovePassManager(delay: .milliseconds(120))
        let state = AppState()
        let model = MoveEntryModel(
            originalEntry: original,
            passManager: manager,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
        model.newPath = "new/path"

        model.save()

        try? await Task.sleep(for: .milliseconds(30))
        XCTAssertTrue(state.anyWriteInFlight)
        XCTAssertTrue(state.activeWriteOps.contains(.move))

        await waitUntil(timeout: 1.0) { !state.anyWriteInFlight }
        XCTAssertFalse(state.anyWriteInFlight)
    }

    func testMoveEntry_cancel_releasesLockoutSynchronously() async {
        let original = PassEntry(path: "old/path")
        let manager = SlowMovePassManager(delay: .milliseconds(300))
        let state = AppState()
        let model = MoveEntryModel(
            originalEntry: original,
            passManager: manager,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
        model.newPath = "new/path"

        model.save()
        try? await Task.sleep(for: .milliseconds(30))
        XCTAssertTrue(state.anyWriteInFlight)

        model.cancel()
        XCTAssertFalse(state.anyWriteInFlight)

        // Cancelled task must not double-release.
        try? await Task.sleep(for: .milliseconds(400))
        XCTAssertFalse(state.anyWriteInFlight)
    }

    // MARK: - EntryListModel.deleteEntry

    func testDeleteEntry_marksDeleteInFlight_thenReleasesOnSuccess() async {
        let path = "personal/email/gmail"
        let secret = PassSecret(password: "doomed")
        let manager = SlowDeleteByOpPassManager(
            secret: secret,
            removeDelay: .milliseconds(120)
        )
        let env = AppEnvironment(
            passManager: manager,
            clipboard: NoopClipboardForLockoutTest(),
            settings: NoopSettingsForLockoutTest(),
            passwordGenerator: LivePasswordGenerator(),
            passCLI: nil,
            discovery: nil
        )
        let state = AppState(passManager: manager, selectedEntryID: path)
        let model = EntryListModel(environment: env, state: state)

        let task = Task { await model.deleteEntry(at: path) }

        // While in flight: lockout active and op identifies as delete.
        try? await Task.sleep(for: .milliseconds(40))
        XCTAssertTrue(state.anyWriteInFlight)
        XCTAssertTrue(state.activeWriteOps.contains(.delete))

        await task.value
        XCTAssertFalse(state.anyWriteInFlight)
    }

    // MARK: - canSave still functions under the lockout

    func testEntryFormCreate_canSave_unaffectedByExternalOpInFlight() {
        // The lockout disables the BUTTON via `appState.anyWriteInFlight`
        // at the toolbar / menu site. The model's own `canSave` is
        // gated only on its own `.saving` state — verify a foreign
        // op (e.g. a delete in flight) does NOT silently break the
        // model's gate.
        let state = AppState()
        state.beginWrite(.delete)

        let model = EntryFormModel(
            mode: .create,
            passManager: MockPassManager(entries: [], secrets: [:]),
            toastCenter: state.toastCenter,
            appState: state
        )
        model.path = "personal/site"
        model.draft.password = "p"

        // The model's gate is still satisfied — the global lockout
        // is the toolbar's responsibility, not the model's.
        XCTAssertTrue(model.canSave)
        XCTAssertTrue(state.anyWriteInFlight)
    }

    // MARK: - Helpers

    private func waitUntil(
        timeout seconds: TimeInterval,
        predicate: @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        // Disambiguate to the module-level helper
        await KizbaTests.waitUntil(timeout: seconds, file: file, line: line, predicate)
    }

    private func waitUntilEditing(
        model: EntryFormModel,
        timeout seconds: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if model.state == .editing { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail(
            "Timed out waiting for .editing; last state \(model.state)",
            file: file,
            line: line
        )
    }
}

// MARK: - Test fakes

/// Sleeps `delay` before completing `insert` successfully.
private actor SlowInsertPassManager: PassManaging {

    private let delay: Duration

    init(delay: Duration) {
        self.delay = delay
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw PassError.decryptionFailed(stderrExcerpt: "n/a")
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-lockout-slow-insert")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        try await Task.sleep(for: delay)
        return entry
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// Sleeps `delay` then throws a scripted `PassError` from `insert`.
private actor ScriptedFailingInsertPassManager: PassManaging {

    private let error: PassError
    private let delay: Duration

    init(error: PassError, delay: Duration) {
        self.error = error
        self.delay = delay
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw PassError.decryptionFailed(stderrExcerpt: "n/a")
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-lockout-failing-insert")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        try await Task.sleep(for: delay)
        throw error
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// Loads a fixed initial secret immediately, then sleeps `insertDelay`
/// inside each `insert`. Used for the `.edit` mode lockout test.
private actor SlowEditPassManager: PassManaging {

    private let entry: PassEntry
    private let initialSecret: PassSecret
    private let insertDelay: Duration

    init(entry: PassEntry, initialSecret: PassSecret, insertDelay: Duration) {
        self.entry = entry
        self.initialSecret = initialSecret
        self.insertDelay = insertDelay
    }

    func listEntries() async throws -> [PassEntry] { [entry] }
    func show(_ e: PassEntry) async throws -> PassSecret {
        guard e.path == entry.path else {
            throw PassError.sourceNotFound(path: e.path)
        }
        return initialSecret
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-lockout-slow-edit")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        try await Task.sleep(for: insertDelay)
        return entry
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// `show` returns a fixed prior secret instantly; `generateInPlace`
/// sleeps `generateDelay` before completing successfully.
private actor SlowRegeneratePassManager: PassManaging {

    private let entry: PassEntry
    private let priorSecret: PassSecret
    private let generateDelay: Duration

    init(entry: PassEntry, priorSecret: PassSecret, generateDelay: Duration) {
        self.entry = entry
        self.priorSecret = priorSecret
        self.generateDelay = generateDelay
    }

    func listEntries() async throws -> [PassEntry] { [entry] }
    func show(_ e: PassEntry) async throws -> PassSecret {
        return priorSecret
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-lockout-slow-regen")
    }

    func generateInPlace(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool
    ) async throws -> PassSecret {
        try await Task.sleep(for: generateDelay)
        return PassSecret(password: "GEN")
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// `show` throws the scripted error; `generateInPlace` is never
/// invoked. Used to verify the lockout is released even when the
/// rotation aborts on the pre-show.
private actor ShowFailingRegeneratePassManager: PassManaging {

    private let error: PassError

    init(error: PassError) {
        self.error = error
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw error
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-lockout-show-fail-regen")
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// Sleeps `delay` before completing `move` successfully.
private actor SlowMovePassManager: PassManaging {

    private let delay: Duration

    init(delay: Duration) {
        self.delay = delay
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw PassError.decryptionFailed(stderrExcerpt: "n/a")
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-lockout-slow-move")
    }

    func move(from: PassEntry, to newPath: String, force: Bool) async throws -> PassEntry {
        try await Task.sleep(for: delay)
        return PassEntry(path: newPath)
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// `show` returns a fixed secret instantly; `remove` sleeps
/// `removeDelay` before completing successfully. Mirrors the shape of
/// `SlowDeletePassManager` from G.5's tests but is local to this file
/// to avoid cross-file dependency on a `private` type.
private actor SlowDeleteByOpPassManager: PassManaging {

    private let secret: PassSecret
    private let removeDelay: Duration

    init(secret: PassSecret, removeDelay: Duration) {
        self.secret = secret
        self.removeDelay = removeDelay
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        return secret
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-lockout-slow-delete")
    }
    func remove(_ entry: PassEntry) async throws {
        try await Task.sleep(for: removeDelay)
    }
    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// No-op `ClipboardServicing` reused across the lockout tests.
private struct NoopClipboardForLockoutTest: ClipboardServicing {
    func copy(_ value: String, clearAfter: Duration) async {}
}

/// No-op `SettingsStoring` for tests that do not exercise persisted
/// preferences.
private struct NoopSettingsForLockoutTest: SettingsStoring {
    nonisolated func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? { nil }
    nonisolated func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {}
    nonisolated func removeValue(forKey key: String) {}
    nonisolated func resetAll() {}
    nonisolated func registerDefaults(_ defaults: [String : Any]) {}
}
