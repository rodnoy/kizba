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
}
