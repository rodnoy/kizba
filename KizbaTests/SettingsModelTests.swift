import XCTest
@testable import Kizba

@MainActor
final class SettingsModelTests: XCTestCase {

    // Stub locator local to this test file.
    private struct TestBinaryLocator: BinaryLocating {
        var paths: [BinaryName: URL] = [:]
        func locate(_ binary: BinaryName) async -> URL? { paths[binary] }
        func reDetect() async {}
    }

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

        let discovery = TestBinaryLocator(paths: [:])
        let model = SettingsModel(settings: store, discovery: discovery)

        XCTAssertEqual(model.clipboardClearDelaySeconds, 30)
    }

    func testDefaultsGitOperationTimeout() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])
        let model = SettingsModel(settings: store, discovery: discovery)

        XCTAssertEqual(model.gitOperationTimeoutSeconds, 60)
    }

    func testSetAndGetOverrides() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

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
        let discovery = TestBinaryLocator(paths: [:])

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

    func testGitOperationTimeoutPersistsOnSave() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        var model = SettingsModel(settings: store, discovery: discovery)
        model.gitOperationTimeoutSeconds = 120
        model.save()

        let fresh = SettingsModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.gitOperationTimeoutSeconds, 120)
    }

    func testGitOperationTimeoutResetsToDefault() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        var model = SettingsModel(settings: store, discovery: discovery)
        model.gitOperationTimeoutSeconds = 200
        model.save()

        model.resetToDefaults()

        let fresh = SettingsModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.gitOperationTimeoutSeconds, 60)
    }

    func testGitOperationTimeoutBoundsAreSane() {
        XCTAssertEqual(SettingsKeys.gitOperationTimeoutBounds, 10...300)
        XCTAssertEqual(SettingsKeys.defaultGitOperationTimeoutSeconds, 60)
        XCTAssertTrue(SettingsKeys.gitOperationTimeoutBounds.contains(SettingsKeys.defaultGitOperationTimeoutSeconds))
    }

    func testGitTimeout_accessibilityValue_likeString() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])
        let model = SettingsModel(settings: store, discovery: discovery)

        let accessibilityValue = "\(model.gitOperationTimeoutSeconds) seconds"
        XCTAssertEqual(accessibilityValue, "60 seconds")
        XCTAssertFalse(accessibilityValue.isEmpty)
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
