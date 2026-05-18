import XCTest
@testable import Kizba

@MainActor
final class SettingsKeyMigrationTests: XCTestCase {

    private let namespacePrefix = "app.kizba.settings."

    private func namespaced(_ key: String) -> String {
        namespacePrefix + key
    }

    private func withIsolatedUserDefaults(_ body: (UserDefaults) -> Void) {
        let suiteName = "KizbaTests.SettingsKeyMigrationTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        body(defaults)
    }

    func testLegacyTrueMigratesToNewKeyAndRemovesLegacy() {
        withIsolatedUserDefaults { defaults in
            let legacyKey = namespaced(SettingsKeys.touchIDPerRevealEnabled)
            let newKey = namespaced(SettingsKeys.touchIDForSensitiveActions)
            defaults.set(true, forKey: legacyKey)

            _ = UserDefaultsSettingsStore(userDefaults: defaults)

            XCTAssertEqual(defaults.object(forKey: newKey) as? Bool, true)
            XCTAssertNil(defaults.object(forKey: legacyKey))
        }
    }

    func testLegacyFalseMigratesToNewKeyAndRemovesLegacy() {
        withIsolatedUserDefaults { defaults in
            let legacyKey = namespaced(SettingsKeys.touchIDPerRevealEnabled)
            let newKey = namespaced(SettingsKeys.touchIDForSensitiveActions)
            defaults.set(false, forKey: legacyKey)

            _ = UserDefaultsSettingsStore(userDefaults: defaults)

            XCTAssertEqual(defaults.object(forKey: newKey) as? Bool, false)
            XCTAssertNil(defaults.object(forKey: legacyKey))
        }
    }

    func testMissingLegacyRegistersNewKeyDefaultFalse() {
        withIsolatedUserDefaults { defaults in
            let newKey = namespaced(SettingsKeys.touchIDForSensitiveActions)

            let store = UserDefaultsSettingsStore(userDefaults: defaults)

            XCTAssertEqual(store.value(for: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions)), false)
            XCTAssertEqual(defaults.object(forKey: newKey) as? Bool, false)
        }
    }

    func testExistingNewKeyIsNotOverwrittenByLegacyValue() {
        withIsolatedUserDefaults { defaults in
            let legacyKey = namespaced(SettingsKeys.touchIDPerRevealEnabled)
            let newKey = namespaced(SettingsKeys.touchIDForSensitiveActions)
            defaults.set(false, forKey: legacyKey)
            defaults.set(true, forKey: newKey)

            _ = UserDefaultsSettingsStore(userDefaults: defaults)

            XCTAssertEqual(defaults.object(forKey: newKey) as? Bool, true)
            XCTAssertEqual(defaults.object(forKey: legacyKey) as? Bool, false)
        }
    }
}
