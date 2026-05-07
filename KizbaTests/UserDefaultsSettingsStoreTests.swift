import XCTest
@testable import Kizba

final class UserDefaultsSettingsStoreTests: XCTestCase {

    let suiteName = "KizbaTests.UserDefaultsSettingsStoreTests"
    var userDefaults: UserDefaults!
    var store: UserDefaultsSettingsStore!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
        store = UserDefaultsSettingsStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        store = nil
        super.tearDown()
    }

    func testRoundTripPerType() {
        let sKey = SettingsKey<String>("testString")
        let urlKey = SettingsKey<URL>("testURL")
        let iKey = SettingsKey<Int>("testInt")
        let dKey = SettingsKey<Double>("testDouble")
        let bKey = SettingsKey<Bool>("testBool")

        store.set("hello", for: sKey)
        XCTAssertEqual(store.value(for: sKey), "hello")

        let u = URL(string: "https://example.test")!
        store.set(u, for: urlKey)
        XCTAssertEqual(store.value(for: urlKey), u)

        store.set(42, for: iKey)
        XCTAssertEqual(store.value(for: iKey), 42)

        store.set(3.14, for: dKey)
        XCTAssertEqual(store.value(for: dKey), 3.14)

        store.set(true, for: bKey)
        XCTAssertEqual(store.value(for: bKey), true)
    }

    func testDefaults_clipboardClearDelaySeconds() {
        // The store init registers default 30 when not present.
        let raw = store.value(for: SettingsKey<Int>("clipboardClearDelaySeconds"))
        XCTAssertEqual(raw, 30)
    }

    func testClear() {
        let sKey = SettingsKey<String>("toClear")
        store.set("x", for: sKey)
        XCTAssertEqual(store.value(for: sKey), "x")
        store.removeValue(forKey: "toClear")
        XCTAssertNil(store.value(for: sKey))
    }

    func testNamespacingIsolation() {
        // Write a key that is *not* namespaced and ensure store doesn't read it.
        userDefaults.set("outside", forKey: "some.other.key")
        let k = SettingsKey<String>("some.other.key")
        XCTAssertNil(store.value(for: k))
    }

    func testResetClearsAll() {
        store.set("a", for: SettingsKey<String>("k1"))
        store.set(1, for: SettingsKey<Int>("k2"))
        store.resetAll()
        XCTAssertNil(store.value(for: SettingsKey<String>("k1")))
        XCTAssertNil(store.value(for: SettingsKey<Int>("k2")))
    }
}
