//
//  GeneratePasswordModelTests.swift
//  KizbaTests
//
//  Phase F.4 — Unit tests for ``GeneratePasswordModel``. Backed by
//  ``FakePasswordGenerator`` (Phase D.4 fixture) so every assertion
//  is deterministic and the production CSPRNG is not exercised.
//
//  The generator's call log is the primary observation surface: we
//  verify that length / includeSymbols changes propagate to the
//  collaborator only when the view-modelled `regenerate()` trigger
//  fires (the model intentionally does NOT auto-regenerate on
//  property mutation — the view owns that contract via SwiftUI
//  `.onChange`).
//

import XCTest
@testable import Kizba

@MainActor
final class GeneratePasswordModelTests: XCTestCase {

    // MARK: - Initial state

    func testInit_runsInitialPreview_andSurfacesReadyState() {
        let fake = FakePasswordGenerator(script: ["initial-preview"])

        let model = GeneratePasswordModel(generator: fake)

        XCTAssertEqual(model.length, 25)
        XCTAssertTrue(model.includeSymbols)
        XCTAssertEqual(model.state, .ready(password: "initial-preview"))
        XCTAssertEqual(model.previewPassword, "initial-preview")
        XCTAssertEqual(fake.allCalls, [
            FakePasswordGenerator.Call(length: 25, includeSymbols: true)
        ])
    }

    // MARK: - regenerate()

    func testRegenerate_consumesNextScriptedValue_andUpdatesState() {
        let fake = FakePasswordGenerator(script: ["preview-1", "preview-2"])
        let model = GeneratePasswordModel(generator: fake)
        XCTAssertEqual(model.previewPassword, "preview-1")

        model.regenerate()

        XCTAssertEqual(model.state, .ready(password: "preview-2"))
        XCTAssertEqual(model.previewPassword, "preview-2")
        XCTAssertEqual(fake.allCalls.count, 2)
    }

    func testLengthMutation_alone_doesNotCallGenerator() {
        // Documents the model's contract: the view is responsible
        // for invoking `regenerate()` after `length` commits via
        // SwiftUI `.onChange`. The model itself stays inert so the
        // contract is testable in isolation.
        let fake = FakePasswordGenerator(script: ["initial"])
        let model = GeneratePasswordModel(generator: fake)
        let callsAfterInit = fake.allCalls.count
        XCTAssertEqual(model.previewPassword, "initial")

        model.length = 40

        XCTAssertEqual(model.previewPassword, "initial",
                       "preview must not change without an explicit regenerate()")
        XCTAssertEqual(fake.allCalls.count, callsAfterInit,
                       "generator must not be re-invoked on bare length mutation")
    }

    func testIncludeSymbolsMutation_alone_doesNotCallGenerator() {
        let fake = FakePasswordGenerator(script: ["initial"])
        let model = GeneratePasswordModel(generator: fake)
        let callsAfterInit = fake.allCalls.count

        model.includeSymbols = false

        XCTAssertEqual(model.previewPassword, "initial")
        XCTAssertEqual(fake.allCalls.count, callsAfterInit)
    }

    func testRegenerate_propagatesCurrentLengthAndSymbolsFlag() {
        // Three different (length, includeSymbols) combinations are
        // pushed through the model; the fake's call log must show
        // exactly those three pairs in order (init counts as the
        // first pair).
        let fake = FakePasswordGenerator()
        let model = GeneratePasswordModel(generator: fake)
        // Init: (25, true).
        model.length = 12
        model.includeSymbols = false
        model.regenerate()
        // Second call: (12, false).
        model.length = 32
        model.includeSymbols = true
        model.regenerate()
        // Third call: (32, true).

        XCTAssertEqual(fake.allCalls, [
            FakePasswordGenerator.Call(length: 25, includeSymbols: true),
            FakePasswordGenerator.Call(length: 12, includeSymbols: false),
            FakePasswordGenerator.Call(length: 32, includeSymbols: true),
        ])
    }

    // MARK: - Error path

    func testRegenerate_withInvalidLengthZero_landsInErrorState() {
        let fake = FakePasswordGenerator()
        let model = GeneratePasswordModel(generator: fake)
        XCTAssertNotNil(model.previewPassword)

        // The UI bounds (8...128) are advisory; the model accepts
        // any Int and lets the generator throw. Setting `length`
        // directly bypasses the bounds the way a programmatic
        // caller (or a future text-input affordance) would.
        model.length = 0
        model.regenerate()

        if case .error(let msg) = model.state {
            XCTAssertTrue(
                msg.contains("0"),
                "error message should mention the offending length, got: \(msg)"
            )
        } else {
            XCTFail("expected .error state, got \(model.state)")
        }
        XCTAssertNil(model.previewPassword,
                     "previewPassword must be nil when in .error state")
    }

    func testRegenerate_withNegativeLength_landsInErrorState() {
        let fake = FakePasswordGenerator()
        let model = GeneratePasswordModel(generator: fake)

        model.length = -5
        model.regenerate()

        guard case .error = model.state else {
            return XCTFail("expected .error state, got \(model.state)")
        }
        XCTAssertNil(model.previewPassword)
    }

    // MARK: - Length bounds constant

    func testLengthBounds_matchesProjectSpec() {
        // Pinned at 8...128 per Phase F.4 plan. Hard-coded here so a
        // future broadening of the bounds is a deliberate test edit
        // rather than a silent UI regression.
        XCTAssertEqual(GeneratePasswordModel.lengthBounds, 8...128)
    }

    // MARK: - Recovery from error → ready

    func testRegenerate_afterError_recoversToReadyOnValidLength() {
        // Two scripted values: the first is consumed by init's
        // initial regenerate; the second is reserved for the
        // post-recovery call. The middle (length = 0) call throws
        // BEFORE the fake pops from the script, so the second value
        // is preserved for the recovery step.
        let fake = FakePasswordGenerator(script: ["initial", "after-recovery"])
        let model = GeneratePasswordModel(generator: fake)
        XCTAssertEqual(model.previewPassword, "initial")

        // Push into error first.
        model.length = 0
        model.regenerate()
        XCTAssertNil(model.previewPassword)

        // Restore a valid length and re-run.
        model.length = 16
        model.regenerate()

        XCTAssertEqual(model.state, .ready(password: "after-recovery"))
        XCTAssertEqual(model.previewPassword, "after-recovery")
    }

    // MARK: - Apply contract (integration-shaped, no view rendered)

    /// Documents the F.4 apply path at the model boundary: the
    /// sub-sheet is expected to read ``GeneratePasswordModel/previewPassword``
    /// and pipe it into `EntryFormModel.draft.password`. Verifying
    /// the EntryFormModel's `canSave` flips to `true` once the
    /// password is populated proves the form is source-agnostic
    /// (it doesn't care whether the user typed or generated the
    /// value).
    func testApplyFlow_populatingDraftPassword_unblocksFormCanSave() {
        let pwdGenerator = FakePasswordGenerator(script: ["applied-from-generator"])
        let generatorModel = GeneratePasswordModel(generator: pwdGenerator)
        guard let preview = generatorModel.previewPassword else {
            return XCTFail("preview must be ready after init")
        }

        let appState = AppState()
        let formModel = EntryFormModel(
            mode: .create,
            passManager: MockPassManager.preview(),
            toastCenter: appState.toastCenter,
            appState: appState
        )
        formModel.path = "personal/site"
        XCTAssertFalse(formModel.canSave,
                       "canSave must be false while password is empty")

        // Apply path: the sub-sheet hands the preview back to the
        // parent form via `onApply`.
        formModel.draft.password = preview

        XCTAssertTrue(formModel.canSave,
                      "canSave must flip to true once the password is populated")
        XCTAssertEqual(formModel.draft.password, "applied-from-generator")
    }
}
