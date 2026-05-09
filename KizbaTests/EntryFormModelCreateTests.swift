//
//  EntryFormModelCreateTests.swift
//  KizbaTests
//
//  Phase F.2 — `EntryFormModel.create` mode tests. Cover validation
//  surfaces, save happy path, collision handling, force overwrite,
//  non-recoverable errors, generation-counter guarantees, mid-save
//  cancellation, and dismissal cleanup.
//
//  Test fakes:
//
//  - `MockPassManager` (project-shipped) for happy-path / collision /
//    force-overwrite scenarios — its `insert(force:)` already throws
//    `PassError.entryAlreadyExists` on collision and emits the
//    appropriate `StoreChange` events.
//  - Local `ScriptedFailingPassManager` for non-recoverable error
//    scenarios (e.g. `recipientNotFound`) which `MockPassManager`
//    does not produce naturally.
//  - Local `SlowPassManager` that delays `insert` by a configurable
//    amount, used to observe generation-counter ordering and
//    mid-save cancellation.
//
//  All time-dependent assertions use the real clock with generous
//  margins to avoid CI flapping; the longest test sleeps ~300ms.
//

import XCTest
@testable import Kizba

@MainActor
final class EntryFormModelCreateTests: XCTestCase {

    // MARK: - Initial state

    func testInitialState_createMode_isEditingWithEmptyDraft() {
        let appState = AppState()
        let model = makeModel(appState: appState)

        XCTAssertEqual(model.mode, .create)
        XCTAssertEqual(model.state, .editing)
        XCTAssertEqual(model.path, "")
        XCTAssertEqual(model.draft.password, "")
        XCTAssertTrue(model.draft.metadata.isEmpty)
        XCTAssertEqual(model.draft.notes, "")
        XCTAssertFalse(model.forceOverwrite)
    }

    // MARK: - canSave / validation surfaces

    func testCanSave_emptyForm_isFalse() {
        let model = makeModel(appState: AppState())
        XCTAssertFalse(model.canSave)
        XCTAssertNotNil(model.pathError)
        XCTAssertNotNil(model.passwordError)
    }

    func testCanSave_pathValid_passwordEmpty_isFalse() {
        let model = makeModel(appState: AppState())
        model.path = "personal/site"
        XCTAssertNil(model.pathError)
        XCTAssertNotNil(model.passwordError)
        XCTAssertFalse(model.canSave)
    }

    func testCanSave_pathAndPasswordSet_metadataEmpty_isTrue() {
        let model = makeModel(appState: AppState())
        model.path = "personal/site"
        model.draft.password = "p"
        XCTAssertNil(model.pathError)
        XCTAssertNil(model.passwordError)
        XCTAssertNil(model.metadataError)
        XCTAssertTrue(model.canSave)
    }

    func testCanSave_pathWithGpgSuffix_isFalse() {
        let model = makeModel(appState: AppState())
        model.path = "personal/site.gpg"
        model.draft.password = "p"
        XCTAssertNotNil(model.pathError)
        XCTAssertFalse(model.canSave)
    }

    func testCanSave_metadataWithDuplicateKeys_isFalse() {
        let model = makeModel(appState: AppState())
        model.path = "personal/site"
        model.draft.password = "p"
        model.draft.metadata = [
            MetadataPair(key: "user", value: "a"),
            MetadataPair(key: "user", value: "b"),
        ]
        XCTAssertNotNil(model.metadataError)
        XCTAssertFalse(model.canSave)
    }

    // MARK: - Save happy path

    func testSave_newPath_succeeds_postsToast_andSelectsEntry() async {
        let manager = MockPassManager(entries: [], secrets: [:])
        let appState = AppState()
        let model = makeModel(passManager: manager, appState: appState)

        model.path = "newentry"
        model.draft.password = "p"

        model.save()
        // The transition to .saving may or may not be observable
        // depending on scheduling; the canonical assertion is the
        // final .saved state.
        await waitForState(model: model, where: isSaved, timeout: 1.0)

        guard case .saved(let path) = model.state else {
            return XCTFail("expected .saved, got \(model.state)")
        }
        XCTAssertEqual(path, "newentry")

        // MockPassManager now contains the new entry.
        let entries = try? await manager.listEntries()
        XCTAssertEqual(entries?.map(\.path), ["newentry"])

        // Toast posted.
        let toast = appState.toastCenter.visible
        XCTAssertEqual(toast?.severity, .success)
        XCTAssertEqual(toast?.title, "Entry created")
        XCTAssertEqual(toast?.message, "newentry")

        // Selection follows the new entry (Phase F.5 behaviour
        // wired here).
        XCTAssertEqual(appState.selectedEntryID, "newentry")

        // Defensive: forceOverwrite reset to false on success.
        XCTAssertFalse(model.forceOverwrite)
    }

    // MARK: - Save with collision (force = false)

    func testSave_collisionWithoutForce_failsInline_noToast() async {
        let existing = PassEntry(path: "existing/path")
        let manager = MockPassManager(
            entries: [existing],
            secrets: [existing.path: PassSecret(password: "old")]
        )
        let appState = AppState()
        let model = makeModel(passManager: manager, appState: appState)

        model.path = "existing/path"
        model.draft.password = "p"
        model.save()

        await waitForState(model: model, where: isFailed, timeout: 1.0)

        guard case .failed(let error) = model.state else {
            return XCTFail("expected .failed, got \(model.state)")
        }
        XCTAssertEqual(error, .entryAlreadyExists(path: "existing/path"))
        XCTAssertTrue(error.inlineRecoverable)

        // Inline-recoverable errors never post a toast — the form
        // shows a banner with an Overwrite button instead.
        XCTAssertNil(appState.toastCenter.visible)

        // Selection unchanged; entry not overwritten.
        XCTAssertNil(appState.selectedEntryID)
    }

    // MARK: - Save with force overwrite

    func testSave_forceOverwrite_replacesExistingAndPostsToast() async {
        let existing = PassEntry(path: "existing/path")
        let manager = MockPassManager(
            entries: [existing],
            secrets: [existing.path: PassSecret(password: "old")]
        )
        let appState = AppState()
        let model = makeModel(passManager: manager, appState: appState)

        // First attempt — collision.
        model.path = "existing/path"
        model.draft.password = "new-password"
        model.save()
        await waitForState(model: model, where: isFailed, timeout: 1.0)

        // Second attempt — flip the overwrite flag and retry.
        model.forceOverwrite = true
        model.save()
        await waitForState(model: model, where: isSaved, timeout: 1.0)

        guard case .saved(let path) = model.state else {
            return XCTFail("expected .saved, got \(model.state)")
        }
        XCTAssertEqual(path, "existing/path")

        // Verify the body actually changed via the manager's `show`.
        let secret = try? await manager.show(existing)
        XCTAssertEqual(secret?.password, "new-password")

        // Success toast posted (replacing nothing, since collision
        // was inline-only).
        XCTAssertEqual(appState.toastCenter.visible?.severity, .success)
        XCTAssertEqual(appState.toastCenter.visible?.title, "Entry created")

        // forceOverwrite reset on success (defensive).
        XCTAssertFalse(model.forceOverwrite)

        XCTAssertEqual(appState.selectedEntryID, "existing/path")
    }

    // MARK: - Save with non-recoverable error

    func testSave_nonRecoverableError_setsFailed_postsErrorToast() async {
        let manager = ScriptedFailingPassManager(
            error: .recipientNotFound(emailOrKeyId: "alice@x")
        )
        let appState = AppState()
        let model = makeModel(passManager: manager, appState: appState)

        model.path = "newentry"
        model.draft.password = "p"
        model.save()

        await waitForState(model: model, where: isFailed, timeout: 1.0)

        guard case .failed(let error) = model.state else {
            return XCTFail("expected .failed, got \(model.state)")
        }
        XCTAssertEqual(error, .recipientNotFound(emailOrKeyId: "alice@x"))
        XCTAssertFalse(error.inlineRecoverable)

        // Non-inline errors post a danger toast.
        XCTAssertEqual(appState.toastCenter.visible?.severity, .danger)
        XCTAssertEqual(appState.toastCenter.visible?.title, "Save failed")
    }

    // MARK: - Generation counter

    func testGenerationCounter_secondSavePreemptsFirst() async {
        // Slow manager so the first save is in-flight when the
        // second begins.
        let manager = SlowPassManager(delay: .milliseconds(150))
        let appState = AppState()
        let model = makeModel(passManager: manager, appState: appState)

        model.path = "first/path"
        model.draft.password = "p1"
        model.save()

        // Switch the form contents and re-save before the first
        // settles.
        try? await Task.sleep(for: .milliseconds(20))
        model.path = "second/path"
        model.draft.password = "p2"
        model.save()

        await waitForState(model: model, where: isSaved, timeout: 2.0)

        guard case .saved(let path) = model.state else {
            return XCTFail("expected .saved, got \(model.state)")
        }
        // The latest save's outcome must win.
        XCTAssertEqual(path, "second/path")

        // Wait long enough that any stale completion would also have
        // landed by now; state must still be the second save.
        try? await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(model.state, .saved(path: "second/path"))
    }

    // MARK: - Cancellation

    func testCancel_midSave_returnsToEditing_andDropsLateCompletion() async {
        let manager = SlowPassManager(delay: .milliseconds(200))
        let appState = AppState()
        let model = makeModel(passManager: manager, appState: appState)

        model.path = "personal/site"
        model.draft.password = "p"
        model.forceOverwrite = true
        model.save()

        // Cancel while in flight.
        try? await Task.sleep(for: .milliseconds(40))
        XCTAssertEqual(model.state, .saving)
        model.cancel()
        XCTAssertEqual(model.state, .editing)
        XCTAssertFalse(model.forceOverwrite)

        // Wait past the slow insert's natural completion deadline;
        // the cancelled task must NOT transition us back into
        // .saved or .failed.
        try? await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(model.state, .editing)
        XCTAssertNil(appState.toastCenter.visible)
    }

    // MARK: - Dismissal

    func testHandleDismissal_resetsFormAndCancelsSave() async {
        let manager = SlowPassManager(delay: .milliseconds(200))
        let appState = AppState()
        let model = makeModel(passManager: manager, appState: appState)

        model.path = "personal/site"
        model.draft.password = "secret-password"
        model.draft.metadata = [MetadataPair(key: "user", value: "jane")]
        model.draft.notes = "some notes"
        model.forceOverwrite = true

        // Kick off a save so dismissal also exercises the cancel path.
        model.save()
        try? await Task.sleep(for: .milliseconds(40))

        model.handleDismissal()

        XCTAssertEqual(model.path, "")
        XCTAssertEqual(model.draft.password, "")
        XCTAssertTrue(model.draft.metadata.isEmpty)
        XCTAssertEqual(model.draft.notes, "")
        XCTAssertFalse(model.forceOverwrite)
        XCTAssertEqual(model.state, .editing)

        // Late completion from the cancelled save must not fire.
        try? await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(model.state, .editing)
    }

    // MARK: - Validation gates save

    func testSave_withInvalidPath_doesNotInvokeManager_andStaysEditing() async {
        let manager = RecordingInsertPassManager()
        let appState = AppState()
        let model = makeModel(passManager: manager, appState: appState)

        // Missing path; password set so passwordError doesn't mask.
        model.path = ""
        model.draft.password = "p"
        XCTAssertNotNil(model.pathError)

        model.save()
        // Give any (incorrectly) scheduled task a chance to run.
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(model.state, .editing)
        XCTAssertEqual(manager.insertCallCount, 0)
    }

    // MARK: - Helpers

    /// Polls `model.state` on the MainActor until `predicate` matches
    /// or `timeout` seconds elapse. Mirrors the helper in
    /// `EntryDetailModelTests`.
    private func waitForState(
        model: EntryFormModel,
        where predicate: (EntryFormModel.State) -> Bool,
        timeout seconds: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if predicate(model.state) { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTFail(
            "Timed out waiting for state predicate. Last state: \(model.state)",
            file: file,
            line: line
        )
    }

    private func isSaved(_ state: EntryFormModel.State) -> Bool {
        if case .saved = state { return true }
        return false
    }

    private func isFailed(_ state: EntryFormModel.State) -> Bool {
        if case .failed = state { return true }
        return false
    }

    private func makeModel(
        passManager: any PassManaging = MockPassManager(entries: [], secrets: [:]),
        appState: AppState
    ) -> EntryFormModel {
        EntryFormModel(
            mode: .create,
            passManager: passManager,
            toastCenter: appState.toastCenter,
            appState: appState
        )
    }
}

// MARK: - Test fakes

/// Throws a single scripted `PassError` from `insert`. Used to drive
/// the non-recoverable error scenario (`recipientNotFound`) which
/// `MockPassManager` does not produce naturally.
private actor ScriptedFailingPassManager: PassManaging {

    private let error: PassError

    init(error: PassError) {
        self.error = error
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw PassError.decryptionFailed(stderrExcerpt: "n/a")
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-scripted")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        throw error
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// Sleeps `delay` before completing `insert` successfully. Used to
/// observe generation-counter ordering and mid-save cancellation.
private actor SlowPassManager: PassManaging {

    private let delay: Duration

    init(delay: Duration) {
        self.delay = delay
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw PassError.decryptionFailed(stderrExcerpt: "n/a")
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-slow")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        try await Task.sleep(for: delay)
        return entry
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// Counts `insert` invocations without performing any I/O. Used by
/// the validation-gate test to assert that an invalid form does NOT
/// call the manager.
private final class RecordingInsertPassManager: PassManaging, @unchecked Sendable {

    private let lock = NSLock()
    private var _insertCallCount: Int = 0

    var insertCallCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _insertCallCount
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw PassError.decryptionFailed(stderrExcerpt: "n/a")
    }
    func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-recording")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        lock.lock()
        _insertCallCount += 1
        lock.unlock()
        return entry
    }

    var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}
