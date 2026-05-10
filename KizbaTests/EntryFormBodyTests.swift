import XCTest
@testable import Kizba

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
}
