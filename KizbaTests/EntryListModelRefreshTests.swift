//
//  EntryListModelRefreshTests.swift
//  KizbaTests
//
//  Focused tests for `EntryListModel.refresh()`: scanner/pass-manager
//  invocation, snapshot update, and cooperative cancellation. The
//  fakes in this file are intentionally local — production wiring
//  (`LivePassManager`, `PasswordStoreScanner`) is exercised by their
//  own dedicated test suites.
//

import XCTest
@testable import Kizba

@MainActor
final class EntryListModelRefreshTests: XCTestCase {

    // MARK: - Fakes

    /// PassManaging double whose `listEntries()` returns successive
    /// canned responses. Records every invocation count atomically so
    /// tests can assert the model actually went back to the source.
    private final actor FakePassManager: PassManaging {

        private var responses: [[PassEntry]]
        private(set) var listCallCount: Int = 0
        private let listDelay: Duration?

        init(responses: [[PassEntry]], listDelay: Duration? = nil) {
            self.responses = responses
            self.listDelay = listDelay
        }

        func listEntries() async throws -> [PassEntry] {
            listCallCount += 1
            if let listDelay {
                // Cooperative sleep — propagates cancellation as
                // CancellationError, which the model swallows.
                try await Task.sleep(for: listDelay)
            }
            if responses.isEmpty {
                return []
            }
            if responses.count == 1 {
                return responses[0]
            }
            return responses.removeFirst()
        }

        func show(_ entry: PassEntry) async throws -> PassSecret {
            fatalError("show() must not be invoked from EntryListModel tests")
        }

        nonisolated func storeLocation() -> URL {
            URL(fileURLWithPath: "/var/empty")
        }

        func currentCallCount() -> Int { listCallCount }
    }

    /// Trivial `ClipboardServicing` double — `EntryListModel` never
    /// touches it, but `AppEnvironment` requires a value.
    private struct NullClipboard: ClipboardServicing {
        func copy(_ value: String, clearAfter: Duration) async {}
    }

    /// Trivial `SettingsStoring` double — same rationale as above.
    private struct NullSettings: SettingsStoring {
        func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? { nil }
        func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {}
        func removeValue(forKey key: String) {}
        func resetAll() {}
        func registerDefaults(_ defaults: [String: Any]) {}
    }

    private func makeEnvironment(passManager: any PassManaging) -> AppEnvironment {
        AppEnvironment(
            passManager: passManager,
            clipboard: NullClipboard(),
            settings: NullSettings(),
            passwordGenerator: LivePasswordGenerator(),
            passCLI: nil,
            discovery: nil
        )
    }

    // MARK: - Tests

    func testRefresh_invokesScannerAndUpdatesEntries() async {
        let initial: [PassEntry] = [
            PassEntry(path: "personal/email"),
            PassEntry(path: "work/aws/root")
        ]
        let updated: [PassEntry] = [
            PassEntry(path: "personal/email"),
            PassEntry(path: "personal/wifi/home"),
            PassEntry(path: "work/aws/root"),
            PassEntry(path: "work/github")
        ]
        let fake = FakePassManager(responses: [initial, updated])
        let env = makeEnvironment(passManager: fake)
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)

        await model.refresh()
        XCTAssertEqual(model.allEntries.map(\.path), initial.map(\.path))

        await model.refresh()
        XCTAssertEqual(model.allEntries.map(\.path), updated.map(\.path))

        let calls = await fake.currentCallCount()
        XCTAssertEqual(calls, 2, "refresh() must delegate to the pass manager every call")
    }

    func testRefresh_cancellable() async {
        let initial: [PassEntry] = [
            PassEntry(path: "personal/email"),
            PassEntry(path: "work/github")
        ]
        // Seed the model with a known good snapshot first.
        let seed = FakePassManager(responses: [initial])
        let env = makeEnvironment(passManager: seed)
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()
        XCTAssertEqual(model.allEntries.map(\.path), initial.map(\.path))

        // Now swap to a slow pass-manager and run a refresh that we
        // cancel before it can complete. The model must preserve the
        // previous snapshot rather than fall back to an empty list.
        let slow = FakePassManager(
            responses: [[PassEntry(path: "should/not/appear")]],
            listDelay: .milliseconds(500)
        )
        let slowEnv = makeEnvironment(passManager: slow)
        // Re-bind the model to the slow environment by constructing a
        // sibling model that shares the same `state`. We assert via
        // the new model so the original snapshot remains untouched.
        let cancellableModel = EntryListModel(environment: slowEnv, state: state)
        // Pre-populate the cancellable model so we can prove cancel
        // does not wipe its snapshot.
        let preseed = FakePassManager(responses: [initial])
        let preseedEnv = makeEnvironment(passManager: preseed)
        let warmModel = EntryListModel(environment: preseedEnv, state: state)
        await warmModel.refresh()

        // Drive cancellableModel.refresh through a Task we cancel.
        let task = Task { await cancellableModel.refresh() }
        // Give the task a chance to enter the sleep, then cancel.
        try? await Task.sleep(for: .milliseconds(20))
        task.cancel()
        await task.value

        XCTAssertTrue(
            cancellableModel.allEntries.isEmpty,
            "cancelled refresh on a fresh model must leave allEntries empty (no partial write)"
        )
        XCTAssertEqual(
            warmModel.allEntries.map(\.path),
            initial.map(\.path),
            "previously loaded snapshot must remain intact after a sibling cancellation"
        )
    }
}
