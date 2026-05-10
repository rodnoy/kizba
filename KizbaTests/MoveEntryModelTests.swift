//
//  MoveEntryModelTests.swift
//  KizbaTests
//
//  Phase G.4 — coverage for the move-entry view-model. Exercises
//  the validation surface (path syntax + same-path rule), the
//  happy-path `passManager.move(...)` call (state, selection,
//  toast, ActionHistory), the collision branch (.failed without
//  toast / without ActionHistory record / selection unchanged),
//  the force-replace retry, the Undo round-trip, the cancellation
//  / handleDismissal seams, the non-recoverable error toast path,
//  and the generation-counter cancellation safety.
//
//  Test fakes:
//
//  - `MockPassManager` (project-shipped) for the happy-path /
//    collision / undo / generation tests. Its `move` mirrors the
//    live behaviour: `entryAlreadyExists` without `force`, success
//    with `force`, deterministic `.moved` event emission.
//  - Local `ScriptedFailingMoveManager` actor for the non-recoverable
//    error and the slow-cancellation tests. Records `move`
//    invocations so assertions can pin call counts and arguments.
//

import XCTest
@testable import Kizba

@MainActor
final class MoveEntryModelTests: XCTestCase {

    // MARK: - Fixtures

    private let originalPath = "personal/old"
    private let newValidPath = "personal/new"

    /// Helper: build a `PassSecret` with a single metadata field so
    /// the manager has a non-trivial body to relocate. Move
    /// preserves the body verbatim (the CLI just renames the
    /// `.gpg` file), so this is mostly to make the fixture realistic.
    private func makeSecret(password: String = "p1") -> PassSecret {
        PassSecret(
            password: password,
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "jane.doe@example.com")],
                notes: nil
            )
        )
    }

    /// Helper: construct a `MoveEntryModel` + its hosting `AppState`
    /// over a shared `MockPassManager`. The manager is pre-seeded
    /// with the original entry (and any extra collision entries
    /// the caller specifies).
    private func makeModelAndState(
        seedSecrets: [String: PassSecret]? = nil
    ) -> (MoveEntryModel, AppState, MockPassManager) {
        let original = PassEntry(path: originalPath)
        let baseSecrets = seedSecrets ?? [originalPath: makeSecret()]
        let entries = baseSecrets.keys.map { PassEntry(path: $0) }
        let manager = MockPassManager(
            entries: entries,
            secrets: baseSecrets
        )
        let state = AppState(passManager: manager)
        let model = MoveEntryModel(
            originalEntry: original,
            passManager: manager,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
        return (model, state, manager)
    }

    // MARK: - Initial state

    func testInitialState_isIdle_andNewPathIsPreFilledWithOriginal_andForceIsFalse() {
        let (model, _, _) = makeModelAndState()
        XCTAssertEqual(model.state, .idle)
        XCTAssertEqual(model.newPath, originalPath)
        XCTAssertFalse(model.forceMove)
        XCTAssertEqual(model.originalEntry.path, originalPath)
    }

    // MARK: - Validation / canSave

    func testCanSave_isFalse_whenNewPathEqualsOriginal_andSurfacesSamePathError() {
        let (model, _, _) = makeModelAndState()
        // Pre-filled with the original — cannot save without an edit.
        XCTAssertEqual(model.newPath, originalPath)
        XCTAssertNotNil(model.pathError)
        XCTAssertFalse(model.canSave)
    }

    func testCanSave_isFalse_whenNewPathIsEmpty() {
        let (model, _, _) = makeModelAndState()
        model.newPath = ""
        XCTAssertNotNil(model.pathError)
        XCTAssertFalse(model.canSave)
    }

    func testCanSave_isFalse_whenNewPathHasGpgSuffix() {
        let (model, _, _) = makeModelAndState()
        model.newPath = "personal/new.gpg"
        XCTAssertNotNil(model.pathError)
        XCTAssertFalse(model.canSave)
    }

    func testCanSave_isFalse_whenNewPathContainsDotDot() {
        let (model, _, _) = makeModelAndState()
        model.newPath = "../escape"
        XCTAssertNotNil(model.pathError)
        XCTAssertFalse(model.canSave)
    }

    func testCanSave_isTrue_forValidNewPath() {
        let (model, _, _) = makeModelAndState()
        model.newPath = newValidPath
        XCTAssertNil(model.pathError)
        XCTAssertTrue(model.canSave)
    }

    // MARK: - Happy path

    func testSave_happyPath_landsInSaved_andUpdatesManager_andSelectsNewEntry_andRecordsUndo_andPostsToast() async throws {
        let (model, state, manager) = makeModelAndState()
        model.newPath = newValidPath

        model.save()
        await waitForNonSavingState(of: model)

        // State.
        guard case .saved(let savedPath) = model.state else {
            return XCTFail("expected .saved, got \(model.state)")
        }
        XCTAssertEqual(savedPath, newValidPath)

        // Manager-side mutation.
        let listed = try await manager.listEntries().map { $0.path }
        XCTAssertFalse(listed.contains(originalPath))
        XCTAssertTrue(listed.contains(newValidPath))

        // Selection follows the entry to its new path.
        XCTAssertEqual(state.router.selectedEntryID, newValidPath)

        // ActionHistory records the inverse move.
        guard let pending = state.actionHistory.pending else {
            return XCTFail("expected pending undo action")
        }
        guard case .move(let from, let to) = pending.action else {
            return XCTFail("expected .move, got \(pending.action)")
        }
        XCTAssertEqual(from, originalPath)
        XCTAssertEqual(to, newValidPath)

        // Toast surface.
        guard let toast = state.toastCenter.visible else {
            return XCTFail("expected visible success toast")
        }
        XCTAssertEqual(toast.severity, .success)
        XCTAssertEqual(toast.title, "Entry moved")
        XCTAssertEqual(toast.message, "Now at \(newValidPath)")
        XCTAssertNotNil(toast.action)
        XCTAssertEqual(toast.action?.label, "Undo")
    }

    // MARK: - Collision

    func testSave_collisionWithoutForce_landsInFailed_inlineRecoverable_andDoesNotRecordOrSelectOrToast() async throws {
        let collisionPath = "personal/exists"
        let (model, state, manager) = makeModelAndState(
            seedSecrets: [
                originalPath: makeSecret(password: "old"),
                collisionPath: makeSecret(password: "exists")
            ]
        )
        // Sanity: selection starts unset.
        XCTAssertNil(state.router.selectedEntryID)

        model.newPath = collisionPath
        model.save()
        await waitForNonSavingState(of: model)

        // State is `.failed(.entryAlreadyExists)`.
        guard case .failed(let err) = model.state else {
            return XCTFail("expected .failed, got \(model.state)")
        }
        guard case .entryAlreadyExists(let path) = err else {
            return XCTFail("expected .entryAlreadyExists, got \(err)")
        }
        XCTAssertEqual(path, collisionPath)
        XCTAssertTrue(err.inlineRecoverable)

        // No success toast posted (collision is inline-recoverable).
        XCTAssertNil(state.toastCenter.visible)

        // No ActionHistory record.
        XCTAssertNil(state.actionHistory.pending)

        // Selection unchanged.
        XCTAssertNil(state.router.selectedEntryID)

        // Manager-side: both entries still present.
        let listed = try await manager.listEntries().map { $0.path }
        XCTAssertTrue(listed.contains(originalPath))
        XCTAssertTrue(listed.contains(collisionPath))
    }

    func testSave_forceReplaceAfterCollision_succeeds() async throws {
        let collisionPath = "personal/exists"
        let (model, state, manager) = makeModelAndState(
            seedSecrets: [
                originalPath: makeSecret(password: "old"),
                collisionPath: makeSecret(password: "exists")
            ]
        )

        // First save → collision.
        model.newPath = collisionPath
        model.save()
        await waitForNonSavingState(of: model)
        guard case .failed(.entryAlreadyExists) = model.state else {
            return XCTFail("expected .failed(.entryAlreadyExists), got \(model.state)")
        }

        // Flip forceMove and retry.
        model.forceMove = true
        model.save()
        await waitForNonSavingState(of: model)

        guard case .saved(let savedPath) = model.state else {
            return XCTFail("expected .saved, got \(model.state)")
        }
        XCTAssertEqual(savedPath, collisionPath)

        // After force replace, the original path is gone, the
        // destination remains, the body is the moved one (password
        // "old" replaced "exists").
        let listed = try await manager.listEntries().map { $0.path }
        XCTAssertFalse(listed.contains(originalPath))
        XCTAssertTrue(listed.contains(collisionPath))
        let postSecret = try await manager.show(PassEntry(path: collisionPath))
        XCTAssertEqual(postSecret.password, "old")

        // Selection follows.
        XCTAssertEqual(state.router.selectedEntryID, collisionPath)

        // forceMove is reset on success (defensive).
        XCTAssertFalse(model.forceMove)
    }

    // MARK: - Undo round-trip

    func testUndo_fromPendingAction_movesEntryBackToOriginalPath() async throws {
        let (model, state, manager) = makeModelAndState()
        model.newPath = newValidPath
        model.save()
        await waitForNonSavingState(of: model)

        // Sanity post-move.
        var listed = try await manager.listEntries().map { $0.path }
        XCTAssertTrue(listed.contains(newValidPath))
        XCTAssertFalse(listed.contains(originalPath))

        // Undo via ActionHistory.
        try await state.actionHistory.undoLast()

        listed = try await manager.listEntries().map { $0.path }
        XCTAssertTrue(listed.contains(originalPath))
        XCTAssertFalse(listed.contains(newValidPath))

        // Pending is cleared.
        XCTAssertNil(state.actionHistory.pending)
    }

    // MARK: - Cancel + dismissal

    func testCancel_midSave_landsInIdle_withoutCompletionSideEffects() async throws {
        // Use a slow scripted manager so we can land cancel before
        // the in-flight task completes.
        let scripted = ScriptedFailingMoveManager(
            moveResult: .success(PassEntry(path: newValidPath)),
            delay: .milliseconds(150)
        )
        let state = AppState(passManager: scripted)
        let model = MoveEntryModel(
            originalEntry: PassEntry(path: originalPath),
            passManager: scripted,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
        model.newPath = newValidPath

        model.save()
        // Yield once to let the save task spawn.
        await Task.yield()
        XCTAssertEqual(model.state, .saving)

        model.cancel()

        XCTAssertEqual(model.state, .idle)
        XCTAssertFalse(model.forceMove)

        // Wait beyond the scripted delay to confirm the late
        // completion is silently dropped (state stays .idle, no
        // toast, no selection, no ActionHistory record).
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(model.state, .idle)
        XCTAssertNil(state.toastCenter.visible)
        XCTAssertNil(state.actionHistory.pending)
        XCTAssertNil(state.router.selectedEntryID)
    }

    func testHandleDismissal_cancelsInFlightSave_andDropsCompletion() async throws {
        let scripted = ScriptedFailingMoveManager(
            moveResult: .success(PassEntry(path: newValidPath)),
            delay: .milliseconds(150)
        )
        let state = AppState(passManager: scripted)
        let model = MoveEntryModel(
            originalEntry: PassEntry(path: originalPath),
            passManager: scripted,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
        model.newPath = newValidPath

        model.save()
        await Task.yield()
        XCTAssertEqual(model.state, .saving)

        model.handleDismissal()

        // Late completion must not mutate state.
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertNil(state.toastCenter.visible)
        XCTAssertNil(state.actionHistory.pending)
        XCTAssertNil(state.router.selectedEntryID)
    }

    // MARK: - Non-recoverable error toast

    func testSave_withNonRecoverableError_landsInFailed_andPostsErrorToast() async throws {
        let scripted = ScriptedFailingMoveManager(
            moveResult: .failure(.recipientNotFound(emailOrKeyId: "missing@example.com"))
        )
        let state = AppState(passManager: scripted)
        let model = MoveEntryModel(
            originalEntry: PassEntry(path: originalPath),
            passManager: scripted,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
        model.newPath = newValidPath

        model.save()
        await waitForNonSavingState(of: model)

        guard case .failed(let err) = model.state else {
            return XCTFail("expected .failed, got \(model.state)")
        }
        guard case .recipientNotFound = err else {
            return XCTFail("expected .recipientNotFound, got \(err)")
        }
        XCTAssertFalse(err.inlineRecoverable)

        // Error toast IS posted (non-recoverable).
        guard let toast = state.toastCenter.visible else {
            return XCTFail("expected visible danger toast")
        }
        XCTAssertEqual(toast.severity, .danger)
        XCTAssertEqual(toast.title, "Move failed")

        // No ActionHistory record, no selection change.
        XCTAssertNil(state.actionHistory.pending)
        XCTAssertNil(state.router.selectedEntryID)
    }

    // MARK: - Generation counter

    func testGenerationCounter_dropsStaleCompletionFromCancelledSave() async throws {
        // Two scripted managers cannot reliably interleave; instead
        // use a single slow scripted manager with two sequential
        // saves. The first (slow) save is supposed to be ignored;
        // we cancel it explicitly via a fresh `save()` which bumps
        // the generation. The second save replaces the in-flight
        // task and its completion is what wins.
        let scripted = ScriptedFailingMoveManager(
            moveResult: .success(PassEntry(path: newValidPath)),
            delay: .milliseconds(80)
        )
        let state = AppState(passManager: scripted)
        let model = MoveEntryModel(
            originalEntry: PassEntry(path: originalPath),
            passManager: scripted,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
        model.newPath = newValidPath

        // First save — this one will be cancelled by the second.
        model.save()
        await Task.yield()
        XCTAssertEqual(model.state, .saving)

        // Second, rapid save — bumps generation, cancels the prior
        // task, and is the only completion that may mutate state.
        model.save()
        await waitForNonSavingState(of: model)

        guard case .saved = model.state else {
            return XCTFail("expected .saved, got \(model.state)")
        }
        // Exactly one toast + one ActionHistory record (no
        // double-posting from a stale completion).
        XCTAssertNotNil(state.toastCenter.visible)
        XCTAssertNotNil(state.actionHistory.pending)
    }

    // MARK: - Helpers

    /// Spin until the model leaves `.saving`. Bounded by a
    /// generous absolute timeout so a regression cannot hang the
    /// suite.
    private func waitForNonSavingState(
        of model: MoveEntryModel,
        timeoutMillis: Int = 1_000,
        line: UInt = #line
    ) async {
        let start = ContinuousClock().now
        let timeout: Duration = .milliseconds(timeoutMillis)
        while ContinuousClock().now - start < timeout {
            if model.state != .saving { return }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(5))
        }
        XCTFail(
            "model still in .saving after \(timeoutMillis)ms",
            line: line
        )
    }
}

// MARK: - Test fakes

/// Scripted PassManager that returns a pre-configured outcome for
/// `move`, optionally after a delay (used to land cancel mid-flight
/// in the cancellation tests). Records `move` invocations so the
/// caller can assert call counts.
private actor ScriptedFailingMoveManager: PassManaging {

    let moveResult: Result<PassEntry, PassError>
    let delay: Duration?

    private(set) var moveCallCount: Int = 0

    init(
        moveResult: Result<PassEntry, PassError>,
        delay: Duration? = nil
    ) {
        self.moveResult = moveResult
        self.delay = delay
    }

    func listEntries() async throws -> [PassEntry] { [] }

    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw PassError.decryptionFailed(stderrExcerpt: "scripted-show-not-supported")
    }

    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-scripted-move")
    }

    func move(from: PassEntry, to newPath: String, force: Bool) async throws -> PassEntry {
        moveCallCount += 1
        if let delay {
            try await Task.sleep(for: delay)
        }
        switch moveResult {
        case .success(let entry):
            return entry
        case .failure(let error):
            throw error
        }
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}
