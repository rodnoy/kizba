//
//  EntryListModelTests.swift
//  KizbaTests
//
//  Tests for the entry-list view model. The MainActor-isolated model
//  is fed `AppEnvironment.preview().passManager` (`MockPassManager`
//  in DEBUG, 20 deterministic fixtures) and asserted under various
//  combinations of folder and search filters.
//

import XCTest
@testable import Kizba

@MainActor
final class EntryListModelTests: XCTestCase {

    // Total fixture count from `MockPassManager.fixtures`:
    // 7 personal + 8 work + 5 archive = 20.
    private let fixtureTotal = 20

    func testEntries_initialCount_unfiltered() async {
        let env = AppEnvironment.preview()
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)

        await model.refresh()

        XCTAssertEqual(model.allEntries.count, fixtureTotal)
        XCTAssertEqual(model.entries.count, fixtureTotal)
    }

    func testEntries_folderFilter_limitsToSelectedFolder() async {
        let env = AppEnvironment.preview()
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        state.router.selectedFolder = "work"

        let filtered = model.entries
        XCTAssertEqual(filtered.count, 8)
        XCTAssertTrue(filtered.allSatisfy { $0.path.hasPrefix("work/") })

        state.router.selectedFolder = "archive"
        XCTAssertEqual(model.entries.count, 5)
        XCTAssertTrue(model.entries.allSatisfy { $0.path.hasPrefix("archive/") })

        state.router.selectedFolder = "personal"
        XCTAssertEqual(model.entries.count, 7)
        XCTAssertTrue(model.entries.allSatisfy { $0.path.hasPrefix("personal/") })
    }

    func testEntries_searchFilter_isCaseInsensitiveSubstringOverPath() async {
        let env = AppEnvironment.preview()
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        // Substring matching the AWS fixtures (work/aws/root, work/aws/ci).
        state.searchQuery = "AWS"
        let aws = model.entries
        XCTAssertEqual(aws.count, 2)
        XCTAssertTrue(aws.allSatisfy { $0.path.lowercased().contains("aws") })

        // Case-insensitive: "POSTGRES" must match "postgres-prod" / "postgres-readonly".
        state.searchQuery = "POSTGRES"
        XCTAssertEqual(model.entries.count, 2)

        // Combined folder + search filter.
        state.router.selectedFolder = "personal"
        state.searchQuery = "wifi"
        let wifi = model.entries
        XCTAssertEqual(wifi.count, 2)
        XCTAssertTrue(wifi.allSatisfy { $0.path.hasPrefix("personal/wifi/") })

        // Empty query restores the folder-only filter.
        state.searchQuery = ""
        XCTAssertEqual(model.entries.count, 7)
    }

    // MARK: - Global search (folder filter bypass)
    //
    // When a search query is active the folder filter is bypassed so
    // matches from outside the currently-selected folder appear.
    // The folder scope is restored as soon as the query is cleared.

    func test_entries_withQuery_ignoresSelectedFolder_andReturnsGlobalMatches() async {
        let env = AppEnvironment.preview()
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        // Sit in `work` (8 entries). The query "personal" matches the
        // 7 personal/* entries AND `work/github/personal-token` — 8
        // total. A folder-scoped search would return just 1.
        state.router.selectedFolder = "work"
        state.searchQuery = "personal"

        let results = model.entries
        XCTAssertEqual(results.count, 8)
        // Must contain at least one match from outside the selected
        // folder — proves the folder filter is bypassed.
        XCTAssertTrue(results.contains { $0.path == "personal/email/gmail" })
        XCTAssertTrue(results.contains { $0.path == "work/github/personal-token" })
    }

    func test_entries_withoutQuery_respectsFolderSelection() async {
        let env = AppEnvironment.preview()
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        state.router.selectedFolder = "personal"
        state.searchQuery = ""

        let results = model.entries
        XCTAssertEqual(results.count, 7)
        XCTAssertTrue(results.allSatisfy { $0.path.hasPrefix("personal/") })
    }

    func testSelect_updatesAppStateSelectedEntryID() async {
        let env = AppEnvironment.preview()
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        XCTAssertNil(state.router.selectedEntryID)

        let target = model.allEntries.first { $0.path == "work/aws/root" }
        XCTAssertNotNil(target)
        model.select(entryID: target?.id)

        XCTAssertEqual(state.router.selectedEntryID, "work/aws/root")

        model.select(entryID: nil)
        XCTAssertNil(state.router.selectedEntryID)
    }
}
