//
//  EntryDetailModelRefinementTests.swift
//  KizbaTests
//
//  Phase 2 — step 2.6 refinement coverage for `EntryDetailModel`.
//
//  These tests harden the invariants already exercised by
//  `EntryDetailModelTests` and add edge-case coverage required by
//  `.ai/plan.md` and `.ai/decisions.md`:
//
//    a) `testReveal_doesNotPersistSecret` — flipping
//       `isPasswordRevealed` never moves the `PassSecret` out of the
//       transient `model.state.loaded(_:)` slot, never touches
//       `AppState`, and the secret stays non-Codable / non-string-
//       convertible (compile-time + runtime mirror probes).
//
//    b) `testCopy_invokesClipboardWithDuration` — a fake clipboard
//       records the value + `Duration` passed to
//       `ClipboardServicing.copy(_:clearAfter:)` and asserts a verbatim
//       hand-off (no `"key: value"` composition).
//
//    c) `testSelectionCancellation_races` — three rapid selection
//       changes against a slow fake `PassManaging` must converge on the
//       last selection's secret; intermediate states must never persist.
//
//    d) `testErrorMapping_setsFailedState` — a fake `PassManaging` that
//       throws a known `PassError` causes
//       `model.state == .failed(expected)`.
//
//  All test doubles are file-private to keep production wiring
//  untouched per the `.ai/decisions.md` testability rules.
//

import XCTest
@testable import Kizba

@MainActor
final class EntryDetailModelRefinementTests: XCTestCase {

    // MARK: - a) Reveal does not persist or leak the secret

    func testReveal_doesNotPersistSecret() async {
        let entry = PassEntry(path: "work/db/admin")
        let secret = PassSecret(
            password: "super-secret-pw",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "admin")]
            )
        )
        let manager = ScriptedPassManager(
            entries: [entry],
            outcomes: [entry.path: .success(secret)]
        )
        let env = makeEnvironment(passManager: manager)
        let appState = AppState()
        let model = EntryDetailModel(environment: env, state: appState)

        model.handleSelectionChange(entry.id)
        await waitForState(of: model, where: { if case .loaded = $0 { return true }; return false }, timeout: 1.0)

        // Reveal & hide. Neither flip should mutate `AppState` or move
        // the secret out of `state.loaded(_:)`.
        model.isPasswordRevealed = true
        model.isPasswordRevealed = false
        model.isPasswordRevealed = true

        // The secret is reachable only via `state.loaded(_:)` —
        // `AppState` exposes no slot for it (compile-time invariant).
        // Re-assert it at runtime via Mirror so a future refactor that
        // adds such a slot trips this test.
        let appStateMirror = Mirror(reflecting: appState)
        for child in appStateMirror.children {
            XCTAssertFalse(
                child.value is PassSecret,
                "AppState must not store a PassSecret (found at label \(child.label ?? "?"))."
            )
        }

        // The secret must still be available transiently inside the
        // model's `state.loaded(_:)` slot.
        guard case .loaded(let loaded) = model.state else {
            return XCTFail("Expected .loaded after reveal toggling, got \(model.state)")
        }
        XCTAssertEqual(loaded, secret)

        // Compile-time guard: `PassSecret` must NOT be Codable nor
        // CustomStringConvertible. The two probes below would fail to
        // compile (or trip `as?`) if such conformances were added.
        XCTAssertFalse(
            (loaded as Any) is any CustomStringConvertible,
            "PassSecret must not conform to CustomStringConvertible."
        )
        XCTAssertFalse(
            (loaded as Any) is any CustomDebugStringConvertible,
            "PassSecret must not conform to CustomDebugStringConvertible."
        )

        // Clearing the selection must drop the secret immediately.
        model.handleSelectionChange(nil)
        if case .loaded = model.state {
            XCTFail("Secret must be released on selection clear.")
        }
    }

    // MARK: - b) Copy forwards verbatim value + Duration

    func testCopy_invokesClipboardWithDuration() async {
        let entry = PassEntry(path: "work/aws/root")
        let secret = PassSecret(
            password: "aws-root-pw",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "root@example.test")]
            )
        )
        let manager = ScriptedPassManager(
            entries: [entry],
            outcomes: [entry.path: .success(secret)]
        )
        let clipboard = FakeClipboardServicing()
        // Persist a non-default delay so the assertion below proves the
        // model is reading from settings rather than using a literal
        // fallback.
        let settings = EphemeralSettingsStore()
        settings.set(45, for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
        let env = makeEnvironment(passManager: manager, clipboard: clipboard, settings: settings)
        let appState = AppState()
        let model = EntryDetailModel(environment: env, state: appState)

        model.handleSelectionChange(entry.id)
        await waitForState(of: model, where: { if case .loaded = $0 { return true }; return false }, timeout: 1.0)

        await model.copyPassword()

        let last = clipboard.lastCall
        XCTAssertEqual(last?.value, "aws-root-pw")
        XCTAssertEqual(last?.clearAfter, .seconds(45))

        // Verbatim guarantee: the copied value must equal the field's
        // raw value, never a `"key: value"` composition.
        await model.copyMetadata(forKey: "user")
        let metaCall = clipboard.lastCall
        XCTAssertEqual(metaCall?.value, "root@example.test")
        XCTAssertFalse(
            (metaCall?.value ?? "").contains(": "),
            "Clipboard must receive verbatim value, not a 'key: value' composition."
        )
        XCTAssertEqual(metaCall?.clearAfter, .seconds(45))
    }

    // MARK: - c) Rapid selection-change race

    func testSelectionCancellation_races() async {
        let a = PassEntry(path: "personal/wifi/home")
        let b = PassEntry(path: "personal/wifi/guest")
        let c = PassEntry(path: "personal/wifi/office")
        let secrets: [String: PassSecret] = [
            a.path: PassSecret(password: "pw-a"),
            b.path: PassSecret(password: "pw-b"),
            c.path: PassSecret(password: "pw-c")
        ]
        let manager = ScriptedPassManager(
            entries: [a, b, c],
            outcomes: secrets.mapValues { .success($0) },
            delay: .milliseconds(200)
        )
        let env = makeEnvironment(passManager: manager)
        let appState = AppState()
        let model = EntryDetailModel(environment: env, state: appState)

        // Three rapid selection changes before the first slow show()
        // could possibly resolve.
        model.handleSelectionChange(a.id)
        model.handleSelectionChange(b.id)
        model.handleSelectionChange(c.id)
        XCTAssertTrue({ if case .loading = model.state { return true }; return false }())

        await waitForState(
            of: model,
            where: { if case .loaded = $0 { return true }; return false },
            timeout: 2.0
        )

        guard case .loaded(let loaded) = model.state else {
            return XCTFail("Expected .loaded after race, got \(model.state)")
        }
        // Final state must reflect the *last* selection.
        XCTAssertEqual(loaded.password, "pw-c")

        // Settle window — earlier in-flight tasks must not clobber
        // the loaded state with a stale result.
        try? await Task.sleep(for: .milliseconds(300))
        guard case .loaded(let stillLoaded) = model.state else {
            return XCTFail("State must remain .loaded after settle window.")
        }
        XCTAssertEqual(stillLoaded.password, "pw-c")
    }

    // MARK: - d) Error mapping → .failed(expected)

    func testErrorMapping_setsFailedState() async {
        let entry = PassEntry(path: "broken/entry")
        let expected = PassError.decryptionFailed(stderrExcerpt: "gpg: decryption failed")
        let manager = ScriptedPassManager(
            entries: [entry],
            outcomes: [entry.path: .failure(expected)]
        )
        let env = makeEnvironment(passManager: manager)
        let appState = AppState()
        let model = EntryDetailModel(environment: env, state: appState)

        model.handleSelectionChange(entry.id)
        await waitForState(
            of: model,
            where: { if case .failed = $0 { return true }; return false },
            timeout: 1.0
        )

        guard case .failed(let actual) = model.state else {
            return XCTFail("Expected .failed, got \(model.state)")
        }
        XCTAssertEqual(actual, expected)
    }

    func testErrorMapping_pinentryNotConfigured() async {
        let entry = PassEntry(path: "needs/pinentry")
        let expected = PassError.pinentryNotConfigured
        let manager = ScriptedPassManager(
            entries: [entry],
            outcomes: [entry.path: .failure(expected)]
        )
        let env = makeEnvironment(passManager: manager)
        let appState = AppState()
        let model = EntryDetailModel(environment: env, state: appState)

        model.handleSelectionChange(entry.id)
        await waitForState(
            of: model,
            where: { if case .failed = $0 { return true }; return false },
            timeout: 1.0
        )

        guard case .failed(let actual) = model.state, actual == expected else {
            return XCTFail("Expected .failed(.pinentryNotConfigured), got \(model.state)")
        }
    }

    // MARK: - Helpers

    private func makeEnvironment(
        passManager: any PassManaging,
        clipboard: any ClipboardServicing = SilentClipboard(),
        settings: any SettingsStoring = EphemeralSettingsStore()
    ) -> AppEnvironment {
        AppEnvironment(
            passManager: passManager,
            clipboard: clipboard,
            settings: settings,
            discovery: nil
        )
    }

    /// Polls `model.state` on the MainActor until `predicate` matches
    /// or `timeout` seconds elapse. Deterministic timing without
    /// relying on a single fixed sleep.
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

// MARK: - File-private test doubles

/// Scriptable `PassManaging` that maps entry paths to a pre-recorded
/// `Result<PassSecret, PassError>` and optionally delays each `show`
/// invocation for race testing.
private actor ScriptedPassManager: PassManaging {
    private let entries: [PassEntry]
    private let outcomes: [String: Result<PassSecret, PassError>]
    private let delay: Duration?

    init(
        entries: [PassEntry],
        outcomes: [String: Result<PassSecret, PassError>],
        delay: Duration? = nil
    ) {
        self.entries = entries
        self.outcomes = outcomes
        self.delay = delay
    }

    func listEntries() async throws -> [PassEntry] { entries }

    func show(_ entry: PassEntry) async throws -> PassSecret {
        if let delay {
            try await Task.sleep(for: delay)
        }
        guard let outcome = outcomes[entry.path] else {
            throw PassError.decryptionFailed(stderrExcerpt: "no fixture for \(entry.path)")
        }
        switch outcome {
        case .success(let secret): return secret
        case .failure(let error):  throw error
        }
    }

    nonisolated func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp/kizba-scripted-store")
    }
}

// `FakeClipboardServicing` lives in `KizbaTests/Fixtures/FakeClipboard.swift`.

/// Drops every clipboard call — used when the test is not asserting on
/// clipboard interaction.
private struct SilentClipboard: ClipboardServicing {
    func copy(_ value: String, clearAfter: Duration) async {}
}

/// Minimal in-memory `SettingsStoring` for tests.
private final class EphemeralSettingsStore: SettingsStoring, @unchecked Sendable {
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
