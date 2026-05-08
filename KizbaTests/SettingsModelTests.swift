import XCTest
@testable import Kizba

final class SettingsModelTests: XCTestCase {

    func makeInMemoryStore() -> AppEnvironment.InMemorySettingsStore {
        // Access the DEBUG-only in-memory class via AppEnvironment source.
        return AppEnvironment.InMemorySettingsStore()
    }

    // Fake discovery that records reDetect calls.
    private actor FakeDiscovery: BinaryLocating {
        var reDetectCalled = false

        func locate(_ binary: BinaryName) async -> URL? { nil }
        func reDetect() async {
            reDetectCalled = true
        }
    }

    func testDefaultsClipboardDelay() {
        let store = makeInMemoryStore()
        // Ensure no explicit value present
        store.removeValue(forKey: "clipboardClearDelaySeconds")

        let discovery = StubBinaryLocator(paths: [:])
        let model = SettingsModel(settings: store, discovery: discovery)

        XCTAssertEqual(model.clipboardClearDelaySeconds, 30)
    }

    func testSetAndGetOverrides() {
        let store = makeInMemoryStore()
        let discovery = StubBinaryLocator(paths: [:])

        var model = SettingsModel(settings: store, discovery: discovery)
        model.storePathOverride = "/tmp/store"
        model.passBinaryOverride = "/usr/bin/pass"
        model.gpgBinaryOverride = "/usr/bin/gpg"
        model.pinentryBinaryOverride = "/usr/local/bin/pinentry-mac"
        model.clipboardClearDelaySeconds = 45

        model.save()

        // Create fresh model backed by same store
        let fresh = SettingsModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.storePathOverride, "/tmp/store")
        XCTAssertEqual(fresh.passBinaryOverride, "/usr/bin/pass")
        XCTAssertEqual(fresh.gpgBinaryOverride, "/usr/bin/gpg")
        XCTAssertEqual(fresh.pinentryBinaryOverride, "/usr/local/bin/pinentry-mac")
        XCTAssertEqual(fresh.clipboardClearDelaySeconds, 45)
    }

    func testResetToDefaults() {
        let store = makeInMemoryStore()
        let discovery = StubBinaryLocator(paths: [:])

        var model = SettingsModel(settings: store, discovery: discovery)
        model.storePathOverride = "x"
        model.passBinaryOverride = "y"
        model.clipboardClearDelaySeconds = 99
        model.save()

        model.resetToDefaults()

        // New model sees cleared values
        let fresh = SettingsModel(settings: store, discovery: discovery)
        XCTAssertNil(fresh.storePathOverride)
        XCTAssertNil(fresh.passBinaryOverride)
        XCTAssertEqual(fresh.clipboardClearDelaySeconds, 30)
    }

    func testReDetectTriggersDiscovery() async {
        let store = makeInMemoryStore()
        let fake = FakeDiscovery()
        let model = SettingsModel(settings: store, discovery: fake)

        XCTAssertFalse(model.isDetectingBinaries)

        await model.reDetectBinaries()

        // After call completes, flag should be false again and fake recorded
        XCTAssertFalse(model.isDetectingBinaries)

        let called = await fake.reDetectCalled
        XCTAssertTrue(called)
    }
}
