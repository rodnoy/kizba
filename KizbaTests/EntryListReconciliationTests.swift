//
//  EntryListReconciliationTests.swift
//  KizbaTests
//
//  Phase F.5 — verifies that `EntryListModel.observeChanges()`
//  subscribes to `PassManaging.changes` and re-fetches the entry
//  snapshot on every `StoreChange` event so the list reflects the
//  underlying FS state without a manual refresh.
//
//  Selection follow-up rules (`.removed` clears selection,
//  `.moved` follows from → to, etc.) are deferred to Phase H —
//  this file only asserts the F.5 contract: any change → re-list.
//  The file name is forward-compatible so Phase H can extend it.
//
//  Async-timing strategy: every assertion that depends on a
//  `StoreChange` round-tripping through the AsyncStream uses the
//  shared `waitUntil(...)` polling helper with a generous 1s
//  timeout and 10ms tick — long enough to absorb scheduler jitter,
//  short enough to keep the suite snappy.
//

import XCTest
@testable import Kizba

@MainActor
final class EntryListReconciliationTests: XCTestCase {

    // MARK: - Helpers

    /// Polls `predicate` on the MainActor until it returns `true` or
    /// `timeout` seconds elapse. On timeout records an `XCTFail` so
    /// the suite does not hang forever.
    private func waitUntil(
        _ predicate: @MainActor () -> Bool,
        timeout: TimeInterval = 1.0,
        message: String = "predicate did not become true in time",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if predicate() { return }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        XCTFail(message, file: file, line: line)
    }

    /// Build an `AppEnvironment` whose `passManager` is the supplied
    /// double. The other collaborators are no-op fakes — the model
    /// under test only touches `passManager`.
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

    /// Spin up `model.observeChanges()` on a detached task. Returns
    /// the task so the test can cancel it (or rely on `model.stop()`)
    /// on tear-down. The model's own `changeSubscriptionTask` is
    /// what actually drives the subscription; this wrapping task
    /// only keeps `observeChanges()` alive for the duration of the
    /// test.
    ///
    /// Note: the call awaits a short tick after spawning the task so
    /// `MockPassManager.changes` has a chance to register the new
    /// continuation under actor isolation. Without this, an immediate
    /// follow-up mutation can be emitted to a not-yet-registered
    /// subscriber and the event is silently lost — a known property
    /// of the multi-subscriber `AsyncStream` pattern in
    /// `MockPassManager` (continuation registration runs through a
    /// detached `Task`).
    private func startObservation(model: EntryListModel) async -> Task<Void, Never> {
        let task = Task { await model.observeChanges() }
        // Yield the main actor a few times so the subscription task
        // can hop to the manager actor and register itself before the
        // test starts mutating.
        for _ in 0..<5 {
            await Task.yield()
        }
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms safety margin
        return task
    }

    // MARK: - 1. .inserted re-lists

    func testSubscription_receivesInsertedEvent_andRefreshesEntries() async {
        let manager = MockPassManager(entries: [], secrets: [:])
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)

        // Initial refresh — empty store.
        await model.refresh()
        XCTAssertTrue(model.allEntries.isEmpty)

        let observer = await startObservation(model: model)
        defer {
            model.stop()
            observer.cancel()
        }

        // Direct mutation through the manager — no form-model in the
        // loop. Isolates the AsyncStream wiring.
        let entry = PassEntry(path: "personal/new")
        _ = try? await manager.insert(
            entry,
            secret: PassSecret(password: "p"),
            force: false
        )

        await waitUntil(
            { model.allEntries.contains(where: { $0.path == "personal/new" }) },
            message: "inserted entry never appeared in EntryListModel.allEntries"
        )
    }

    // MARK: - 2. .removed re-lists

    func testSubscription_receivesRemovedEvent_andRefreshesEntries() async {
        let entry = PassEntry(path: "work/legacy")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: PassSecret(password: "old")]
        )
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)

        await model.refresh()
        XCTAssertEqual(model.allEntries.map(\.path), ["work/legacy"])

        let observer = await startObservation(model: model)
        defer {
            model.stop()
            observer.cancel()
        }

        try? await manager.remove(entry)

        await waitUntil(
            { !model.allEntries.contains(where: { $0.path == "work/legacy" }) },
            message: "removed entry remained in EntryListModel.allEntries"
        )
    }

    // MARK: - 3. .moved re-lists

    func testSubscription_receivesMovedEvent_andRefreshesEntries() async {
        let entry = PassEntry(path: "old/home")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: PassSecret(password: "p")]
        )
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)

        await model.refresh()
        XCTAssertEqual(model.allEntries.map(\.path), ["old/home"])

        let observer = await startObservation(model: model)
        defer {
            model.stop()
            observer.cancel()
        }

        _ = try? await manager.move(from: entry, to: "new/home", force: false)

        await waitUntil(
            {
                !model.allEntries.contains(where: { $0.path == "old/home" })
                    && model.allEntries.contains(where: { $0.path == "new/home" })
            },
            message: "moved entry: old path still present or new path missing"
        )
    }

    // MARK: - 4. Multiple events in sequence

    func testSubscription_handlesMultipleEvents_inOrder() async {
        let manager = MockPassManager(entries: [], secrets: [:])
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        let observer = await startObservation(model: model)
        defer {
            model.stop()
            observer.cancel()
        }

        let a = PassEntry(path: "a")
        let b = PassEntry(path: "b")
        let c = PassEntry(path: "c")

        // insert a, insert b, remove a, insert c.
        _ = try? await manager.insert(a, secret: PassSecret(password: "p"), force: false)
        _ = try? await manager.insert(b, secret: PassSecret(password: "p"), force: false)
        try? await manager.remove(a)
        _ = try? await manager.insert(c, secret: PassSecret(password: "p"), force: false)

        await waitUntil(
            {
                let paths = Set(model.allEntries.map(\.path))
                return paths == ["b", "c"]
            },
            message: "final list state did not converge to {b, c}"
        )
    }

    // MARK: - 5. stop() halts subscription

    func testStop_haltsSubscription_furtherEventsDoNotRefresh() async {
        let manager = MockPassManager(entries: [], secrets: [:])
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        let observer = await startObservation(model: model)

        // First event — proves the subscription is live.
        let first = PassEntry(path: "first")
        _ = try? await manager.insert(first, secret: PassSecret(password: "p"), force: false)
        await waitUntil(
            { model.allEntries.contains(where: { $0.path == "first" }) },
            message: "first insert never propagated"
        )

        // Tear it down, wait for the wrapping task to complete so the
        // `for await` loop has actually exited.
        model.stop()
        await observer.value

        // Second event — must NOT update the list. We give the system
        // ample time to do the wrong thing.
        let second = PassEntry(path: "second")
        _ = try? await manager.insert(second, secret: PassSecret(password: "p"), force: false)
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

        XCTAssertFalse(
            model.allEntries.contains(where: { $0.path == "second" }),
            "list updated after stop() — subscription was not torn down"
        )
        XCTAssertTrue(
            model.allEntries.contains(where: { $0.path == "first" }),
            "first insert (before stop) must remain reflected in the list"
        )
    }

    // MARK: - 6. observeChanges() is a no-op when already running

    func testObserveChanges_calledTwice_doesNotDoubleSubscribe() async {
        let manager = MockPassManager(entries: [], secrets: [:])
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let model = EntryListModel(environment: env, state: state)
        await model.refresh()

        let first = await startObservation(model: model)

        // Give the first subscription a tick to register itself with
        // the manager.
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms

        // The second call should return promptly because the model
        // already has an active subscription.
        let secondReturned = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await model.observeChanges()
                return true
            }
            // Race the second call against a short delay; if
            // `observeChanges()` doesn't short-circuit it will block
            // for the entire suite duration.
            group.addTask {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                return false
            }
            let outcome = await group.next() ?? false
            group.cancelAll()
            return outcome
        }
        XCTAssertTrue(
            secondReturned,
            "second observeChanges() call did not short-circuit while a subscription was active"
        )

        // Cleanup — the first subscription is still live.
        model.stop()
        first.cancel()
        await first.value
    }

    // MARK: - 7. End-to-end with EntryFormModel

    func testEndToEnd_formModelInsert_listAutoRefreshes_andSelectionFollows() async {
        let manager = MockPassManager(entries: [], secrets: [:])
        let env = makeEnvironment(passManager: manager)
        let state = AppState()
        let listModel = EntryListModel(environment: env, state: state)
        await listModel.refresh()

        let observer = await startObservation(model: listModel)
        defer {
            listModel.stop()
            observer.cancel()
        }

        let formModel = EntryFormModel(
            mode: .create,
            passManager: manager,
            toastCenter: state.toastCenter,
            appState: state
        )
        formModel.path = "new/from-form"
        formModel.draft.password = "p"
        formModel.save()

        // Wait for the list to pick up the inserted entry — this is
        // the F.5 contract: form-model save → manager.insert →
        // .inserted on changes → listModel.refresh → new row visible.
        await waitUntil(
            { listModel.allEntries.contains(where: { $0.path == "new/from-form" }) },
            message: "EntryListModel did not refresh after EntryFormModel.save()"
        )

        // Selection set imperatively by EntryFormModel.applySuccess.
        XCTAssertEqual(state.selectedEntryID, "new/from-form")

        // Success toast posted by the form model.
        XCTAssertEqual(state.toastCenter.visible?.severity, .success)
        XCTAssertEqual(state.toastCenter.visible?.title, "Entry created")
    }
}

// MARK: - Local fakes

/// Drops every `copy` call. Reused from existing test files'
/// pattern — kept private here so this file is self-contained.
private struct NoopClipboard: ClipboardServicing {
    func copy(_ value: String, clearAfter: Duration) async {}
}

/// Trivial `SettingsStoring` double — `EntryListModel` never reads
/// settings, but `AppEnvironment` requires a value.
private struct NoopSettings: SettingsStoring {
    func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? { nil }
    func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {}
    func removeValue(forKey key: String) {}
    func resetAll() {}
    func registerDefaults(_ defaults: [String: Any]) {}
}
