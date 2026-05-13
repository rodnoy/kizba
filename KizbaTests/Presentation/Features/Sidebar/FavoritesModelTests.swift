//
//  FavoritesModelTests.swift
//  KizbaTests
//
//  Unit tests for the sidebar favorites view model.
//

import XCTest
@testable import Kizba

@MainActor
final class FavoritesModelTests: XCTestCase {

    func testLoad_populatesFavoritesFromStore() async {
        let store = FakeFavoritesStore(initialFavorites: ["a", "b"])
        let model = FavoritesModel(store: store)

        await model.load()

        XCTAssertEqual(model.favorites, ["a", "b"].sorted())
    }

    func testToggle_addsFavorite() async {
        let store = FakeFavoritesStore()
        let model = FavoritesModel(store: store)

        await model.load()
        await model.toggle("entry/x")

        let isFavorite = await store.isFavorite("entry/x")
        XCTAssertTrue(isFavorite)
        XCTAssertEqual(model.favorites, ["entry/x"])
    }

    func testToggle_removesFavorite() async {
        let store = FakeFavoritesStore(initialFavorites: ["entry/x"])
        let model = FavoritesModel(store: store)

        await model.load()
        await model.toggle("entry/x")

        let isFavorite = await store.isFavorite("entry/x")
        XCTAssertFalse(isFavorite)
        XCTAssertEqual(model.favorites, [])
    }

    func testIsFavorite_returnsCorrectValue() async {
        let store = FakeFavoritesStore(initialFavorites: ["entry/x"])
        let model = FavoritesModel(store: store)

        let existing = await model.isFavorite("entry/x")
        let missing = await model.isFavorite("entry/missing")

        XCTAssertTrue(existing)
        XCTAssertFalse(missing)
    }

    func testObservesStoreChanges() async throws {
        let store = FakeFavoritesStore()
        let model = FavoritesModel(store: store)

        await model.load()
        try await Task.sleep(for: .milliseconds(50))

        await store.addFavorite("entry/z")
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(model.favorites, ["entry/z"])
    }

    func testStop_cancelsObservation() async throws {
        let store = FakeFavoritesStore()
        let model = FavoritesModel(store: store)

        await model.load()
        model.stop()

        await store.addFavorite("entry/z")
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(model.favorites, [])
    }

    func testFavorites_areSorted() async {
        let store = FakeFavoritesStore(initialFavorites: ["z", "a", "m"])
        let model = FavoritesModel(store: store)

        await model.load()

        XCTAssertEqual(model.favorites, ["a", "m", "z"])
    }
}
