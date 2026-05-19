import XCTest
import SwiftUI
@testable import Kizba

@MainActor
final class EntryFormBodyTests: XCTestCase {

    func testHeaderAndFooterSlotsAreRendered() {
        let appState = AppState()
        let model = EntryFormModel(mode: .create, passManager: MockPassManager(entries: [], secrets: [:]), toastCenter: appState.toastCenter, appState: appState)

        // We cannot render SwiftUI snapshots here; instead assert the view
        // holds the model and flags and that initializing does not crash.
        let body = EntryFormBody(model: model, pathFieldEnabled: true, header: { Text("H") }, footer: { Text("F") })

        XCTAssertEqual(body.model.mode, .create)
        XCTAssertTrue(body.pathFieldEnabled)
    }

    func testPathFieldEnabledToggles() {
        let appState = AppState()
        let model = EntryFormModel(mode: .create, passManager: MockPassManager(entries: [], secrets: [:]), toastCenter: appState.toastCenter, appState: appState)

        let enabled = EntryFormBody(model: model, pathFieldEnabled: true, header: { Text("") }, footer: { Text("") })
        let disabled = EntryFormBody(model: model, pathFieldEnabled: false, header: { Text("") }, footer: { Text("") })

        XCTAssertTrue(enabled.pathFieldEnabled)
        XCTAssertFalse(disabled.pathFieldEnabled)
    }

    /// Phase D.3 closure — Asserts the password reveal helper
    /// matches the `SecretRevealField` vocabulary so the editable
    /// and read-only secret affordances announce the same value to
    /// VoiceOver.
    func testPasswordRevealAccessibilityValueDefaultsToHidden() {
        XCTAssertEqual(
            EntryFormBody<EmptyView, EmptyView>.passwordRevealAccessibilityValue(isRevealed: false),
            "Hidden"
        )
    }

    /// Phase D.3 closure — Mirrors the revealed-state vocabulary
    /// from `SecretRevealField.accessibilityValueText(isRevealed:)`.
    func testPasswordRevealAccessibilityValueWhenRevealed() {
        XCTAssertEqual(
            EntryFormBody<EmptyView, EmptyView>.passwordRevealAccessibilityValue(isRevealed: true),
            "Revealed"
        )

        // Cross-check with the existing read-only field helper so
        // any future divergence between the two affordances trips
        // this test rather than slipping past review.
        XCTAssertEqual(
            EntryFormBody<EmptyView, EmptyView>.passwordRevealAccessibilityValue(isRevealed: true),
            SecretRevealField.accessibilityValueText(isRevealed: true)
        )
        XCTAssertEqual(
            EntryFormBody<EmptyView, EmptyView>.passwordRevealAccessibilityValue(isRevealed: false),
            SecretRevealField.accessibilityValueText(isRevealed: false)
        )
    }

    // MARK: - MVP9.2 — derivedIssuer prefill rule

    /// Single-component paths have no folder structure to mine for
    /// an issuer; the AddTOTP sheet must fall back to "no prefill"
    /// so the user can type the value.
    func testDerivedIssuer_singleComponent_returnsNil() {
        XCTAssertNil(EntryFormBody<EmptyView, EmptyView>.derivedIssuer(fromPath: ""))
        XCTAssertNil(EntryFormBody<EmptyView, EmptyView>.derivedIssuer(fromPath: "github"))
    }

    /// Two-component paths (`<issuer>/<account>`) yield the first
    /// segment as the issuer prefill.
    func testDerivedIssuer_twoComponents_takesFirst() {
        XCTAssertEqual(
            EntryFormBody<EmptyView, EmptyView>.derivedIssuer(fromPath: "github/alice"),
            "github"
        )
    }

    /// Deeper paths take the second-to-last segment — the leaf is
    /// treated as the account, the segment right before it as the
    /// issuer (`work/aws/root` → `aws`).
    func testDerivedIssuer_deepPath_takesSecondToLast() {
        XCTAssertEqual(
            EntryFormBody<EmptyView, EmptyView>.derivedIssuer(fromPath: "work/aws/root"),
            "aws"
        )
    }
}
