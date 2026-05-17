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

    /// Helper that builds a `SettingsModel` with the new MVP6 Phase A.4
    /// `recentStore` parameter defaulted to a fresh `FakeRecentEntriesStore`.
    /// Existing tests do not care which actor store is plugged in — only
    /// tests that assert `setMaxCount` propagation construct the model
    /// manually so they retain a reference to the fake.
    private func makeModel(
        settings: any SettingsStoring,
        discovery: any BinaryLocating,
        recentStore: any RecentEntriesStoring = FakeRecentEntriesStore()
    ) -> SettingsModel {
        SettingsModel(settings: settings, discovery: discovery, recentStore: recentStore)
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
        let model = makeModel(settings: store, discovery: discovery)

        XCTAssertEqual(model.clipboardClearDelaySeconds, 30)
    }

    func testDefaultsGitOperationTimeout() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])
        let model = makeModel(settings: store, discovery: discovery)

        XCTAssertEqual(model.gitOperationTimeoutSeconds, 60)
    }

    func testSetAndGetOverrides() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        var model = makeModel(settings: store, discovery: discovery)
        model.storePathOverride = "/tmp/store"
        model.passBinaryOverride = "/usr/bin/pass"
        model.gpgBinaryOverride = "/usr/bin/gpg"
        model.pinentryBinaryOverride = "/usr/local/bin/pinentry-mac"
        model.clipboardClearDelaySeconds = 45

        model.save()

        // Create fresh model backed by same store
        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.storePathOverride, "/tmp/store")
        XCTAssertEqual(fresh.passBinaryOverride, "/usr/bin/pass")
        XCTAssertEqual(fresh.gpgBinaryOverride, "/usr/bin/gpg")
        XCTAssertEqual(fresh.pinentryBinaryOverride, "/usr/local/bin/pinentry-mac")
        XCTAssertEqual(fresh.clipboardClearDelaySeconds, 45)
    }

    func testResetToDefaults() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        var model = makeModel(settings: store, discovery: discovery)
        model.storePathOverride = "x"
        model.passBinaryOverride = "y"
        model.clipboardClearDelaySeconds = 99
        model.save()

        model.resetToDefaults()

        // New model sees cleared values
        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertNil(fresh.storePathOverride)
        XCTAssertNil(fresh.passBinaryOverride)
        XCTAssertEqual(fresh.clipboardClearDelaySeconds, 30)
    }

    func testGitOperationTimeoutPersistsOnSave() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        var model = makeModel(settings: store, discovery: discovery)
        model.gitOperationTimeoutSeconds = 120
        model.save()

        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.gitOperationTimeoutSeconds, 120)
    }

    func testGitOperationTimeoutResetsToDefault() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        var model = makeModel(settings: store, discovery: discovery)
        model.gitOperationTimeoutSeconds = 200
        model.save()

        model.resetToDefaults()

        let fresh = makeModel(settings: store, discovery: discovery)
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
        let model = makeModel(settings: store, discovery: discovery)

        let accessibilityValue = "\(model.gitOperationTimeoutSeconds) seconds"
        XCTAssertEqual(accessibilityValue, "60 seconds")
        XCTAssertFalse(accessibilityValue.isEmpty)
    }

    func testReDetectTriggersDiscovery() async {
        let store = makeInMemoryStore()
        let fake = FakeDiscovery()
        let model = makeModel(settings: store, discovery: fake)

        XCTAssertFalse(model.isDetectingBinaries)

        await model.reDetectBinaries()

        // After call completes, flag should be false again and fake recorded
        XCTAssertFalse(model.isDetectingBinaries)

        let called = await fake.reDetectCalled
        XCTAssertTrue(called)
    }

    func testShowInMenuBar_defaultsToTrue() {
        let store = makeInMemoryStore()
        store.removeValue(forKey: SettingsKeys.showInMenuBar)

        let discovery = TestBinaryLocator(paths: [:])
        let model = makeModel(settings: store, discovery: discovery)

        XCTAssertTrue(model.showInMenuBar)
    }

    func testShowInMenuBar_persistsChange() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.showInMenuBar = false
        model.save()

        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertFalse(fresh.showInMenuBar)
    }

    func testReset_restoresShowInMenuBarDefault() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.showInMenuBar = false
        model.save()

        model.resetToDefaults()

        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.showInMenuBar, SettingsKeys.defaultShowInMenuBar)
    }

    // MARK: - MVP6 Phase A.4 — Recents controls

    func testShowRecents_defaultIsTrue() {
        let store = makeInMemoryStore()
        store.removeValue(forKey: SettingsKeys.showRecents)
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)

        XCTAssertTrue(model.showRecents)
        XCTAssertEqual(model.showRecents, SettingsKeys.defaultShowRecents)
    }

    func testShowRecents_persists() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.showRecents = false
        model.save()

        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertFalse(fresh.showRecents)
    }

    func testRecentsLimit_defaultIsSeven() {
        let store = makeInMemoryStore()
        store.removeValue(forKey: SettingsKeys.recentsLimit)
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)

        XCTAssertEqual(model.recentsLimit, SettingsKeys.defaultRecentsLimit)
        XCTAssertEqual(model.recentsLimit, 7)
    }

    func testRecentsLimit_persistsAndClampsHigh() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.recentsLimit = 99
        model.save()

        // `UserDefaultsSettingsStore` clamps on write to recentsLimitBounds (3...7).
        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.recentsLimit, SettingsKeys.maxRecentsLimit)
        XCTAssertEqual(fresh.recentsLimit, 7)
    }

    func testRecentsLimit_persistsAndClampsLow() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.recentsLimit = 1
        model.save()

        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.recentsLimit, SettingsKeys.minRecentsLimit)
        XCTAssertEqual(fresh.recentsLimit, 3)
    }

    func testSave_callsSetMaxCountOnRecentStore() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])
        let fake = FakeRecentEntriesStore()

        let model = makeModel(settings: store, discovery: discovery, recentStore: fake)
        model.recentsLimit = 5
        model.save()

        // `save()` dispatches the actor hop via `Task { ... }`; drain it
        // before asserting. Polling keeps the test resilient to scheduler
        // jitter without sleeping unconditionally.
        try? await waitForRecordedSetMaxCount(on: fake, count: 1, timeout: 1.0)

        let calls = await fake.setMaxCountCalls
        XCTAssertEqual(calls.last, 5)
        XCTAssertEqual(calls.count, 1)
    }

    func testSave_propagatesClampedValueToRecentStore() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])
        let fake = FakeRecentEntriesStore()

        let model = makeModel(settings: store, discovery: discovery, recentStore: fake)
        model.recentsLimit = 99 // Clamped to 7 by the settings store.
        model.save()

        try? await waitForRecordedSetMaxCount(on: fake, count: 1, timeout: 1.0)

        let calls = await fake.setMaxCountCalls
        // The model re-reads the persisted (clamped) value before
        // propagating, so the actor store sees the clamp too.
        XCTAssertEqual(calls.last, SettingsKeys.maxRecentsLimit)
    }

    // MARK: - Helpers

    /// Polls the fake until `setMaxCountCalls.count >= count` or `timeout`
    /// expires. Throws on timeout so the test fails fast rather than
    /// hanging the suite.
    private func waitForRecordedSetMaxCount(
        on fake: FakeRecentEntriesStore,
        count: Int,
        timeout: TimeInterval
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let current = await fake.setMaxCountCalls.count
            if current >= count { return }
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        XCTFail("Timed out waiting for setMaxCount call (expected \(count))")
    }
}
