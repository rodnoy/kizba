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

    // MARK: - MVP6.G.3 — namespaced storage key + one-shot legacy migration

    func testInit_migratesLegacyFavorites_onceWhenNewKeyAbsent() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(["a", "b"], forKey: StorageKeys.legacyFavoritesEntries)

        let store = UserDefaultsFavoritesStore(userDefaults: defaults)
        let all = await store.allFavorites()

        XCTAssertEqual(all, Set(["a", "b"]))
        XCTAssertEqual(
            (defaults.array(forKey: StorageKeys.favoritesEntriesV1) as? [String]).map { Set($0) },
            Set(["a", "b"])
        )
        XCTAssertNil(
            defaults.object(forKey: StorageKeys.legacyFavoritesEntries),
            "Legacy key must be removed after successful migration"
        )
    }

    func testInit_doesNotOverwriteNewKey_whenBothPresent() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Both legacy and new are populated — new key must win.
        defaults.set(["x"], forKey: StorageKeys.legacyFavoritesEntries)
        defaults.set(["y", "z"], forKey: StorageKeys.favoritesEntriesV1)

        let store = UserDefaultsFavoritesStore(userDefaults: defaults)
        let all = await store.allFavorites()

        XCTAssertEqual(all, Set(["y", "z"]), "New-key data must take precedence over legacy")
        // Forensic: legacy is intentionally NOT cleaned up when no migration occurred,
        // so any out-of-band investigation still has the original payload to inspect.
        XCTAssertEqual(
            defaults.array(forKey: StorageKeys.legacyFavoritesEntries) as? [String],
            ["x"],
            "Legacy key must be left untouched when the new key already has data (forensic preservation)"
        )
    }

    func testInit_idempotent_secondConstructionIsNoOp() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(["a", "b"], forKey: StorageKeys.legacyFavoritesEntries)

        // First construction performs the migration.
        let firstStore = UserDefaultsFavoritesStore(userDefaults: defaults)
        let firstAll = await firstStore.allFavorites()
        XCTAssertEqual(firstAll, Set(["a", "b"]))

        // Second construction with the same defaults must be a pure read,
        // returning the migrated set with no duplicates or regressions.
        let secondStore = UserDefaultsFavoritesStore(userDefaults: defaults)
        let secondAll = await secondStore.allFavorites()
        XCTAssertEqual(secondAll, Set(["a", "b"]))
        XCTAssertNil(
            defaults.object(forKey: StorageKeys.legacyFavoritesEntries),
            "Legacy key must remain absent after the second construction"
        )
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
