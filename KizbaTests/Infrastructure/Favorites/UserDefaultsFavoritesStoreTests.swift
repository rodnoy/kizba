import XCTest
@testable import Kizba

@MainActor
final class UserDefaultsFavoritesStoreTests: XCTestCase {

    func testEmptyInitialState() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsFavoritesStore(userDefaults: defaults)

        let allFavorites = await store.allFavorites()
        let isFavorite = await store.isFavorite("entry/a")
        XCTAssertEqual(allFavorites, [])
        XCTAssertFalse(isFavorite)
    }

    func testAddRemoveTogglePersistence() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstStore = UserDefaultsFavoritesStore(userDefaults: defaults)

        await firstStore.addFavorite("entry/a")
        let isFavoriteAfterAdd = await firstStore.isFavorite("entry/a")
        let allAfterAdd = await firstStore.allFavorites()
        XCTAssertTrue(isFavoriteAfterAdd)
        XCTAssertEqual(allAfterAdd, ["entry/a"])

        await firstStore.toggleFavorite("entry/a")
        let isFavoriteAfterToggle = await firstStore.isFavorite("entry/a")
        let allAfterToggle = await firstStore.allFavorites()
        XCTAssertFalse(isFavoriteAfterToggle)
        XCTAssertEqual(allAfterToggle, [])

        await firstStore.addFavorite("entry/a")
        let secondStore = UserDefaultsFavoritesStore(userDefaults: defaults)
        let secondIsFavorite = await secondStore.isFavorite("entry/a")
        let secondAllFavorites = await secondStore.allFavorites()
        XCTAssertTrue(secondIsFavorite)
        XCTAssertEqual(secondAllFavorites, ["entry/a"])
    }

    func testDuplicateAddIdempotent() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsFavoritesStore(userDefaults: defaults)

        await store.addFavorite("entry/a")
        await store.addFavorite("entry/a")

        let allFavorites = await store.allFavorites()
        XCTAssertEqual(allFavorites, ["entry/a"])
    }

    private func makeIsolatedDefaults() -> (String, UserDefaults) {
        let suiteName = "kizba.favorites.tests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated UserDefaults suite")
            return (suiteName, .standard)
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        return (suiteName, userDefaults)
    }
}
