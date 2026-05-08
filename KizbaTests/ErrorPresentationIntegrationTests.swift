//
// ErrorPresentationIntegrationTests.swift
// KizbaTests
//
// Integration-level tests covering DiagnosticsModel and EntryDetailModel
// behaviour for a decryption failure path and the ErrorPresentation
// mapping.
//

import XCTest
@testable import Kizba

@MainActor
final class ErrorPresentationIntegrationTests: XCTestCase {

    func testDiagnosticsModel_recordsInvocationWithDecryptionFailure() async {
        let log = InvocationLog()
        let invocation = Invocation(
            executable: "/usr/bin/pass",
            args: ["show", "broken/entry"],
            exitCode: 2,
            stderrExcerpt: "gpg: decryption failed",
            startedAt: Date(),
            duration: 0.1
        )

        await log.record(invocation)

        let model = DiagnosticsModel(invocationLog: log)
        await model.refresh()

        XCTAssertEqual(model.recentInvocations.count, 1)
        XCTAssertEqual(model.recentInvocations.first?.stderrExcerpt, "gpg: decryption failed")
        XCTAssertEqual(model.recentInvocations.first?.executable, "/usr/bin/pass")
    }

    func testEntryDetailModel_decryptionFailed_setsFailed_and_ErrorPresentationInline() async {
        let entry = PassEntry(path: "broken/entry")
        let expected = PassError.decryptionFailed(stderrExcerpt: "gpg: decryption failed")

        let manager = ScriptedPassManager(entries: [entry], outcomes: [entry.path: .failure(expected)])
        let clipboard = SilentClipboard()
        let settings = EphemeralSettingsStore()
        let env = AppEnvironment(passManager: manager, clipboard: clipboard, settings: settings, passCLI: nil, discovery: nil, invocationLog: nil)

        let appState = AppState()
        let model = EntryDetailModel(environment: env, state: appState)

        model.handleSelectionChange(entry.id)

        await waitForState(of: model, where: { if case .failed = $0 { return true }; return false }, timeout: 1.0)

        guard case .failed(let actual) = model.state else {
            return XCTFail("Expected .failed, got \(model.state)")
        }
        XCTAssertEqual(actual, expected)

        let presentation = ErrorPresentation.present(for: actual)
        switch presentation {
        case .inlineWithDiagnostics(let message):
            XCTAssertEqual(message, "gpg: decryption failed")
        default:
            XCTFail("Expected inlineWithDiagnostics presentation for decryptionFailed, got \(presentation)")
        }
    }

    // MARK: - Helpers & test doubles

    /// Simple scriptable PassManaging used by these integration tests.
    private actor ScriptedPassManager: PassManaging {
        private let entries: [PassEntry]
        private let outcomes: [String: Result<PassSecret, PassError>]

        init(entries: [PassEntry], outcomes: [String: Result<PassSecret, PassError>]) {
            self.entries = entries
            self.outcomes = outcomes
        }

        func listEntries() async throws -> [PassEntry] { entries }

        func show(_ entry: PassEntry) async throws -> PassSecret {
            guard let outcome = outcomes[entry.path] else {
                throw PassError.decryptionFailed(stderrExcerpt: "no fixture for \(entry.path)")
            }
            switch outcome {
            case .success(let secret): return secret
            case .failure(let error): throw error
            }
        }

        nonisolated func storeLocation() -> URL { URL(fileURLWithPath: "/tmp/kizba-scripted-store") }
    }

    private struct SilentClipboard: ClipboardServicing {
        func copy(_ value: String, clearAfter: Duration) async {}
    }

    private final class EphemeralSettingsStore: SettingsStoring, @unchecked Sendable {
        private let lock = NSLock()
        private var storage: [String: any SettingsValue] = [:]

        func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? {
            lock.lock(); defer { lock.unlock() }
            return storage[key.name] as? Value
        }

        func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {
            lock.lock(); defer { lock.unlock() }
            if let value { storage[key.name] = value } else { storage.removeValue(forKey: key.name) }
        }

        func removeValue(forKey key: String) { lock.lock(); defer { lock.unlock() }; storage.removeValue(forKey: key) }
        func resetAll() { lock.lock(); defer { lock.unlock() }; storage.removeAll() }
        func registerDefaults(_ defaults: [String : Any]) {}
    }

    private func waitForState(
        of model: EntryDetailModel,
        where predicate: (EntryDetailModel.State) -> Bool,
        timeout seconds: TimeInterval
    ) async {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if predicate(model.state) { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Timed out waiting for state predicate. Last state: \(model.state)")
    }
}
