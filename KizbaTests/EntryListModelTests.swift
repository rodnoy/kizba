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
        await model.performSearch()
        let aws = model.entries
        XCTAssertEqual(aws.count, 2)
        XCTAssertTrue(aws.allSatisfy { $0.path.lowercased().contains("aws") })

        // Case-insensitive: "POSTGRES" must match "postgres-prod" / "postgres-readonly".
        state.searchQuery = "POSTGRES"
        await model.performSearch()
        XCTAssertEqual(model.entries.count, 2)

        // Combined folder + search filter.
        state.router.selectedFolder = "personal"
        state.searchQuery = "wifi"
        await model.performSearch()
        let wifi = model.entries
        XCTAssertEqual(wifi.count, 2)
        XCTAssertTrue(wifi.allSatisfy { $0.path.hasPrefix("personal/wifi/") })

        // Empty query restores the folder-only filter.
        state.searchQuery = ""
        await model.performSearch()
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
        await model.performSearch()

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

    // MARK: - MVP9.3 — hierarchical folder selection (prefix match)

    func testEntries_folderFilter_topLevelPrefixIncludesAllSubfolders() async {
        // Selecting `"personal"` must include every entry whose path
        // starts with `personal/` — including deeply nested ones such
        // as `personal/email/gmail`. The MVP9.2 (pre-MVP9.3) head-
        // equality filter happened to produce the same result for
        // 2-component paths; this test pins the new semantic so any
        // future regression to "head-only" matching is caught.
        let env = AppEnvironment.preview()
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        state.router.selectedFolder = "personal"
        let filtered = model.entries
        XCTAssertEqual(filtered.count, 7)
        XCTAssertTrue(filtered.allSatisfy { $0.path.hasPrefix("personal/") })
        // The deeply-nested case is the surprising one — assert it
        // explicitly.
        XCTAssertTrue(filtered.contains { $0.path == "personal/email/gmail" })
    }

    func testEntries_folderFilter_nestedSelection_narrowsToSubtree() {
        // Selecting `"personal/email"` must show ONLY entries under
        // that sub-folder, even though `personal/bank/checking`
        // shares the same top-level component.
        let entries = [
            PassEntry(path: "personal/email/gmail"),
            PassEntry(path: "personal/email/yahoo"),
            PassEntry(path: "personal/bank/checking"),
        ]
        let state = AppState()
        state.router.selectedFolder = "personal/email"

        // Build a tiny in-memory env that returns the synthetic entries.
        // We use ``AppEnvironment.preview()`` solely for the
        // collaborator shapes and substitute the snapshot directly.
        let env = AppEnvironment.preview()
        let model = EntryListModel(environment: env, state: state)
        model.setAllEntriesForTesting(entries)

        let filtered = model.entries
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.path.hasPrefix("personal/email/") })
        XCTAssertFalse(filtered.contains { $0.path == "personal/bank/checking" })
    }

    func testEntries_folderFilter_matchesEntryWithExactPath() {
        // Edge case: a top-level entry whose path equals the selected
        // folder name (no `/`). Selecting that name should include it.
        let entries = [
            PassEntry(path: "system"),
            PassEntry(path: "system/work/email"),
        ]
        let state = AppState()
        state.router.selectedFolder = "system"

        let env = AppEnvironment.preview()
        let model = EntryListModel(environment: env, state: state)
        model.setAllEntriesForTesting(entries)

        let filtered = model.entries
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains { $0.path == "system" })
        XCTAssertTrue(filtered.contains { $0.path == "system/work/email" })
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
