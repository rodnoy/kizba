import XCTest
@testable import Kizba

@MainActor
final class UserDefaultsRecentEntriesStoreTests: XCTestCase {

    func testRecord_addsPath() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsRecentEntriesStore(defaults: defaults)

        await store.record("entry/a")

        let paths = await store.recentPaths()
        XCTAssertEqual(paths, ["entry/a"])
    }

    func testRecord_movesExistingToFront() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsRecentEntriesStore(defaults: defaults)

        await store.record("entry/a")
        await store.record("entry/b")
        await store.record("entry/a")

        let paths = await store.recentPaths()
        XCTAssertEqual(paths, ["entry/a", "entry/b"])
    }

    func testRecord_evictsOldestBeyondMax() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsRecentEntriesStore(defaults: defaults, maxCount: 3)

        await store.record("entry/a")
        await store.record("entry/b")
        await store.record("entry/c")
        await store.record("entry/d")

        let paths = await store.recentPaths()
        XCTAssertEqual(paths, ["entry/d", "entry/c", "entry/b"])
    }

    func testRecentPaths_returnsOrderedList() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let firstStore = UserDefaultsRecentEntriesStore(defaults: defaults)

        await firstStore.record("entry/a")
        await firstStore.record("entry/b")
        await firstStore.record("entry/c")

        let secondStore = UserDefaultsRecentEntriesStore(defaults: defaults)
        let persisted = await secondStore.recentPaths()
        XCTAssertEqual(persisted, ["entry/c", "entry/b", "entry/a"])
    }

    func testClear_emptiesList() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsRecentEntriesStore(defaults: defaults)

        await store.record("entry/a")
        await store.record("entry/b")
        await store.clear()

        let paths = await store.recentPaths()
        XCTAssertEqual(paths, [])
    }

    func testRecentsChanged_emitsOnRecord() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsRecentEntriesStore(defaults: defaults)

        var didEmit = false
        let observation = Task {
            for await _ in store.recentsChanged {
                didEmit = true
                break
            }
        }
        defer { observation.cancel() }
        try? await Task.sleep(for: .milliseconds(50))

        await store.record("entry/a")

        await waitUntil({ didEmit }, timeout: 1.0, message: "Expected recentsChanged after record")
    }

    func testRecentsChanged_emitsOnClear() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsRecentEntriesStore(defaults: defaults)

        await store.record("entry/a")

        var didEmit = false
        let observation = Task {
            for await _ in store.recentsChanged {
                didEmit = true
                break
            }
        }
        defer { observation.cancel() }
        try? await Task.sleep(for: .milliseconds(50))

        await store.clear()

        await waitUntil({ didEmit }, timeout: 1.0, message: "Expected recentsChanged after clear")
    }

    private func makeIsolatedDefaults() -> (String, UserDefaults) {
        let suiteName = "kizba.recents.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated UserDefaults suite")
            return (suiteName, .standard)
        }
        defaults.removePersistentDomain(forName: suiteName)
        return (suiteName, defaults)
    }
}
