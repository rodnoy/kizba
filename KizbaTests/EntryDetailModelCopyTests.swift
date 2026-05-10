//
//  EntryDetailModelCopyTests.swift
//  KizbaTests
//
//  Phase 7.3: model-level assertion that `EntryDetailModel.copy(...)`
//  forwards verbatim to the injected `ClipboardServicing` with the
//  requested clear-after delay. Complements the existing
//  `EntryDetailModelTests` / `EntryDetailModelRefinementTests` suites
//  with a focused, self-contained scenario for the new wiring.
//
//  View-level button-action coverage (tapping the Copy buttons in
//  `EntryDetailView` and observing clipboard side effects) is the
//  responsibility of UI tests; this file deliberately stays at the
//  model boundary.
//

import XCTest
@testable import Kizba

@MainActor
final class EntryDetailModelCopyTests: XCTestCase {

    func testModelCopy_invokesClipboardWithVerbatimValueAndDefaultDelay() async {
        let clipboard = FakeClipboardServicing()
        // Empty store — `currentClipboardClearDelay()` must fall back
        // to ``SettingsKeys/defaultClipboardClearDelaySeconds``.
        let model = makeModel(clipboard: clipboard)

        await model.copy("super-secret-token")

        XCTAssertEqual(clipboard.calls.count, 1)
        XCTAssertEqual(clipboard.calls.first?.value, "super-secret-token")
        XCTAssertEqual(
            clipboard.calls.first?.clearAfter,
            .seconds(SettingsKeys.defaultClipboardClearDelaySeconds)
        )
    }

    func testModelCopyPassword_forwardsLoadedPasswordVerbatim() async {
        let secret = PassSecret(
            password: "p@ss-w0rd!",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "alice@example.com")]
            )
        )
        let entry = PassEntry(path: "work/example/alice")
        let clipboard = FakeClipboardServicing()
        let passManager = StubPassManager(entry: entry, secret: secret)
        let model = makeModel(passManager: passManager, clipboard: clipboard)

        // Drive the model into `.loaded(secret)` via the public API.
        model.handleSelectionChange(entry.id)
        await waitForLoaded(model, timeout: 1.0)

        await model.copyPassword()

        XCTAssertEqual(clipboard.calls.count, 1)
        XCTAssertEqual(clipboard.calls.first?.value, "p@ss-w0rd!")
        XCTAssertEqual(
            clipboard.calls.first?.clearAfter,
            .seconds(SettingsKeys.defaultClipboardClearDelaySeconds)
        )
    }

    // MARK: - Phase A.6: live read of `clipboardClearDelaySeconds`

    /// Setting a non-default value in the injected ``SettingsStoring``
    /// must drive the very next `copy(_:)` invocation.
    func testCopy_readsClipboardDelayFromSettingsLive() async {
        let clipboard = FakeClipboardServicing()
        let settings = MutableSettingsStore()
        settings.set(60, for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
        let model = makeModel(clipboard: clipboard, settings: settings)

        await model.copy("token-1")

        XCTAssertEqual(clipboard.calls.last?.clearAfter, .seconds(60))

        // Mutate the setting between copies — the change must take
        // effect on the next call without rebuilding the model.
        settings.set(15, for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))

        await model.copy("token-2")

        XCTAssertEqual(clipboard.calls.last?.clearAfter, .seconds(15))
    }

    /// Out-of-range persisted values must be clamped to
    /// ``SettingsKeys/clipboardClearDelayBounds``.
    func testCopy_clampsOutOfRangeSettingsValue() async {
        let clipboard = FakeClipboardServicing()
        let settings = MutableSettingsStore()
        let bounds = SettingsKeys.clipboardClearDelayBounds

        // Below lower bound (and the legacy "no-clear" footgun) → clamp up.
        settings.set(0, for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
        let model = makeModel(clipboard: clipboard, settings: settings)
        await model.copy("a")
        XCTAssertEqual(clipboard.calls.last?.clearAfter, .seconds(bounds.lowerBound))

        // Above upper bound → clamp down.
        settings.set(1_000_000, for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
        await model.copy("b")
        XCTAssertEqual(clipboard.calls.last?.clearAfter, .seconds(bounds.upperBound))
    }

    // MARK: - Confirmation toast (post-784212b regression coverage)

    /// `copyPassword()` must post an `.info` toast titled `Password
    /// copied`, with a message that surfaces the auto-clear delay
    /// in seconds. The toast MUST NOT contain the password value
    /// (security: per-`.ai/decisions.md` toasts never carry secret
    /// material).
    func testCopyPassword_postsInfoToastWithLabelAndDelay() async {
        let secretValue = "p@ss-w0rd!"
        let secret = PassSecret(
            password: secretValue,
            metadata: PassMetadata(fields: [])
        )
        let entry = PassEntry(path: "work/example/alice")
        let clipboard = FakeClipboardServicing()
        let passManager = StubPassManager(entry: entry, secret: secret)
        let settings = MutableSettingsStore()
        settings.set(45, for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
        let appState = AppState()
        let model = makeModel(
            passManager: passManager,
            clipboard: clipboard,
            settings: settings,
            appState: appState
        )

        model.handleSelectionChange(entry.id)
        await waitForLoaded(model, timeout: 1.0)

        await model.copyPassword()

        let toast = appState.toastCenter.visible
        XCTAssertNotNil(toast)
        XCTAssertEqual(toast?.severity, .info)
        XCTAssertEqual(toast?.title, "Password copied")
        XCTAssertEqual(toast?.message, "Auto-clears in 45s")

        // Security: the toast must NEVER contain the copied value.
        XCTAssertFalse(toast?.title.contains(secretValue) ?? false)
        XCTAssertFalse(toast?.message?.contains(secretValue) ?? false)
    }

    /// `copyMetadata(forKey:)` must post an `.info` toast titled
    /// `"<key>" copied` (key wrapped in quotes). The toast MUST NOT
    /// contain the metadata value.
    func testCopyMetadata_postsInfoToastWithKeyLabel() async {
        let metadataValue = "alice@example.com"
        let secret = PassSecret(
            password: "irrelevant",
            metadata: PassMetadata(
                fields: [.init(key: "email", value: metadataValue)]
            )
        )
        let entry = PassEntry(path: "work/example/alice")
        let clipboard = FakeClipboardServicing()
        let passManager = StubPassManager(entry: entry, secret: secret)
        let settings = MutableSettingsStore()
        settings.set(20, for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
        let appState = AppState()
        let model = makeModel(
            passManager: passManager,
            clipboard: clipboard,
            settings: settings,
            appState: appState
        )

        model.handleSelectionChange(entry.id)
        await waitForLoaded(model, timeout: 1.0)

        await model.copyMetadata(forKey: "email")

        let toast = appState.toastCenter.visible
        XCTAssertNotNil(toast)
        XCTAssertEqual(toast?.severity, .info)
        XCTAssertEqual(toast?.title, "\"email\" copied")
        XCTAssertEqual(toast?.message, "Auto-clears in 20s")

        // Security: the toast must NEVER contain the copied value.
        XCTAssertFalse(toast?.title.contains(metadataValue) ?? false)
        XCTAssertFalse(toast?.message?.contains(metadataValue) ?? false)
    }

    /// `copyNotes()` must post an `.info` toast titled `Notes
    /// copied`. The toast MUST NOT contain the notes body.
    func testCopyNotes_postsInfoToastWithLabel() async {
        let notesBody = "recovery codes: 11111-22222"
        let secret = PassSecret(
            password: "irrelevant",
            metadata: PassMetadata(fields: [], notes: notesBody)
        )
        let entry = PassEntry(path: "work/example/alice")
        let clipboard = FakeClipboardServicing()
        let passManager = StubPassManager(entry: entry, secret: secret)
        let settings = MutableSettingsStore()
        settings.set(30, for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
        let appState = AppState()
        let model = makeModel(
            passManager: passManager,
            clipboard: clipboard,
            settings: settings,
            appState: appState
        )

        model.handleSelectionChange(entry.id)
        await waitForLoaded(model, timeout: 1.0)

        await model.copyNotes()

        let toast = appState.toastCenter.visible
        XCTAssertNotNil(toast)
        XCTAssertEqual(toast?.severity, .info)
        XCTAssertEqual(toast?.title, "Notes copied")
        XCTAssertEqual(toast?.message, "Auto-clears in 30s")

        // Security: the toast must NEVER contain the copied notes.
        XCTAssertFalse(toast?.title.contains(notesBody) ?? false)
        XCTAssertFalse(toast?.message?.contains(notesBody) ?? false)
    }

    // MARK: - Helpers

    private func makeModel(
        passManager: any PassManaging = NullPassManager(),
        clipboard: any ClipboardServicing,
        settings: any SettingsStoring = MutableSettingsStore(),
        appState: AppState? = nil
    ) -> EntryDetailModel {
        let env = AppEnvironment(
            passManager: passManager,
            clipboard: clipboard,
            settings: settings,
            passwordGenerator: LivePasswordGenerator(),
            discovery: nil
        )
        return EntryDetailModel(environment: env, state: appState ?? AppState())
    }

    private func waitForLoaded(
        _ model: EntryDetailModel,
        timeout seconds: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if case .loaded = model.state { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTFail(
            "Timed out waiting for .loaded; last state: \(model.state)",
            file: file,
            line: line
        )
    }
}

// MARK: - File-private doubles
// `FakeClipboardServicing` lives in `KizbaTests/Fixtures/FakeClipboard.swift`.

private struct StubPassManager: PassManaging {
    let entry: PassEntry
    let secret: PassSecret
    func listEntries() async throws -> [PassEntry] { [entry] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        guard entry.path == self.entry.path else {
            throw PassError.decryptionFailed(stderrExcerpt: "unknown entry")
        }
        return secret
    }
    func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-copy-tests")
    }
}

private struct NullPassManager: PassManaging {
    func listEntries() async throws -> [PassEntry] { [] }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        throw PassError.decryptionFailed(stderrExcerpt: "not used")
    }
    func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-copy-tests")
    }
}

/// Tiny in-memory `SettingsStoring` test double. Mutable so a single
/// instance can drive multiple `copy(_:)` calls in a single test, in
/// order to assert that ``EntryDetailModel`` re-reads the setting on
/// every call rather than caching it at init time.
// Shared in-memory SettingsStoring test fixture used by multiple test files.
final class MutableSettingsStore: SettingsStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: any SettingsValue] = [:]

    func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? {
        lock.lock(); defer { lock.unlock() }
        return storage[key.name] as? Value
    }

    func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {
        lock.lock(); defer { lock.unlock() }
        if let value {
            storage[key.name] = value
        } else {
            storage.removeValue(forKey: key.name)
        }
    }

    func removeValue(forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }

    func resetAll() {
        lock.lock(); defer { lock.unlock() }
        storage.removeAll()
    }

    func registerDefaults(_ defaults: [String: Any]) {
        // Tests mutate explicit keys; defaults registration is unused here.
        _ = defaults
    }
}
