//
//  EntryDetailModelTests.swift
//  KizbaTests
//
//  Deterministic tests for `EntryDetailModel`. Cover three concerns
//  per `.ai/plan.md` step 2.6:
//
//    1. Successful load transitions `state` to `.loaded(secret)`.
//    2. Selection churn cancels in-flight loads — only the final
//       selection's secret reaches `state`.
//    3. `copy(_:)` forwards verbatim to `ClipboardServicing` with the
//       requested clear-after delay.
//
//  Tests use small, in-test doubles for `PassManaging` and
//  `ClipboardServicing` so production wiring stays untouched.
//

import XCTest
@testable import Kizba

@MainActor
final class EntryDetailModelTests: XCTestCase {

    // MARK: - Test doubles

    /// Records every `copy(_:clearAfter:)` invocation. Order is
    /// preserved; reads must run on MainActor.
    private final class RecordingClipboard: ClipboardServicing, @unchecked Sendable {
        struct Call: Sendable, Equatable {
            let value: String
            let clearAfter: Duration
        }
        private let lock = NSLock()
        private(set) var calls: [Call] = []

        func copy(_ value: String, clearAfter: Duration) async {
            lock.lock(); defer { lock.unlock() }
            calls.append(Call(value: value, clearAfter: clearAfter))
        }
    }

    /// Optional-delay `PassManaging`. When `delay` is non-nil, `show`
    /// awaits `Task.sleep` so cancellation can be observed
    /// deterministically.
    private actor SlowPassManager: PassManaging {
        private let entries: [PassEntry]
        private let secrets: [String: PassSecret]
        private let delay: Duration?
        private(set) var showCalls: [String] = []

        init(
            entries: [PassEntry],
            secrets: [String: PassSecret],
            delay: Duration? = nil
        ) {
            self.entries = entries
            self.secrets = secrets
            self.delay = delay
        }

        func listEntries() async throws -> [PassEntry] { entries }

        func show(_ entry: PassEntry) async throws -> PassSecret {
            showCalls.append(entry.path)
            if let delay {
                try await Task.sleep(for: delay)
            }
            guard let secret = secrets[entry.path] else {
                throw PassError.decryptionFailed(stderrExcerpt: "no fixture")
            }
            return secret
        }

        nonisolated func storeLocation() -> URL {
            URL(fileURLWithPath: "/tmp/kizba-slow-store")
        }
    }

    private func makeEnvironment(
        passManager: any PassManaging,
        clipboard: any ClipboardServicing = NoopClipboardForTests(),
        settings: any SettingsStoring = InMemorySettingsStoreForTests()
    ) -> AppEnvironment {
        AppEnvironment(
            passManager: passManager,
            clipboard: clipboard,
            settings: settings,
            passwordGenerator: LivePasswordGenerator(),
            discovery: nil
        )
    }

    // MARK: - 1. Successful load

    func testLoadSelection_succeeds() async {
        let entry = PassEntry(path: "work/aws/root")
        let secret = PassSecret(
            password: "aws-root-password",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "root@example.test")]
            )
        )
        let manager = SlowPassManager(
            entries: [entry],
            secrets: [entry.path: secret]
        )
        let env = makeEnvironment(passManager: manager)
        let appState = AppState()
        let model = EntryDetailModel(environment: env, state: appState)

        XCTAssertTrue(isIdle(model.state))

        model.handleSelectionChange(entry.id)
        XCTAssertTrue(isLoading(model.state))

        await waitForState(of: model, where: isLoaded, timeout: 1.0)

        guard case .loaded(let loaded) = model.state else {
            return XCTFail("Expected .loaded, got \(model.state)")
        }
        XCTAssertEqual(loaded, secret)
    }

    // MARK: - 2. Selection-change cancellation

    func testSelectionCancellation_dropsStaleResult() async {
        let first  = PassEntry(path: "personal/wifi/home")
        let second = PassEntry(path: "personal/wifi/guest")
        let secrets: [String: PassSecret] = [
            first.path:  PassSecret(password: "first-pw"),
            second.path: PassSecret(password: "second-pw")
        ]
        // 200ms delay is long enough to observe cancellation in CI
        // without making the test slow.
        let manager = SlowPassManager(
            entries: [first, second],
            secrets: secrets,
            delay: .milliseconds(200)
        )
        let env = makeEnvironment(passManager: manager)
        let appState = AppState()
        let model = EntryDetailModel(environment: env, state: appState)

        // Kick off the first load, then immediately switch to the
        // second selection before the slow `show` returns.
        model.handleSelectionChange(first.id)
        XCTAssertTrue(isLoading(model.state))
        model.handleSelectionChange(second.id)
        XCTAssertTrue(isLoading(model.state))

        await waitForState(of: model, where: isLoaded, timeout: 2.0)

        guard case .loaded(let loaded) = model.state else {
            return XCTFail("Expected .loaded, got \(model.state)")
        }
        // The final state must correspond to the *last* selection,
        // never the cancelled first one.
        XCTAssertEqual(loaded.password, "second-pw")
    }

    func testSelectionCleared_returnsToIdle() async {
        let entry = PassEntry(path: "personal/wifi/home")
        let manager = SlowPassManager(
            entries: [entry],
            secrets: [entry.path: PassSecret(password: "x")],
            delay: .milliseconds(100)
        )
        let env = makeEnvironment(passManager: manager)
        let appState = AppState()
        let model = EntryDetailModel(environment: env, state: appState)

        model.handleSelectionChange(entry.id)
        XCTAssertTrue(isLoading(model.state))

        // Clear selection mid-flight.
        model.handleSelectionChange(nil)
        XCTAssertTrue(isIdle(model.state))

        // Give the cancelled task a moment to settle; state must stay idle.
        try? await Task.sleep(for: .milliseconds(250))
        XCTAssertTrue(isIdle(model.state))
    }

    // MARK: - 3. Copy forwards to clipboard

    func testCopy_callsClipboardWithVerbatimValueAndSettingsDelay() async {
        let entry = PassEntry(path: "work/github/personal-token")
        let secret = PassSecret(
            password: "ghp_TEST_TOKEN_0001",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "jane")]
            )
        )
        let manager = SlowPassManager(
            entries: [entry],
            secrets: [entry.path: secret]
        )
        let clipboard = RecordingClipboard()
        let settings = InMemorySettingsStoreForTests()
        // No persisted value → model must fall back to the documented
        // default.
        let env = makeEnvironment(passManager: manager, clipboard: clipboard, settings: settings)
        let appState = AppState()
        let model = EntryDetailModel(environment: env, state: appState)

        model.handleSelectionChange(entry.id)
        await waitForState(of: model, where: isLoaded, timeout: 1.0)

        await model.copyPassword()
        await model.copyMetadata(forKey: "user")
        await model.copy("explicit-value")

        let defaultDelay = Duration.seconds(SettingsKeys.defaultClipboardClearDelaySeconds)
        XCTAssertEqual(clipboard.calls.count, 3)
        XCTAssertEqual(
            clipboard.calls[0],
            .init(value: "ghp_TEST_TOKEN_0001", clearAfter: defaultDelay)
        )
        XCTAssertEqual(
            clipboard.calls[1],
            .init(value: "jane", clearAfter: defaultDelay)
        )
        XCTAssertEqual(
            clipboard.calls[2],
            .init(value: "explicit-value", clearAfter: defaultDelay)
        )
    }

    // MARK: - State helpers

    private func isIdle(_ state: EntryDetailModel.State) -> Bool {
        if case .idle = state { return true }
        return false
    }

    private func isLoading(_ state: EntryDetailModel.State) -> Bool {
        if case .loading = state { return true }
        return false
    }

    private func isLoaded(_ state: EntryDetailModel.State) -> Bool {
        if case .loaded = state { return true }
        return false
    }

    /// Polls `model.state` on the MainActor until `predicate` matches
    /// or `timeout` seconds elapse. Polling beats `Task.sleep`-only
    /// waits because it tolerates host-load variability without making
    /// the happy path slow.
    private func waitForState(
        of model: EntryDetailModel,
        where predicate: (EntryDetailModel.State) -> Bool,
        timeout seconds: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if predicate(model.state) { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTFail(
            "Timed out waiting for state predicate. Last state: \(model.state)",
            file: file,
            line: line
        )
    }
}

// MARK: - Bare-bones doubles for non-clipboard env slots

private struct NoopClipboardForTests: ClipboardServicing {
    func copy(_ value: String, clearAfter: Duration) async {}
}

private final class InMemorySettingsStoreForTests: SettingsStoring, @unchecked Sendable {
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
        // Tests do not exercise defaults registration on this double.
        _ = defaults
    }
}
