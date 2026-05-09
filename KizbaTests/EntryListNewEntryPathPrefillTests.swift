//
//  EntryListNewEntryPathPrefillTests.swift
//  KizbaTests
//
//  Pin the path-prefill contract for the New Entry sheet:
//  when the user has a folder selected in the sidebar and opens the
//  New Entry form, the path field starts as `"<folder>/"` so the
//  user can immediately type the entry name. Nil or empty selection
//  yields an empty initial path.
//
//  Implementation note: the production helper lives as a static
//  function on `EntryListView` (`initialPath(for:)`) — kept
//  `internal` so tests reach it directly without instantiating a
//  SwiftUI view (constructing `EntryListView` requires an
//  `AppEnvironment` and a `State<EntryListModel>`, both with
//  observable side-effects that we don't want in this contract
//  test). Testing the helper directly is functionally equivalent:
//  `makeNewEntryFormModel()` does nothing more than forward
//  `Self.initialPath(for: state.selectedFolder)` into the
//  `EntryFormModel` initializer.
//

import XCTest
@testable import Kizba

@MainActor
final class EntryListNewEntryPathPrefillTests: XCTestCase {

    func test_makeNewEntryFormModel_withSelectedFolder_prefillsPath() {
        let prefilled = EntryListView.initialPath(for: "personal")
        XCTAssertEqual(prefilled, "personal/")

        // Round-trip the prefilled value through the form model to
        // prove the contract reaches the field the user types into.
        let env = AppEnvironment.preview()
        let state = AppState()
        let formModel = EntryFormModel(
            mode: .create,
            passManager: env.passManager,
            toastCenter: state.toastCenter,
            appState: state,
            initialPath: prefilled
        )
        XCTAssertEqual(formModel.path, "personal/")
    }

    func test_makeNewEntryFormModel_withNilFolder_pathIsEmpty() {
        let prefilled = EntryListView.initialPath(for: nil)
        XCTAssertEqual(prefilled, "")

        let env = AppEnvironment.preview()
        let state = AppState()
        let formModel = EntryFormModel(
            mode: .create,
            passManager: env.passManager,
            toastCenter: state.toastCenter,
            appState: state,
            initialPath: prefilled
        )
        XCTAssertEqual(formModel.path, "")
    }

    func test_makeNewEntryFormModel_withEmptyFolder_pathIsEmpty() {
        // An empty string selection (root) is treated the same as nil
        // — no folder prefix on the new entry's path.
        let prefilled = EntryListView.initialPath(for: "")
        XCTAssertEqual(prefilled, "")

        let env = AppEnvironment.preview()
        let state = AppState()
        let formModel = EntryFormModel(
            mode: .create,
            passManager: env.passManager,
            toastCenter: state.toastCenter,
            appState: state,
            initialPath: prefilled
        )
        XCTAssertEqual(formModel.path, "")
    }
}
