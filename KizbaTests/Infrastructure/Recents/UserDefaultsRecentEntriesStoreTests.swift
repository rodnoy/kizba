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

    // MARK: - MVP6.A.2 — maxCount default + setMaxCount

    func testInit_usesDefaultFromSettingsKey() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsRecentEntriesStore(defaults: defaults)

        // Record more entries than the default cap; the oldest must be
        // evicted at the SettingsKeys.defaultRecentsLimit boundary.
        let total = SettingsKeys.defaultRecentsLimit + 3
        for i in 0..<total {
            await store.record("entry/\(i)")
        }

        let paths = await store.recentPaths()
        XCTAssertEqual(paths.count, SettingsKeys.defaultRecentsLimit)
        // record() inserts at index 0; newest entries survive.
        let expected = (0..<total)
            .map { "entry/\($0)" }
            .reversed()
            .prefix(SettingsKeys.defaultRecentsLimit)
        XCTAssertEqual(paths, Array(expected))
    }

    func testSetMaxCount_truncatesAndEmitsOnce() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsRecentEntriesStore(defaults: defaults)

        for i in 0..<SettingsKeys.defaultRecentsLimit {
            await store.record("entry/\(i)")
        }
        let initialCount = await store.recentPaths().count
        XCTAssertEqual(initialCount, SettingsKeys.defaultRecentsLimit)

        // Subscribe BEFORE mutating, count events for a short window.
        let counter = EventCounter()
        let observation = Task {
            for await _ in store.recentsChanged {
                await counter.increment()
            }
        }
        defer { observation.cancel() }
        try? await Task.sleep(for: .milliseconds(50))

        await store.setMaxCount(4)

        // Allow the yield to propagate.
        try? await Task.sleep(for: .milliseconds(100))

        let paths = await store.recentPaths()
        XCTAssertEqual(paths.count, 4)
        // The four newest entries (highest indices) must survive,
        // in newest-first order — consistent with testRecord_evictsOldestBeyondMax.
        let expected = (0..<SettingsKeys.defaultRecentsLimit)
            .map { "entry/\($0)" }
            .reversed()
            .prefix(4)
        XCTAssertEqual(paths, Array(expected))

        let emitted = await counter.value
        XCTAssertEqual(emitted, 1, "setMaxCount must emit exactly one change event")
    }

    func testSetMaxCount_clampsLow() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsRecentEntriesStore(defaults: defaults)

        await store.setMaxCount(1) // Below SettingsKeys.minRecentsLimit (3).

        for i in 0..<10 {
            await store.record("entry/\(i)")
        }

        let paths = await store.recentPaths()
        XCTAssertEqual(paths.count, SettingsKeys.minRecentsLimit)
    }

    func testSetMaxCount_clampsHigh() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsRecentEntriesStore(defaults: defaults)

        await store.setMaxCount(99) // Above SettingsKeys.maxRecentsLimit (7).

        for i in 0..<10 {
            await store.record("entry/\(i)")
        }

        let paths = await store.recentPaths()
        XCTAssertEqual(paths.count, SettingsKeys.maxRecentsLimit)
    }

    func testSetMaxCount_noopWhenUnchanged() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsRecentEntriesStore(defaults: defaults)

        await store.record("entry/a")

        let counter = EventCounter()
        let observation = Task {
            for await _ in store.recentsChanged {
                await counter.increment()
            }
        }
        defer { observation.cancel() }
        try? await Task.sleep(for: .milliseconds(50))

        // Default is SettingsKeys.defaultRecentsLimit; setting same value is a no-op.
        await store.setMaxCount(SettingsKeys.defaultRecentsLimit)
        try? await Task.sleep(for: .milliseconds(100))

        let emitted = await counter.value
        XCTAssertEqual(emitted, 0, "setMaxCount must be a no-op when the clamped value is unchanged")
    }

    // MARK: - MVP6.G.3 / H.1 — namespaced storage key + legacy cleanup

    func testInit_readsFromNewNamespacedKey() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(["a", "b"], forKey: StorageKeys.recentsEntriesV2)

        let store = UserDefaultsRecentEntriesStore(defaults: defaults)
        let paths = await store.recentPaths()
        XCTAssertEqual(paths, ["a", "b"])
    }

    func testInit_ignoresLegacyKey_andRemovesIt() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Seed legacy slot (the DEBUG fixture-leak vector).
        defaults.set(["leaked/fixture"], forKey: StorageKeys.legacyRecentsEntries)

        let store = UserDefaultsRecentEntriesStore(defaults: defaults)
        let paths = await store.recentPaths()

        XCTAssertTrue(paths.isEmpty, "Legacy Recents values must NOT migrate — fresh start by design")
        XCTAssertNil(
            defaults.object(forKey: StorageKeys.legacyRecentsEntries),
            "Legacy key must be removed during init"
        )
    }

    func testRecord_persistsToNewKey_only() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsRecentEntriesStore(defaults: defaults)
        await store.record("x")

        XCTAssertEqual(
            defaults.array(forKey: StorageKeys.recentsEntriesV2) as? [String],
            ["x"]
        )
        XCTAssertNil(
            defaults.object(forKey: StorageKeys.legacyRecentsEntries),
            "record() must never write to the bare legacy key"
        )
        XCTAssertNil(
            defaults.object(forKey: StorageKeys.legacyRecentsEntriesV1),
            "record() must never write to the legacy .v1 key"
        )
    }

    // MARK: - MVP6.H.1 — fixture-leak hotfix (v1 → v2 schema bump)

    func testInit_ignoresLegacyV1Key_andRemovesIt() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Seed the polluted .v1 slot (the actual MVP6.H.1 fixture-leak vector —
        // DEBUG MockPassManager wrote fixture paths here before G.3 even shipped).
        defaults.set(["fixture/old/path"], forKey: StorageKeys.legacyRecentsEntriesV1)

        let store = UserDefaultsRecentEntriesStore(defaults: defaults)
        let paths = await store.recentPaths()

        XCTAssertTrue(paths.isEmpty, "Legacy .v1 fixtures must not migrate to .v2")
        XCTAssertNil(
            defaults.object(forKey: StorageKeys.legacyRecentsEntriesV1),
            "Legacy .v1 key must be removed on init"
        )
    }

    func testInit_ignoresBothLegacyKeys() async {
        let (suiteName, defaults) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(["bare/legacy"], forKey: StorageKeys.legacyRecentsEntries)
        defaults.set(["v1/fixture"], forKey: StorageKeys.legacyRecentsEntriesV1)

        let store = UserDefaultsRecentEntriesStore(defaults: defaults)
        let paths = await store.recentPaths()

        XCTAssertTrue(paths.isEmpty, "Neither legacy key may seed .v2")
        XCTAssertNil(defaults.object(forKey: StorageKeys.legacyRecentsEntries))
        XCTAssertNil(defaults.object(forKey: StorageKeys.legacyRecentsEntriesV1))
    }

    private actor EventCounter {
        private(set) var value: Int = 0
        func increment() { value += 1 }
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
