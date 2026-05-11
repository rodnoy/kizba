//
//  AppStateTests.swift
//  KizbaTests
//
//  Tests for the `@Observable @MainActor` root state. Assertions are
//  pure read/write checks — no SwiftUI runtime is involved.
//

import XCTest
@testable import Kizba

@MainActor
final class AppStateTests: XCTestCase {

    func testInit_defaultsAreEmpty() {
        let state = AppState()
        XCTAssertNil(state.router.selectedEntryID)
        XCTAssertEqual(state.searchQuery, "")
        XCTAssertFalse(state.isSidebarCollapsed)
        XCTAssertTrue(state.currentEntries.isEmpty)
    }

    func testInit_acceptsExplicitValues() {
        let entries = [PassEntry(path: "work/aws/root")]
        let state = AppState(
            searchQuery: "aws",
            isSidebarCollapsed: true,
            currentEntries: entries
        )

        // Selection is now owned by AppRouter and defaults to nil;
        // AppState initialisation no longer infers a selection from
        // the provided entries.
        XCTAssertNil(state.router.selectedEntryID)
        XCTAssertEqual(state.searchQuery, "aws")
        XCTAssertTrue(state.isSidebarCollapsed)
        XCTAssertEqual(state.currentEntries, entries)
    }

    func testSelectedEntryID_isMutable() {
        let state = AppState()
        XCTAssertNil(state.router.selectedEntryID)

        state.router.selectedEntryID = "personal/email/gmail"
        XCTAssertEqual(state.router.selectedEntryID, "personal/email/gmail")

        state.router.selectedEntryID = nil
        XCTAssertNil(state.router.selectedEntryID)
    }

    func testSearchQuery_isMutable() {
        let state = AppState()
        state.searchQuery = "github"
        XCTAssertEqual(state.searchQuery, "github")
    }

    func testCurrentEntries_isMutable() {
        let state = AppState()
        state.currentEntries = [
            PassEntry(path: "a"),
            PassEntry(path: "b"),
        ]
        XCTAssertEqual(state.currentEntries.map(\.path), ["a", "b"])
    }

    func testGitStatusModel_defaultNil() {
        let state = AppState()
        XCTAssertNil(state.gitStatusModel)
    }
}
