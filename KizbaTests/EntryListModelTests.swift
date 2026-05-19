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
        // MVP9.5 — immediate-children-only semantics. All MockPassManager
        // fixtures have `top/middle/leaf` shape, so top-level folders
        // (work / archive / personal) have ZERO direct children — every
        // entry lives one level deeper. The interesting cases are the
        // mid-level subfolders.
        let env = AppEnvironment.preview()
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        state.router.selectedFolder = "work/aws"
        let aws = model.entries
        XCTAssertEqual(aws.count, 2)
        XCTAssertTrue(aws.allSatisfy { $0.path.hasPrefix("work/aws/") })

        state.router.selectedFolder = "work/db"
        let db = model.entries
        XCTAssertEqual(db.count, 2)
        XCTAssertTrue(db.allSatisfy { $0.path.hasPrefix("work/db/") })

        state.router.selectedFolder = "personal/email"
        let email = model.entries
        XCTAssertEqual(email.count, 2)
        XCTAssertTrue(email.allSatisfy { $0.path.hasPrefix("personal/email/") })
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

        // Combined folder + search filter. Search bypasses the folder
        // scope (global search contract) so `wifi` still matches the
        // two `personal/wifi/*` entries even though `personal/wifi` is
        // not an immediate child of the selected `personal/wifi` folder.
        state.router.selectedFolder = "personal/wifi"
        state.searchQuery = "wifi"
        await model.performSearch()
        let wifi = model.entries
        XCTAssertEqual(wifi.count, 2)
        XCTAssertTrue(wifi.allSatisfy { $0.path.hasPrefix("personal/wifi/") })

        // Empty query restores the folder-only filter. Under MVP9.5
        // immediate-children semantics, `personal/wifi` has exactly
        // two direct children (`home`, `guest`).
        state.searchQuery = ""
        await model.performSearch()
        XCTAssertEqual(model.entries.count, 2)
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
        // MVP9.5 — immediate-children-only. `personal/email` has two
        // direct children (`gmail`, `jane+filter@example.com`). The
        // top-level `personal` folder would have zero under the new
        // semantics — that case is pinned by
        // `testEntries_folderFilter_topLevelExcludesNestedSubfolders`.
        let env = AppEnvironment.preview()
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        state.router.selectedFolder = "personal/email"
        state.searchQuery = ""

        let results = model.entries
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.path.hasPrefix("personal/email/") })
    }

    // MARK: - MVP9.5 — immediate-children-only folder selection

    func testEntries_folderFilter_topLevelExcludesNestedSubfolders() async {
        // MVP9.5 inverts the MVP9.3 prefix-match semantic. Selecting
        // `"personal"` (top-level) under the new rule shows ONLY
        // entries that live directly inside `personal/` — none, in
        // the fixture set, because every fixture has the shape
        // `top/middle/leaf`. Nested entries like
        // `personal/email/gmail` are reached by drilling into the
        // sidebar tree.
        let env = AppEnvironment.preview()
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        state.router.selectedFolder = "personal"
        let filtered = model.entries
        XCTAssertEqual(filtered.count, 0)
        // The previously-included deep entry must NOT appear under the
        // tightened semantics. This pins the inversion against any
        // future regression to the old prefix-match.
        XCTAssertFalse(filtered.contains { $0.path == "personal/email/gmail" })
    }

    func testEntries_folderFilter_nestedSelection_narrowsToImmediateChildren() {
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
        // The fixture covers both the exact-path arm (`system`) AND an
        // immediate child (`system/foo`) AND asserts that a nested
        // grandchild (`system/work/email`) is excluded under MVP9.5
        // immediate-children semantics.
        let entries = [
            PassEntry(path: "system"),
            PassEntry(path: "system/foo"),
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
        XCTAssertTrue(filtered.contains { $0.path == "system/foo" })
        XCTAssertFalse(filtered.contains { $0.path == "system/work/email" })
    }

    // MARK: - MVP9.5 — new immediate-children-only coverage

    func testEntries_folderFilter_excludesGrandchildren() {
        // Selecting `"a"` must include `a/b` (immediate child) and
        // exclude `a/c/d` (grandchild) and `a/c/e/f` (great-grandchild)
        // even though all three share the `a/` prefix.
        let entries = [
            PassEntry(path: "a/b"),
            PassEntry(path: "a/c/d"),
            PassEntry(path: "a/c/e/f"),
        ]
        let state = AppState()
        state.router.selectedFolder = "a"

        let env = AppEnvironment.preview()
        let model = EntryListModel(environment: env, state: state)
        model.setAllEntriesForTesting(entries)

        let filtered = model.entries
        XCTAssertEqual(filtered.count, 1)
        XCTAssertTrue(filtered.contains { $0.path == "a/b" })
        XCTAssertFalse(filtered.contains { $0.path == "a/c/d" })
        XCTAssertFalse(filtered.contains { $0.path == "a/c/e/f" })
    }

    func testEntries_folderFilter_nestedSelectionExcludesDeeperNesting() {
        // Selecting `"a/b"` must include direct children `a/b/c` and
        // `a/b/d` but exclude `a/b/e/f` (grandchild of the selection).
        let entries = [
            PassEntry(path: "a/b/c"),
            PassEntry(path: "a/b/d"),
            PassEntry(path: "a/b/e/f"),
        ]
        let state = AppState()
        state.router.selectedFolder = "a/b"

        let env = AppEnvironment.preview()
        let model = EntryListModel(environment: env, state: state)
        model.setAllEntriesForTesting(entries)

        let filtered = model.entries
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains { $0.path == "a/b/c" })
        XCTAssertTrue(filtered.contains { $0.path == "a/b/d" })
        XCTAssertFalse(filtered.contains { $0.path == "a/b/e/f" })
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
