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

    func testModelCopy_invokesClipboardWithVerbatimValueAndDelay() async {
        let clipboard = RecordingClipboard()
        let model = makeModel(clipboard: clipboard)

        await model.copy("super-secret-token", clearAfterSeconds: 30)

        XCTAssertEqual(clipboard.calls.count, 1)
        XCTAssertEqual(clipboard.calls.first?.value, "super-secret-token")
        XCTAssertEqual(clipboard.calls.first?.clearAfter, .seconds(30))
    }

    func testModelCopyPassword_forwardsLoadedPasswordVerbatim() async {
        let secret = PassSecret(
            password: "p@ss-w0rd!",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "alice@example.com")]
            )
        )
        let entry = PassEntry(path: "work/example/alice")
        let clipboard = RecordingClipboard()
        let passManager = StubPassManager(entry: entry, secret: secret)
        let model = makeModel(passManager: passManager, clipboard: clipboard)

        // Drive the model into `.loaded(secret)` via the public API.
        model.handleSelectionChange(entry.id)
        await waitForLoaded(model, timeout: 1.0)

        await model.copyPassword(clearAfterSeconds: 30)

        XCTAssertEqual(clipboard.calls.count, 1)
        XCTAssertEqual(clipboard.calls.first?.value, "p@ss-w0rd!")
        XCTAssertEqual(clipboard.calls.first?.clearAfter, .seconds(30))
    }

    // MARK: - Helpers

    private func makeModel(
        passManager: any PassManaging = NullPassManager(),
        clipboard: any ClipboardServicing
    ) -> EntryDetailModel {
        let env = AppEnvironment(
            passManager: passManager,
            clipboard: clipboard,
            settings: NullSettingsStore()
            ,
            discovery: nil
        )
        return EntryDetailModel(environment: env, state: AppState())
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

private final class RecordingClipboard: ClipboardServicing, @unchecked Sendable {
    struct Call: Equatable, Sendable {
        let value: String
        let clearAfter: Duration
    }
    private let lock = NSLock()
    private var _calls: [Call] = []
    var calls: [Call] {
        lock.lock(); defer { lock.unlock() }
        return _calls
    }
    func copy(_ value: String, clearAfter: Duration) async {
        lock.lock(); defer { lock.unlock() }
        _calls.append(Call(value: value, clearAfter: clearAfter))
    }
}

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

private struct NullSettingsStore: SettingsStoring {
    func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? { nil }
    func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {}
}
