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

        state.selectedFolder = "work"

        let filtered = model.entries
        XCTAssertEqual(filtered.count, 8)
        XCTAssertTrue(filtered.allSatisfy { $0.path.hasPrefix("work/") })

        state.selectedFolder = "archive"
        XCTAssertEqual(model.entries.count, 5)
        XCTAssertTrue(model.entries.allSatisfy { $0.path.hasPrefix("archive/") })

        state.selectedFolder = "personal"
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
        state.selectedFolder = "personal"
        state.searchQuery = "wifi"
        let wifi = model.entries
        XCTAssertEqual(wifi.count, 2)
        XCTAssertTrue(wifi.allSatisfy { $0.path.hasPrefix("personal/wifi/") })

        // Empty query restores the folder-only filter.
        state.searchQuery = ""
        XCTAssertEqual(model.entries.count, 7)
    }

    func testSelect_updatesAppStateSelectedEntryID() async {
        let env = AppEnvironment.preview()
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        XCTAssertNil(state.selectedEntryID)

        let target = model.allEntries.first { $0.path == "work/aws/root" }
        XCTAssertNotNil(target)
        model.select(entryID: target?.id)

        XCTAssertEqual(state.selectedEntryID, "work/aws/root")

        model.select(entryID: nil)
        XCTAssertNil(state.selectedEntryID)
    }
}
