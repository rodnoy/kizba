//
//  RegenerateInPlaceModelTests.swift
//  KizbaTests
//
//  Phase G.3 — coverage for the in-place regenerate sub-sheet view-
//  model. Exercises the two-call sequence (pre-`show` for undo body
//  → `generateInPlace` for rotation), the ActionHistory recording,
//  the success / error toast surfaces, and the parameter pass-
//  through for length / includeSymbols.
//
//  Test fakes:
//
//  - `MockPassManager` (project-shipped) for the happy path. Its
//    `generateInPlace` preserves the prior metadata in `secrets`
//    and emits a `.updated` `StoreChange`, mirroring the live
//    behaviour.
//  - Local `ScriptedRegeneratePassManager` actor for the failure
//    branches (pre-`show` failure, and `generateInPlace` failure
//    after a successful pre-`show`). Records `generateInPlace`
//    arguments so the parameter pass-through assertion can pin
//    length / includeSymbols.
//
//  Time-dependent assertions use the real clock with generous
//  margins; the longest test sleeps ~250ms.
//

import XCTest
@testable import Kizba

@MainActor
final class RegenerateInPlaceModelTests: XCTestCase {

    // MARK: - Fixtures

    /// Path used by every test. Pinned so toast / undo assertions
    /// can match exactly.
    private let entryPath = "personal/email/gmail"

    /// Helper: build a `PassSecret` with a single metadata field so
    /// the post-rotation "metadata preserved" invariant has
    /// observable evidence (it differs from a default-empty body).
    private func makeSecret(password: String) -> PassSecret {
        PassSecret(
            password: password,
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "jane.doe@example.com")],
                notes: "recovery codes offline"
            )
        )
    }

    /// Helper: construct an `AppState` + `RegenerateInPlaceModel`
    /// pair sharing the same `actionHistory` / `toastCenter`. Tests
    /// usually want to assert against both surfaces, so returning
    /// the pair keeps each test compact.
    private func makeModelAndState(
        manager: any PassManaging,
        path: String? = nil
    ) -> (RegenerateInPlaceModel, AppState) {
        let state = AppState(passManager: manager)
        let entry = PassEntry(path: path ?? entryPath)
        let model = RegenerateInPlaceModel(
            entry: entry,
            passManager: manager,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
        return (model, state)
    }

    // MARK: - Initial state

    func testInitialState_isIdle_withDefaultLengthAndSymbols() {
        let entry = PassEntry(path: entryPath)
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entryPath: makeSecret(password: "p1")]
        )
        let (model, _) = makeModelAndState(manager: manager)

        XCTAssertEqual(model.state, .idle)
        XCTAssertEqual(model.length, 24)
        XCTAssertTrue(model.includeSymbols)
        XCTAssertEqual(model.entry.path, entryPath)
    }

    func testLengthBounds_pinnedAt8To128() {
        XCTAssertEqual(RegenerateInPlaceModel.lengthBounds.lowerBound, 8)
        XCTAssertEqual(RegenerateInPlaceModel.lengthBounds.upperBound, 128)
    }

    // MARK: - Happy path

    func testRegenerate_happyPath_landsInSucceeded_andRecordsAction_andPostsToast() async throws {
        let entry = PassEntry(path: entryPath)
        let priorSecret = makeSecret(password: "prior-pwd")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entryPath: priorSecret]
        )
        let (model, state) = makeModelAndState(manager: manager)

        await model.regenerate()

        // State.
        guard case .succeeded(let newPwd) = model.state else {
            return XCTFail("expected .succeeded, got \(model.state)")
        }
        // The mock's `generateInPlace` returns a deterministic shape;
        // we don't pin the exact value here — the value-equality is
        // more meaningfully covered by the pass-through test below.
        XCTAssertFalse(newPwd.isEmpty)

        // ActionHistory recorded the inverse with the prior body.
        guard let pending = state.actionHistory.pending else {
            return XCTFail("expected pending undo action")
        }
        guard case .inPlaceGenerate(let path, let captured) = pending.action else {
            return XCTFail("expected .inPlaceGenerate, got \(pending.action)")
        }
        XCTAssertEqual(path, entryPath)
        XCTAssertEqual(captured.password, priorSecret.password)
        XCTAssertEqual(captured.metadata.fields.first?.key, "user")
        XCTAssertEqual(captured.metadata.fields.first?.value, "jane.doe@example.com")

        // Toast: success severity, carries an Undo action, message =
        // entry path (NEVER the password).
        guard let toast = state.toastCenter.visible else {
            return XCTFail("expected visible toast")
        }
        XCTAssertEqual(toast.severity, .success)
        XCTAssertEqual(toast.title, "Password regenerated")
        XCTAssertEqual(toast.message, entryPath)
        XCTAssertNotNil(toast.action)
        XCTAssertEqual(toast.action?.label, "Undo")

        // Manager-side mutation: post-rotation, the stored secret has
        // a NEW password but the SAME metadata block (atomic in-place
        // contract).
        let postSecret = try await manager.show(entry)
        XCTAssertNotEqual(postSecret.password, priorSecret.password)
        XCTAssertEqual(postSecret.metadata.fields.first?.value, "jane.doe@example.com")
    }

    func testUndo_fromPendingAction_restoresPriorSecret() async throws {
        let entry = PassEntry(path: entryPath)
        let priorSecret = makeSecret(password: "S1")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entryPath: priorSecret]
        )
        let (model, state) = makeModelAndState(manager: manager)

        await model.regenerate()

        // Sanity: post-regenerate the password is different.
        let postRegenerate = try await manager.show(entry)
        XCTAssertNotEqual(postRegenerate.password, priorSecret.password)

        // Undo via ActionHistory.
        try await state.actionHistory.undoLast()

        // After undo, `show` should return the prior body verbatim.
        let restored = try await manager.show(entry)
        XCTAssertEqual(restored.password, priorSecret.password)
        XCTAssertEqual(restored.metadata.fields.first?.value, "jane.doe@example.com")

        // And the pending action is now nil.
        XCTAssertNil(state.actionHistory.pending)
    }

    // MARK: - Failure paths

    func testRegenerate_preShowFailure_landsInFailed_andDoesNotRecordAction_andPostsDangerToast() async {
        let entry = PassEntry(path: entryPath)
        let scripted = ScriptedRegeneratePassManager(
            showResult: .failure(.decryptionFailed(stderrExcerpt: "no key")),
            generateResult: .failure(.shellFailure(exitCode: -1, stderrExcerpt: "should-not-call"))
        )
        let (model, state) = makeModelAndState(manager: scripted, path: entryPath)
        // Replace the entry to match the scripted manager's expectations.
        let regenModel = RegenerateInPlaceModel(
            entry: entry,
            passManager: scripted,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )

        await regenModel.regenerate()

        // State is .failed with the scripted error.
        guard case .failed(let err) = regenModel.state else {
            return XCTFail("expected .failed, got \(regenModel.state)")
        }
        if case .decryptionFailed = err {
            // ok
        } else {
            XCTFail("expected .decryptionFailed, got \(err)")
        }

        // No undo action was recorded — we never rotated.
        XCTAssertNil(state.actionHistory.pending)

        // Toast is danger.
        guard let toast = state.toastCenter.visible else {
            return XCTFail("expected visible danger toast")
        }
        XCTAssertEqual(toast.severity, .danger)
        XCTAssertEqual(toast.title, "Could not regenerate password")
        XCTAssertEqual(toast.message, entryPath)

        // The scripted manager observed exactly one call: the pre-show.
        let showCount = await scripted.showCallCount
        let genCount = await scripted.generateCallCount
        XCTAssertEqual(showCount, 1)
        XCTAssertEqual(genCount, 0)
        // Suppress unused-variable warning on `model`.
        _ = model
    }

    func testRegenerate_generateFailureAfterSuccessfulShow_landsInFailed_andDoesNotRecordAction_andPostsDangerToast() async {
        let entry = PassEntry(path: entryPath)
        let priorSecret = makeSecret(password: "prior")
        let scripted = ScriptedRegeneratePassManager(
            showResult: .success(priorSecret),
            generateResult: .failure(.invalidLength)
        )
        let (_, state) = makeModelAndState(manager: scripted, path: entryPath)
        let regenModel = RegenerateInPlaceModel(
            entry: entry,
            passManager: scripted,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
        regenModel.length = 7 // invalid; scripted manager throws regardless

        await regenModel.regenerate()

        guard case .failed(let err) = regenModel.state else {
            return XCTFail("expected .failed, got \(regenModel.state)")
        }
        if case .invalidLength = err {
            // ok
        } else {
            XCTFail("expected .invalidLength, got \(err)")
        }

        XCTAssertNil(state.actionHistory.pending)

        guard let toast = state.toastCenter.visible else {
            return XCTFail("expected visible danger toast")
        }
        XCTAssertEqual(toast.severity, .danger)
        XCTAssertEqual(toast.title, "Could not regenerate password")

        let showCount = await scripted.showCallCount
        let genCount = await scripted.generateCallCount
        XCTAssertEqual(showCount, 1)
        XCTAssertEqual(genCount, 1)
    }

    // MARK: - Parameter pass-through

    func testRegenerate_lengthAndSymbols_passedThroughToManager() async throws {
        let entry = PassEntry(path: entryPath)
        let priorSecret = makeSecret(password: "p")
        let scripted = ScriptedRegeneratePassManager(
            showResult: .success(priorSecret),
            generateResult: .success(
                PassSecret(
                    password: "GEN",
                    metadata: PassMetadata(fields: [], notes: nil)
                )
            )
        )
        let (_, state) = makeModelAndState(manager: scripted, path: entryPath)
        let regenModel = RegenerateInPlaceModel(
            entry: entry,
            passManager: scripted,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
        regenModel.length = 42
        regenModel.includeSymbols = false

        await regenModel.regenerate()

        let recorded = await scripted.recordedGenerateCall
        XCTAssertEqual(recorded?.path, entryPath)
        XCTAssertEqual(recorded?.length, 42)
        XCTAssertEqual(recorded?.includeSymbols, false)
    }

    // MARK: - State machine intermediate

    func testRegenerate_afterCall_isNotInRunning_orIdle() async {
        // Smoke: by the time `await model.regenerate()` returns, the
        // pipeline has resolved. We assert it is NOT in `.running` /
        // `.idle` — it must be `.succeeded` or `.failed`. This pins
        // the contract the view's `.onChange` relies on for auto-
        // dismissal.
        let entry = PassEntry(path: entryPath)
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entryPath: makeSecret(password: "p")]
        )
        let (model, _) = makeModelAndState(manager: manager)

        await model.regenerate()

        switch model.state {
        case .idle, .running:
            XCTFail("model should not be in \(model.state) after await regenerate()")
        case .succeeded, .failed:
            break
        }
    }

    // MARK: - Toast carries no secret

    func testToast_message_neverContainsTheNewPassword() async {
        let entry = PassEntry(path: entryPath)
        let priorSecret = makeSecret(password: "prior-secret-XYZ")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entryPath: priorSecret]
        )
        let (model, state) = makeModelAndState(manager: manager)

        await model.regenerate()

        guard let toast = state.toastCenter.visible else {
            return XCTFail("expected visible toast")
        }
        // Toast.message MUST equal the entry path (per
        // `.ai/decisions.md` toasts never carry secret material).
        XCTAssertEqual(toast.message, entryPath)
        // Defensive: also verify the title doesn't sneak the secret in.
        XCTAssertFalse(toast.title.contains("prior-secret"))
        XCTAssertFalse(toast.title.contains("GEN_INPLACE"))
        // And the recorded prior secret in ActionHistory carries the
        // right body (covered above) — sanity-only here.
        if case .inPlaceGenerate(_, let captured) = state.actionHistory.pending?.action {
            XCTAssertEqual(captured.password, priorSecret.password)
        }
    }
}

// MARK: - Test fakes

/// Scripted PassManager that returns pre-configured outcomes for
/// `show` and `generateInPlace`, recording the latter's parameters
/// for assertion. Used by the failure / pass-through tests in this
/// suite.
private actor ScriptedRegeneratePassManager: PassManaging {

    struct GenerateCall: Sendable, Equatable {
        let path: String
        let length: Int
        let includeSymbols: Bool
    }

    let showResult: Result<PassSecret, PassError>
    let generateResult: Result<PassSecret, PassError>

    private(set) var showCallCount: Int = 0
    private(set) var generateCallCount: Int = 0
    private(set) var recordedGenerateCall: GenerateCall?

    init(
        showResult: Result<PassSecret, PassError>,
        generateResult: Result<PassSecret, PassError>
    ) {
        self.showResult = showResult
        self.generateResult = generateResult
    }

    func listEntries() async throws -> [PassEntry] { [] }

    func show(_ entry: PassEntry) async throws -> PassSecret {
        showCallCount += 1
        switch showResult {
        case .success(let s): return s
        case .failure(let e): throw e
        }
    }

    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-scripted-regenerate")
    }

    func generateInPlace(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool
    ) async throws -> PassSecret {
        generateCallCount += 1
        recordedGenerateCall = GenerateCall(
            path: entry.path,
            length: length,
            includeSymbols: includeSymbols
        )
        switch generateResult {
        case .success(let s): return s
        case .failure(let e): throw e
        }
    }

    nonisolated var changes: AsyncStream<StoreChange> {
        AsyncStream { $0.finish() }
    }
}
