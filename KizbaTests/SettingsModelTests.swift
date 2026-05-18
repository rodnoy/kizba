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
    ///
    /// `savedFlashDuration` defaults to 10 ms so the SaveState flash hop
    /// (`.saved → .idle`) does not slow the suite (MVP6 Phase B.2).
    private func makeModel(
        settings: any SettingsStoring,
        discovery: any BinaryLocating,
        recentStore: any RecentEntriesStoring = FakeRecentEntriesStore(),
        biometricAuth: (any BiometricAuthenticating)? = nil,
        savedFlashDuration: Duration = .milliseconds(10)
    ) -> SettingsModel {
        SettingsModel(
            settings: settings,
            discovery: discovery,
            recentStore: recentStore,
            biometricAuth: biometricAuth,
            savedFlashDuration: savedFlashDuration
        )
    }

    /// Helper for the MVP6 D.3 biometric-toggle matrix. Seeds the
    /// in-memory store with the desired initial value for the
    /// `touchIDForSensitiveActions` key, then constructs a SettingsModel
    /// with the supplied fake authenticator injected.
    private func makeModelWithBiometric(
        initialEnabled: Bool,
        fake: FakeBiometricAuthenticator
    ) -> SettingsModel {
        let store = makeInMemoryStore()
        store.set(initialEnabled, for: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions))
        let discovery = TestBinaryLocator(paths: [:])
        return makeModel(
            settings: store,
            discovery: discovery,
            biometricAuth: fake
        )
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

    func testSetAndGetOverrides() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.storePathOverride = "/tmp/store"
        model.passBinaryOverride = "/usr/bin/pass"
        model.gpgBinaryOverride = "/usr/bin/gpg"
        model.pinentryBinaryOverride = "/usr/local/bin/pinentry-mac"
        model.clipboardClearDelaySeconds = 45

        await model.save()

        // Create fresh model backed by same store
        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.storePathOverride, "/tmp/store")
        XCTAssertEqual(fresh.passBinaryOverride, "/usr/bin/pass")
        XCTAssertEqual(fresh.gpgBinaryOverride, "/usr/bin/gpg")
        XCTAssertEqual(fresh.pinentryBinaryOverride, "/usr/local/bin/pinentry-mac")
        XCTAssertEqual(fresh.clipboardClearDelaySeconds, 45)
    }

    func testResetToDefaults() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.storePathOverride = "x"
        model.passBinaryOverride = "y"
        model.clipboardClearDelaySeconds = 99
        await model.save()

        model.resetToDefaults()

        // New model sees cleared values
        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertNil(fresh.storePathOverride)
        XCTAssertNil(fresh.passBinaryOverride)
        XCTAssertEqual(fresh.clipboardClearDelaySeconds, 30)
    }

    func testGitOperationTimeoutPersistsOnSave() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.gitOperationTimeoutSeconds = 120
        await model.save()

        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.gitOperationTimeoutSeconds, 120)
    }

    func testGitOperationTimeoutResetsToDefault() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.gitOperationTimeoutSeconds = 200
        await model.save()

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

    func testShowInMenuBar_persistsChange() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.showInMenuBar = false
        await model.save()

        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertFalse(fresh.showInMenuBar)
    }

    func testReset_restoresShowInMenuBarDefault() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.showInMenuBar = false
        await model.save()

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

    func testShowRecents_persists() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.showRecents = false
        await model.save()

        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertFalse(fresh.showRecents)
    }

    // MARK: - MVP6 Phase G.1 — Favorites visibility toggle

    func testShowFavorites_defaultIsTrue() {
        let store = makeInMemoryStore()
        store.removeValue(forKey: SettingsKeys.showFavorites)
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)

        XCTAssertTrue(model.showFavorites)
        XCTAssertEqual(model.showFavorites, SettingsKeys.defaultShowFavorites)
    }

    func testShowFavorites_persists() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.showFavorites = false
        await model.save()

        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertFalse(fresh.showFavorites)
    }

    func testShowOTP_defaultIsTrue() {
        let store = makeInMemoryStore()
        store.removeValue(forKey: SettingsKeys.showOTP)
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)

        XCTAssertTrue(model.showOTP)
        XCTAssertEqual(model.showOTP, SettingsKeys.defaultShowOTP)
    }

    func testShowOTP_persists() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.showOTP = false
        await model.save()

        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertFalse(fresh.showOTP)
    }

    func testReset_restoresShowOTPDefault() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.showOTP = false
        await model.save()

        model.resetToDefaults()

        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.showOTP, SettingsKeys.defaultShowOTP)
    }

    func testHasChanges_flipsWhenShowOTPMutated() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        XCTAssertFalse(model.hasChanges)

        model.showOTP.toggle()
        XCTAssertTrue(model.hasChanges)

        model.showOTP.toggle()
        XCTAssertFalse(model.hasChanges)
    }

    func testHasChanges_flipsWhenShowFavoritesMutated() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        XCTAssertFalse(model.hasChanges,
                       "Freshly-loaded model should have a clean baseline")

        // Toggle the field — `hasChanges` should pick it up via the
        // private `SettingsSnapshot` diff (regression test for forgetting
        // to extend `currentSnapshot` / `initialSnapshot`).
        model.showFavorites.toggle()
        XCTAssertTrue(model.hasChanges,
                      "Mutating showFavorites must flip hasChanges to true")

        // Flip back — baseline restored.
        model.showFavorites.toggle()
        XCTAssertFalse(model.hasChanges,
                       "Restoring showFavorites should clear hasChanges")
    }

    func testRecentsLimit_defaultIsSeven() {
        let store = makeInMemoryStore()
        store.removeValue(forKey: SettingsKeys.recentsLimit)
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)

        XCTAssertEqual(model.recentsLimit, SettingsKeys.defaultRecentsLimit)
        XCTAssertEqual(model.recentsLimit, 7)
    }

    func testRecentsLimit_persistsAndClampsHigh() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.recentsLimit = 99
        await model.save()

        // `UserDefaultsSettingsStore` clamps on write to recentsLimitBounds (3...7).
        let fresh = makeModel(settings: store, discovery: discovery)
        XCTAssertEqual(fresh.recentsLimit, SettingsKeys.maxRecentsLimit)
        XCTAssertEqual(fresh.recentsLimit, 7)
    }

    func testRecentsLimit_persistsAndClampsLow() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.recentsLimit = 1
        await model.save()

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
        await model.save()

        // `save()` now awaits `setMaxCount` inline, so the recorded call
        // is already visible without polling. The helper remains for the
        // historical case but the count check below is sufficient.
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
        await model.save()

        let calls = await fake.setMaxCountCalls
        // The model re-reads the persisted (clamped) value before
        // propagating, so the actor store sees the clamp too.
        XCTAssertEqual(calls.last, SettingsKeys.maxRecentsLimit)
    }

    // MARK: - MVP6 Phase B.2 — dirty-tracking + SaveState

    func testHasChanges_isFalseAfterLoad() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)

        XCTAssertFalse(model.hasChanges)
        XCTAssertEqual(model.saveState, .idle)
    }

    func testHasChanges_becomesTrueAfterMutation() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        XCTAssertFalse(model.hasChanges)

        model.clipboardClearDelaySeconds = 99

        XCTAssertTrue(model.hasChanges)
    }

    func testHasChanges_falseAfterSave() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.storePathOverride = "/tmp/store"
        model.gitOperationTimeoutSeconds = 90
        XCTAssertTrue(model.hasChanges)

        await model.save()

        XCTAssertFalse(model.hasChanges)
    }

    func testSaveState_transitions_idle_saving_saved_idle() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        // Very short flash window so the test does not linger.
        let model = makeModel(
            settings: store,
            discovery: discovery,
            savedFlashDuration: .milliseconds(10)
        )

        XCTAssertEqual(model.saveState, .idle)

        // Trigger a real change so save() does not early-return.
        model.clipboardClearDelaySeconds = 77

        await model.save()

        // Awaiting `save()` runs the full flow including the post-flash
        // `.idle` hop, so by the time we resume the state has returned
        // to `.idle`.
        XCTAssertEqual(model.saveState, .idle)
        XCTAssertFalse(model.hasChanges)
    }

    func testSave_isNoopWhenNoChanges() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])
        let fake = FakeRecentEntriesStore()

        let model = makeModel(settings: store, discovery: discovery, recentStore: fake)
        XCTAssertFalse(model.hasChanges)

        await model.save()

        XCTAssertEqual(model.saveState, .idle)
        // The no-op guard short-circuits before the actor hop, so the
        // recents store never sees a setMaxCount call either.
        let calls = await fake.setMaxCountCalls
        XCTAssertTrue(calls.isEmpty)
    }

    func testReset_clearsHasChanges() {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        model.storePathOverride = "/tmp/x"
        model.clipboardClearDelaySeconds = 45
        XCTAssertTrue(model.hasChanges)

        model.resetToDefaults()

        XCTAssertFalse(model.hasChanges)
    }

    // MARK: - MVP6 Phase D.3 — biometric toggle behaviour matrix

    func testToggleBiometricOff_requiresAuth_successPersists() async {
        let fake = FakeBiometricAuthenticator(
            availability: .available,
            nextResult: .success
        )
        let model = makeModelWithBiometric(initialEnabled: true, fake: fake)
        XCTAssertTrue(model.touchIDForSensitiveActions)

        let result = await model.requestToggleBiometric(false)

        // `Result<Void, …>` is not Equatable (Void is not Equatable), so
        // assert via pattern match instead of `XCTAssertEqual`.
        guard case .success = result else {
            XCTFail("Expected success, got \(result)"); return
        }
        XCTAssertFalse(model.touchIDForSensitiveActions,
                       "Successful biometric auth must persist the disable")
        XCTAssertEqual(fake.authenticateCalls.count, 1,
                       "Disable path must present exactly one biometric prompt")
        XCTAssertTrue(fake.authenticateCalls[0].localizedCaseInsensitiveContains("Touch ID"),
                      "Prompt reason should mention Touch ID for user clarity")
    }

    func testToggleBiometricOff_authCancelled_leavesEnabled() async {
        let fake = FakeBiometricAuthenticator(
            availability: .available,
            nextResult: .cancelled
        )
        let model = makeModelWithBiometric(initialEnabled: true, fake: fake)

        let result = await model.requestToggleBiometric(false)

        guard case .failure(let err) = result else {
            XCTFail("Expected failure, got \(result)"); return
        }
        XCTAssertEqual(err, .cancelled)
        XCTAssertTrue(model.touchIDForSensitiveActions,
                      "Value must remain enabled when auth is cancelled")
        XCTAssertEqual(fake.authenticateCalls.count, 1)
    }

    func testToggleBiometricOn_persistsWithoutAuth() async {
        let fake = FakeBiometricAuthenticator(
            availability: .available,
            nextResult: .success
        )
        let model = makeModelWithBiometric(initialEnabled: false, fake: fake)

        let result = await model.requestToggleBiometric(true)

        guard case .success = result else {
            XCTFail("Expected success, got \(result)"); return
        }
        XCTAssertTrue(model.touchIDForSensitiveActions)
        XCTAssertEqual(fake.authenticateCalls.count, 0,
                       "Enabling biometric protection must not prompt the user")
    }

    func testBiometricAvailability_propagatesFromAuth() {
        let fake = FakeBiometricAuthenticator(availability: .unavailable(.notEnrolled))
        let model = makeModelWithBiometric(initialEnabled: false, fake: fake)

        XCTAssertEqual(model.biometricAvailability, .unavailable(.notEnrolled))

        fake.availability = .available
        XCTAssertEqual(model.biometricAvailability, .available)
    }

    func testToggleBiometricOff_failedAuth_leavesEnabled_andReturnsFailure() async {
        let fake = FakeBiometricAuthenticator(
            availability: .available,
            nextResult: .failed(.userFailed)
        )
        let model = makeModelWithBiometric(initialEnabled: true, fake: fake)

        let result = await model.requestToggleBiometric(false)

        guard case .failure(let err) = result else {
            XCTFail("Expected failure, got \(result)"); return
        }
        XCTAssertEqual(err, .failed(.userFailed))
        XCTAssertTrue(model.touchIDForSensitiveActions,
                      "Failed auth must NOT persist the disable")
        XCTAssertEqual(fake.authenticateCalls.count, 1)
    }

    func testSnapshot_treatsNilAndEmptyOverrideAsDifferent() async {
        let store = makeInMemoryStore()
        let discovery = TestBinaryLocator(paths: [:])

        let model = makeModel(settings: store, discovery: discovery)
        // Baseline: storePathOverride is `nil` from the empty store. Save
        // a no-op-equivalent change (we need at least one diff to drive
        // save), then assert the override remains nil and hasChanges is
        // clean.
        model.storePathOverride = nil
        XCTAssertFalse(model.hasChanges, "nil baseline should remain clean")

        // Flip to explicit empty string — a distinct value from `nil`.
        model.storePathOverride = ""
        XCTAssertTrue(model.hasChanges, "empty string must differ from nil baseline")
    }

}
