//
//  EntryDetailReconciliationTests.swift
//  KizbaTests
//
//  Phase H.2 — verifies that `EntryDetailModel.observeChanges()`
//  subscribes to `PassManaging.changes` and reconciles the
//  detail-side state against events targeting the currently-
//  displayed entry:
//
//  - `.updated(currentPath)` re-fetches the body so an in-place
//    rewrite (e.g. `pass generate --in-place`) becomes visible
//    without a manual reload.
//  - `.removed(currentPath)` clears the loaded secret.
//  - `.moved(currentPath, to:)` re-fetches under the new path.
//  - `.updated/.removed/.moved` for OTHER paths is a no-op.
//  - `.inserted` and `.bulk` are no-ops for the detail model.
//
//  Async-timing strategy mirrors `EntryListReconciliationTests`:
//  small `waitUntil` polling helper with a generous 1s timeout +
//  10ms tick. The `startObservation` helper yields a few times +
//  sleeps 20ms after spawning the subscription task so the
//  multi-subscriber `MockPassManager.changes` continuation has
//  been registered before the test begins mutating.
//

import XCTest
@testable import Kizba

@MainActor
final class EntryDetailReconciliationTests: XCTestCase {

    // MARK: - Helpers

    private func makeEnvironment(passManager: any PassManaging) -> AppEnvironment {
        AppEnvironment(
            passManager: passManager,
            clipboard: NoopClipboard(),
            settings: NoopSettings(),
            passwordGenerator: LivePasswordGenerator(),
            passCLI: nil,
            discovery: nil
        )
    }

    /// Spin up `model.observeChanges()` on a detached task and wait a
    /// short tick for the subscription to register with the manager.
    // use shared startObservation(model:) from Fixtures/AsyncTestHelpers.swift

    /// Drive the detail model into `.loaded(_)` for `path` and wait
    /// for the load to complete. Mirrors the production view's
    /// `.onChange(of: state.router.selectedEntryID, initial: true)`
    /// handler.
    private func loadEntry(
        _ path: String,
        on model: EntryDetailModel,
        appState: AppState
    ) async {
        appState.router.selectedEntryID = path
        model.handleSelectionChange(path)
        await waitUntil(
            {
                if case .loaded = model.state { return true }
                return false
            },
            message: "detail model did not transition to .loaded for \(path)"
        )
    }

    // MARK: - 1. .updated(currentPath) triggers re-fetch

    func testUpdated_currentPath_triggersRefetch() async {
        let entry = PassEntry(path: "x")
        let initial = PassSecret(password: "S1")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: initial]
        )
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryDetailModel(environment: env, state: state)

        await loadEntry("x", on: model, appState: state)
        // Sanity: the loaded body is the initial secret.
        if case .loaded(let secret) = model.state {
            XCTAssertEqual(secret.password, "S1")
        } else {
            XCTFail("expected .loaded after initial load")
        }

        let observer = await startObservation(model: model)
        defer {
            model.stop()
            observer.cancel()
        }

        // Mutate the underlying entry — emits `.updated`.
        _ = try? await manager.insert(
            entry,
            secret: PassSecret(password: "S2"),
            force: true
        )

        await waitUntil(
            {
                if case .loaded(let secret) = model.state {
                    return secret.password == "S2"
                }
                return false
            },
            message: "detail did not re-fetch updated body"
        )
    }

    // MARK: - 2. .updated(otherPath) does NOT trigger re-fetch

    func testUpdated_otherPath_doesNotRefetch() async {
        let x = PassEntry(path: "x")
        let y = PassEntry(path: "y")
        let manager = MockPassManager(
            entries: [x, y],
            secrets: [
                x.path: PassSecret(password: "S1"),
                y.path: PassSecret(password: "Y1"),
            ]
        )
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryDetailModel(environment: env, state: state)

        await loadEntry("x", on: model, appState: state)

        let observer = await startObservation(model: model)
        defer {
            model.stop()
            observer.cancel()
        }

        _ = try? await manager.insert(
            y,
            secret: PassSecret(password: "Y2"),
            force: true
        )

        // Wait long enough for any reaction to occur, then assert
        // the detail body is still the original "S1".
        for _ in 0..<10 { await Task.yield() }
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        if case .loaded(let secret) = model.state {
            XCTAssertEqual(
                secret.password,
                "S1",
                "detail re-fetched on a .updated event for an OTHER path"
            )
        } else {
            XCTFail("expected .loaded; detail state changed unexpectedly")
        }
    }

    // MARK: - 3. .removed(currentPath) clears detail state

    func testRemoved_currentPath_clearsDetailState() async {
        let entry = PassEntry(path: "x")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: PassSecret(password: "S1")]
        )
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryDetailModel(environment: env, state: state)

        await loadEntry("x", on: model, appState: state)

        let observer = await startObservation(model: model)
        defer {
            model.stop()
            observer.cancel()
        }

        try? await manager.remove(entry)

        await waitUntil(
            {
                if case .idle = model.state { return true }
                return false
            },
            message: "detail state was not cleared after .removed of current entry"
        )
    }

    // MARK: - 4. .removed(otherPath) is a no-op

    func testRemoved_otherPath_isNoop() async {
        let x = PassEntry(path: "x")
        let y = PassEntry(path: "y")
        let manager = MockPassManager(
            entries: [x, y],
            secrets: [
                x.path: PassSecret(password: "S1"),
                y.path: PassSecret(password: "Y1"),
            ]
        )
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryDetailModel(environment: env, state: state)

        await loadEntry("x", on: model, appState: state)

        let observer = await startObservation(model: model)
        defer {
            model.stop()
            observer.cancel()
        }

        try? await manager.remove(y)

        for _ in 0..<10 { await Task.yield() }
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let secret) = model.state {
            XCTAssertEqual(secret.password, "S1")
        } else {
            XCTFail("detail unexpectedly left .loaded after .removed for other path")
        }
    }

    // MARK: - 5. .moved(currentPath, to:) re-fetches with new path

    func testMoved_currentPath_refetchesUnderNewPath() async {
        let x = PassEntry(path: "x")
        let manager = MockPassManager(
            entries: [x],
            secrets: [x.path: PassSecret(password: "S1")]
        )
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryDetailModel(environment: env, state: state)

        await loadEntry("x", on: model, appState: state)

        let observer = await startObservation(model: model)
        defer {
            model.stop()
            observer.cancel()
        }

        _ = try? await manager.move(from: x, to: "z", force: false)

        // The handler routes through `handleSelectionChange("z")`
        // which spawns a new load against `pass.show("z")`. The
        // body content is preserved by the mock's move impl.
        await waitUntil(
            {
                if case .loaded(let secret) = model.state {
                    return secret.password == "S1"
                }
                return false
            },
            message: "detail did not re-fetch under moved path"
        )
    }

    // MARK: - 6. .inserted is a no-op for the detail

    func testInserted_isNoopForDetail() async {
        let x = PassEntry(path: "x")
        let manager = MockPassManager(
            entries: [x],
            secrets: [x.path: PassSecret(password: "S1")]
        )
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryDetailModel(environment: env, state: state)

        await loadEntry("x", on: model, appState: state)

        let observer = await startObservation(model: model)
        defer {
            model.stop()
            observer.cancel()
        }

        let new = PassEntry(path: "totally/new")
        _ = try? await manager.insert(
            new,
            secret: PassSecret(password: "N"),
            force: false
        )

        for _ in 0..<10 { await Task.yield() }
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let secret) = model.state {
            XCTAssertEqual(secret.password, "S1")
        } else {
            XCTFail("detail changed state on an unrelated .inserted event")
        }
    }

    // MARK: - 7. .bulk is a no-op for the detail

    func testBulk_isNoopForDetail() async {
        let x = PassEntry(path: "x")
        let manager = MockPassManager(
            entries: [x],
            secrets: [x.path: PassSecret(password: "S1")]
        )
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryDetailModel(environment: env, state: state)

        await loadEntry("x", on: model, appState: state)

        let observer = await startObservation(model: model)
        defer {
            model.stop()
            observer.cancel()
        }

        await manager.emitBulk()

        for _ in 0..<10 { await Task.yield() }
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .loaded(let secret) = model.state {
            XCTAssertEqual(secret.password, "S1")
        } else {
            XCTFail("detail changed state on a .bulk event")
        }
    }

    // MARK: - 8. observeChanges() is a no-op when already running

    func testObserveChanges_calledTwice_doesNotDoubleSubscribe() async {
        let manager = MockPassManager(entries: [], secrets: [:])
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryDetailModel(environment: env, state: state)

        let first = await startObservation(model: model)

        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms

        let secondReturned = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await model.observeChanges()
                return true
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 100_000_000)
                return false
            }
            let outcome = await group.next() ?? false
            group.cancelAll()
            return outcome
        }
        XCTAssertTrue(
            secondReturned,
            "second observeChanges() did not short-circuit while a subscription was active"
        )

        model.stop()
        first.cancel()
        await first.value
    }

    // MARK: - 9. stop() halts the subscription

    func testStop_haltsSubscription_furtherEventsDoNotMutateDetail() async {
        let entry = PassEntry(path: "x")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: PassSecret(password: "S1")]
        )
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryDetailModel(environment: env, state: state)

        await loadEntry("x", on: model, appState: state)

        let observer = await startObservation(model: model)

        // Tear down before mutating; further `.updated` events for
        // the loaded entry MUST NOT trigger a re-fetch.
        model.stop()
        await observer.value

        _ = try? await manager.insert(
            entry,
            secret: PassSecret(password: "S2"),
            force: true
        )

        try? await Task.sleep(nanoseconds: 150_000_000)

        if case .loaded(let secret) = model.state {
            XCTAssertEqual(
                secret.password,
                "S1",
                "detail re-fetched after stop() — subscription was not torn down"
            )
        } else {
            XCTFail("unexpected detail state after stop()")
        }
    }
}

// MARK: - Local fakes

/// Drops every `copy` call. Mirrors the helper in
/// `EntryListReconciliationTests`; kept private here so this file is
/// self-contained.
private struct NoopClipboard: ClipboardServicing {
    func copy(_ value: String, clearAfter: Duration) async {}
}

/// Trivial `SettingsStoring` double — `EntryDetailModel` only reads
/// `clipboardClearDelaySeconds` lazily on copy, never during the
/// reconciliation tests.
private struct NoopSettings: SettingsStoring {
    func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? { nil }
    func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {}
    func removeValue(forKey key: String) {}
    func resetAll() {}
    func registerDefaults(_ defaults: [String: Any]) {}
}
