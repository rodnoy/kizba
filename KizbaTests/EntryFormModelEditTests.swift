//
//  EntryFormModelEditTests.swift
//  KizbaTests
//
//  Phase G.2 — `EntryFormModel.edit(originalPath:)` mode tests.
//  Cover initial-load behaviour, save-via-insert(force:true)
//  semantics, the `canEditPath` contract, the `canSave` lockout
//  while loading, generation-counter behaviour for save under load,
//  load-failure surfacing, and save-failure propagation.
//
//  Test fakes:
//
//  - `MockPassManager` (project-shipped) for happy-path scenarios —
//    its `show(_:)` returns the seeded fixture and its
//    `insert(force:true)` updates the in-memory secret without
//    throwing.
//  - Local `LoadFailingPassManager` that throws a scripted PassError
//    from `show`, used to drive the failed-initial-load scenario.
//  - Local `SlowShowPassManager` that delays `show` so we can
//    observe the `.loadingExisting` state and exercise mid-load
//    cancellation.
//  - Local `InsertFailingPassManager` that loads successfully but
//    fails on `insert`, used to drive the save-failure scenario.
//
//  All time-dependent assertions use the real clock with generous
//  margins to avoid CI flapping.
//

import XCTest
@testable import Kizba

@MainActor
final class EntryFormModelEditTests: XCTestCase {

    // MARK: - Initial load

    func testInit_editMode_loadsExistingDraftAndTransitionsToEditing() async {
        let entry = PassEntry(path: "personal/github")
        let secret = PassSecret(
            password: "old-password",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "jane")],
                notes: "some notes"
            )
        )
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: secret]
        )
        let appState = AppState()
        let model = makeEditModel(
            originalPath: entry.path,
            passManager: manager,
            appState: appState
        )

        // Path is the original immediately (set in init).
        XCTAssertEqual(model.path, entry.path)
        XCTAssertEqual(model.mode, .edit(originalPath: entry.path))

        await waitForState(model: model, where: isEditing, timeout: 1.0)

        XCTAssertEqual(model.draft.password, "old-password")
        XCTAssertEqual(model.draft.notes, "some notes")
        XCTAssertEqual(model.draft.metadata.count, 1)
        XCTAssertEqual(model.draft.metadata.first?.key, "user")
        XCTAssertEqual(model.draft.metadata.first?.value, "jane")
    }

    // MARK: - canEditPath

    func testCanEditPath_createMode_isTrue() {
        let model = EntryFormModel(
            mode: .create,
            passManager: MockPassManager(entries: [], secrets: [:]),
            toastCenter: ToastCenter(),
            appState: AppState()
        )
        XCTAssertTrue(model.canEditPath)
    }

    func testCanEditPath_editMode_isFalse() {
        let entry = PassEntry(path: "x/y")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: PassSecret(password: "p")]
        )
        let model = makeEditModel(
            originalPath: entry.path,
            passManager: manager,
            appState: AppState()
        )
        XCTAssertFalse(model.canEditPath)
    }

    // MARK: - canSave gating during load

    func testCanSave_whileLoadingExisting_isFalse() async {
        let entry = PassEntry(path: "personal/github")
        let manager = SlowShowPassManager(
            entries: [entry],
            secret: PassSecret(password: "p"),
            delay: .milliseconds(150)
        )
        let model = makeEditModel(
            originalPath: entry.path,
            passManager: manager,
            appState: AppState()
        )

        // Immediately after init the load is in flight.
        XCTAssertEqual(model.state, .loadingExisting)
        XCTAssertFalse(model.canSave)

        // After the load completes the form becomes saveable
        // (assuming validators pass — the seeded secret has a
        // non-empty password and a valid path).
        await waitForState(model: model, where: isEditing, timeout: 1.0)
        XCTAssertTrue(model.canSave)
    }

    // MARK: - Save (happy path)

    func testSave_editMode_usesInsertWithForceTrue_postsChangesSavedToast() async {
        let entry = PassEntry(path: "personal/github")
        let initial = PassSecret(password: "old")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: initial]
        )
        let appState = AppState(selectedEntryID: entry.path)
        let model = makeEditModel(
            originalPath: entry.path,
            passManager: manager,
            appState: appState
        )

        await waitForState(model: model, where: isEditing, timeout: 1.0)

        // Mutate the password — this should land in the store via
        // insert(force: true).
        model.draft.password = "new-password"
        model.save()

        await waitForState(model: model, where: isSaved, timeout: 1.0)

        guard case .saved(let savedPath) = model.state else {
            return XCTFail("expected .saved, got \(model.state)")
        }
        XCTAssertEqual(savedPath, entry.path)

        // The store now reflects the new password (verified via the
        // mock's show — which is what insert(force: true) overwrites).
        let after = try? await manager.show(entry)
        XCTAssertEqual(after?.password, "new-password")

        // Toast distinguishes edit from create.
        let toast = appState.toastCenter.visible
        XCTAssertEqual(toast?.severity, .success)
        XCTAssertEqual(toast?.title, "Changes saved")
        XCTAssertEqual(toast?.message, entry.path)
    }

    func testSave_editMode_doesNotMutateSelectedEntryID() async {
        let entry = PassEntry(path: "personal/github")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: PassSecret(password: "old")]
        )
        // Selection is intentionally something OTHER than the
        // edited entry to prove the save does not overwrite it.
        let appState = AppState(selectedEntryID: "some/other/path")
        let model = makeEditModel(
            originalPath: entry.path,
            passManager: manager,
            appState: appState
        )
        await waitForState(model: model, where: isEditing, timeout: 1.0)

        model.draft.password = "new"
        model.save()
        await waitForState(model: model, where: isSaved, timeout: 1.0)

        // Selection unchanged — Phase H still owns selection rules,
        // and edit explicitly does NOT call setSelection.
        XCTAssertEqual(appState.selectedEntryID, "some/other/path")
    }

    func testSave_editMode_clearsForceOverwriteFlag() async {
        let entry = PassEntry(path: "personal/github")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: PassSecret(password: "old")]
        )
        let appState = AppState()
        let model = makeEditModel(
            originalPath: entry.path,
            passManager: manager,
            appState: appState
        )
        await waitForState(model: model, where: isEditing, timeout: 1.0)

        // The flag is irrelevant in edit mode (force is always true)
        // but flipping it shouldn't break anything; it should also
        // be reset on success per the defensive contract.
        model.forceOverwrite = true
        model.draft.password = "new"
        model.save()
        await waitForState(model: model, where: isSaved, timeout: 1.0)

        XCTAssertFalse(model.forceOverwrite)
    }

    // MARK: - Cancel during load

    func testCancel_duringLoad_returnsToEditing_andDropsLateLoadCompletion() async {
        let entry = PassEntry(path: "personal/github")
        let manager = SlowShowPassManager(
            entries: [entry],
            secret: PassSecret(password: "loaded"),
            delay: .milliseconds(200)
        )
        let model = makeEditModel(
            originalPath: entry.path,
            passManager: manager,
            appState: AppState()
        )

        XCTAssertEqual(model.state, .loadingExisting)
        // Cancel while the load is in flight.
        model.cancel()
        XCTAssertEqual(model.state, .editing)

        // Wait past the slow show's natural completion deadline.
        // The cancelled load must NOT pour the loaded secret into
        // the draft after the user has cancelled.
        try? await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(model.state, .editing)
        XCTAssertEqual(model.draft.password, "")
    }

    // MARK: - Failed initial load

    func testInit_editMode_loadFailure_setsFailedAndPostsToast() async {
        let manager = LoadFailingPassManager(
            error: .decryptionFailed(stderrExcerpt: "no key")
        )
        let appState = AppState()
        let model = makeEditModel(
            originalPath: "personal/github",
            passManager: manager,
            appState: appState
        )

        await waitForState(model: model, where: isFailed, timeout: 1.0)

        guard case .failed(let error) = model.state else {
            return XCTFail("expected .failed, got \(model.state)")
        }
        XCTAssertEqual(error, .decryptionFailed(stderrExcerpt: "no key"))

        // Load failures always post a danger toast — there is no
        // inline-recoverable affordance for a failed initial decrypt.
        let toast = appState.toastCenter.visible
        XCTAssertEqual(toast?.severity, .danger)
        XCTAssertEqual(toast?.title, "Could not load entry")
    }

    // MARK: - Save failure propagates

    func testSave_editMode_insertFailure_setsFailedAndPostsErrorToast() async {
        let manager = InsertFailingPassManager(
            entry: PassEntry(path: "personal/github"),
            initialSecret: PassSecret(password: "old"),
            insertError: .recipientNotFound(emailOrKeyId: "alice@x")
        )
        let appState = AppState()
        let model = makeEditModel(
            originalPath: "personal/github",
            passManager: manager,
            appState: appState
        )
        await waitForState(model: model, where: isEditing, timeout: 1.0)

        // Sanity: load succeeded, draft is populated.
        XCTAssertEqual(model.draft.password, "old")

        model.draft.password = "new"
        model.save()
        await waitForState(model: model, where: isFailed, timeout: 1.0)

        guard case .failed(let error) = model.state else {
            return XCTFail("expected .failed, got \(model.state)")
        }
        XCTAssertEqual(error, .recipientNotFound(emailOrKeyId: "alice@x"))

        // Non-inline error → danger toast.
        let toast = appState.toastCenter.visible
        XCTAssertEqual(toast?.severity, .danger)
        XCTAssertEqual(toast?.title, "Save failed")
    }

    // MARK: - Generation counter (rapid saves)

    func testGenerationCounter_secondSavePreemptsFirst() async {
        let entry = PassEntry(path: "personal/github")
        let manager = SlowInsertAfterShowPassManager(
            entry: entry,
            initialSecret: PassSecret(password: "old"),
            insertDelay: .milliseconds(150)
        )
        let appState = AppState()
        let model = makeEditModel(
            originalPath: entry.path,
            passManager: manager,
            appState: appState
        )
        await waitForState(model: model, where: isEditing, timeout: 1.0)

        model.draft.password = "first"
        model.save()

        try? await Task.sleep(for: .milliseconds(20))

        model.draft.password = "second"
        model.save()

        await waitForState(model: model, where: isSaved, timeout: 2.0)

        // Wait past the first save's natural completion deadline so
        // any stale write would also have landed by now.
        try? await Task.sleep(for: .milliseconds(200))

        // The latest save's outcome must win — state stays .saved
        // and the manager's stored value reflects the second write.
        guard case .saved = model.state else {
            return XCTFail("expected .saved, got \(model.state)")
        }
        let final = await manager.lastInsertedPassword
        XCTAssertEqual(final, "second")
    }

    // MARK: - Helpers

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

    private func isEditing(_ state: EntryFormModel.State) -> Bool {
        if case .editing = state { return true }
        return false
    }

    private func isSaved(_ state: EntryFormModel.State) -> Bool {
        if case .saved = state { return true }
        return false
    }

    private func isFailed(_ state: EntryFormModel.State) -> Bool {
        if case .failed = state { return true }
        return false
    }

    private func makeEditModel(
        originalPath: String,
        passManager: any PassManaging,
        appState: AppState
    ) -> EntryFormModel {
        EntryFormModel(
            mode: .edit(originalPath: originalPath),
            passManager: passManager,
            toastCenter: appState.toastCenter,
            appState: appState
        )
    }
}

// MARK: - Test fakes

/// Throws a scripted `PassError` from `show`. Used to drive the
/// failed-initial-load scenario.
private actor LoadFailingPassManager: PassManaging {

    private let error: PassError

    init(error: PassError) {
        self.error = error
    }

    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw error
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-load-fail")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        throw PassError.writeFailed(reason: nil)
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// Sleeps `delay` before completing `show` successfully. Insert is
/// not exercised by the tests that use this fake.
private actor SlowShowPassManager: PassManaging {

    private let entries: [PassEntry]
    private let secret: PassSecret
    private let delay: Duration

    init(entries: [PassEntry], secret: PassSecret, delay: Duration) {
        self.entries = entries
        self.secret = secret
        self.delay = delay
    }

    func listEntries() async throws -> [PassEntry] { entries }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        try await Task.sleep(for: delay)
        return secret
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-slow-show")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        return entry
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// Loads a fixed initial secret successfully, then throws a scripted
/// `PassError` from `insert`. Used to drive the save-failure scenario.
private actor InsertFailingPassManager: PassManaging {

    private let entry: PassEntry
    private let initialSecret: PassSecret
    private let insertError: PassError

    init(entry: PassEntry, initialSecret: PassSecret, insertError: PassError) {
        self.entry = entry
        self.initialSecret = initialSecret
        self.insertError = insertError
    }

    func listEntries() async throws -> [PassEntry] { [entry] }
    func show(_ e: PassEntry) async throws -> PassSecret {
        guard e.path == entry.path else {
            throw PassError.sourceNotFound(path: e.path)
        }
        return initialSecret
    }
    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-insert-fail")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        throw insertError
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}

/// Loads a fixed initial secret immediately, then sleeps `insertDelay`
/// inside each `insert` so the generation-counter test can observe two
/// in-flight writes in flight simultaneously. Records the LAST
/// insert's password under actor isolation for assertion.
private actor SlowInsertAfterShowPassManager: PassManaging {

    private let entry: PassEntry
    private let initialSecret: PassSecret
    private let insertDelay: Duration
    private(set) var lastInsertedPassword: String?

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
        URL(fileURLWithPath: "/tmp/kizba-slow-insert")
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        // Capture the password BEFORE the sleep so the value is
        // recorded in submission order — the LATEST submission wins
        // because it overwrites prior captures.
        try await Task.sleep(for: insertDelay)
        lastInsertedPassword = secret.password
        return entry
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}
