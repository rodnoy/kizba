//
//  UserDefaultsFolderExpansionStoreTests.swift
//  KizbaTests
//
//  Persistence + change-stream coverage for
//  ``UserDefaultsFolderExpansionStore``. Mirrors the discipline used
//  by ``UserDefaultsFavoritesStoreTests``: every test owns an
//  isolated ``UserDefaults`` suite so concurrent runs cannot stomp
//  on one another.
//

import XCTest
@testable import Kizba

@MainActor
final class UserDefaultsFolderExpansionStoreTests: XCTestCase {

    func testEmptyInitialState() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsFolderExpansionStore(userDefaults: defaults)
        let isExpanded = await store.isExpanded("anything")
        XCTAssertFalse(isExpanded)
    }

    func testSetExpanded_persistsAcrossInstances() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstStore = UserDefaultsFolderExpansionStore(userDefaults: defaults)
        await firstStore.setExpanded("system/work", expanded: true)

        let secondStore = UserDefaultsFolderExpansionStore(userDefaults: defaults)
        let workIsExpanded = await secondStore.isExpanded("system/work")
        let otherIsExpanded = await secondStore.isExpanded("other")
        XCTAssertTrue(workIsExpanded)
        XCTAssertFalse(otherIsExpanded)
    }

    func testSetExpanded_toggleRoundTrip() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsFolderExpansionStore(userDefaults: defaults)
        await store.setExpanded("a", expanded: true)
        let afterExpand = await store.isExpanded("a")
        XCTAssertTrue(afterExpand)

        await store.setExpanded("a", expanded: false)
        let afterCollapse = await store.isExpanded("a")
        XCTAssertFalse(afterCollapse)
    }

    func testSetExpanded_isIdempotent_andDoesNotDuplicatePersisted() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsFolderExpansionStore(userDefaults: defaults)
        await store.setExpanded("system", expanded: true)
        await store.setExpanded("system", expanded: true)

        // The persisted array must be a single entry; Set discipline
        // is enforced at the in-memory layer and mirrored to defaults.
        let persisted = defaults.array(forKey: StorageKeys.folderExpansionV1) as? [String] ?? []
        XCTAssertEqual(persisted, ["system"])
    }

    func testSetExpanded_storesSetAsArray_withMultipleEntries() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsFolderExpansionStore(userDefaults: defaults)
        await store.setExpanded("a", expanded: true)
        await store.setExpanded("b", expanded: true)
        await store.setExpanded("c", expanded: true)

        let persisted = defaults.array(forKey: StorageKeys.folderExpansionV1) as? [String] ?? []
        XCTAssertEqual(Set(persisted), Set(["a", "b", "c"]))
    }

    private func makeIsolatedDefaults() -> (String, UserDefaults) {
        let suiteName = "kizba.folder-expansion.tests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated UserDefaults suite")
            return (suiteName, .standard)
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        return (suiteName, userDefaults)
    }
}
