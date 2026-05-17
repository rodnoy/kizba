//
//  RecentsModelTests.swift
//  KizbaTests
//
//  Unit tests for the sidebar recents view model.
//

import XCTest
@testable import Kizba

@MainActor
final class RecentsModelTests: XCTestCase {

    func testLoad_populatesRecents() async {
        let store = FakeRecentEntriesStore(initialPaths: ["a", "b"])
        let model = RecentsModel(store: store)

        await model.load()

        XCTAssertEqual(model.recents, ["a", "b"])
    }

    func testLoad_observesChanges() async {
        let store = FakeRecentEntriesStore()
        let model = RecentsModel(store: store)

        let observer = await startObservation(model: model)
        defer { observer.cancel() }

        await store.record("x")

        await waitUntil {
            model.recents.contains("x")
        }
    }

    /// MVP6 Phase A.3: end-to-end check that `RecentsModel` observes
    /// the cap mutation introduced in A.2. After recording 7 entries,
    /// calling `setMaxCount(4)` on the store must truncate to 4 and
    /// the change must propagate to the model via `recentsChanged`.
    func testCappedListReflectsSetMaxCount() async {
        let store = FakeRecentEntriesStore()
        let model = RecentsModel(store: store)

        let observer = await startObservation(model: model)
        defer { observer.cancel() }

        // Record 7 entries (matches the default cap). Newest first.
        for path in ["a", "b", "c", "d", "e", "f", "g"] {
            await store.record(path)
        }

        await waitUntil { model.recents.count == 7 }

        await store.setMaxCount(4)

        await waitUntil { model.recents.count == 4 }

        // Truncation keeps the newest-first prefix.
        XCTAssertEqual(model.recents, ["g", "f", "e", "d"])
    }

    func testStop_cancelsObservation() async throws {
        let store = FakeRecentEntriesStore()
        let model = RecentsModel(store: store)

        let observer = await startObservation(model: model)
        defer { observer.cancel() }

        model.stop()

        await store.record("y")
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(model.recents, [])
    }

    // MARK: - MVP6 Phase H.2: validation at load time

    /// `load()` must drop paths that the injected validator deems
    /// invalid (i.e. not present in the live password store). This is
    /// the final fix for the fixture-paths-in-Recents leak that
    /// survived H.1's schema bump.
    func testLoad_filtersOutInvalidPaths() async {
        let store = FakeRecentEntriesStore(initialPaths: ["valid/a", "fixture/x", "valid/b"])
        let validator = FakeRecentEntriesValidator(validPaths: ["valid/a", "valid/b"])
        let model = RecentsModel(store: store, validator: validator)

        await model.load()

        XCTAssertEqual(model.recents, ["valid/a", "valid/b"])
        let calls = await validator.validateCalls
        XCTAssertEqual(calls, 1)
    }

    /// When the validator accepts every path the model behaves
    /// identically to the legacy (no-validator) path.
    func testLoad_returnsAllPathsWhenAllValid() async {
        let store = FakeRecentEntriesStore(initialPaths: ["a", "b"])
        let validator = FakeRecentEntriesValidator(validPaths: ["a", "b"])
        let model = RecentsModel(store: store, validator: validator)

        await model.load()

        XCTAssertEqual(model.recents, ["a", "b"])
    }

    /// When the validator rejects everything the sidebar is empty —
    /// this is the exact symptom the user will see on first launch
    /// after H.2 ships against the polluted plist.
    func testLoad_returnsEmptyWhenNothingValid() async {
        let store = FakeRecentEntriesStore(initialPaths: ["fixture/x", "fixture/y"])
        let validator = FakeRecentEntriesValidator(validPaths: [])
        let model = RecentsModel(store: store, validator: validator)

        await model.load()

        XCTAssertTrue(model.recents.isEmpty)
    }

    /// `nil` validator preserves the pre-H.2 behaviour so existing
    /// preview/test wirings remain untouched.
    func testLoad_withoutValidator_passesPathsThrough() async {
        let store = FakeRecentEntriesStore(initialPaths: ["fixture/x", "fixture/y"])
        let model = RecentsModel(store: store, validator: nil)

        await model.load()

        XCTAssertEqual(model.recents, ["fixture/x", "fixture/y"])
    }

    private func startObservation(model: RecentsModel) async -> Task<Void, Never> {
        let task = Task { await model.load() }
        for _ in 0..<5 { await Task.yield() }
        try? await Task.sleep(for: .milliseconds(20))
        return task
    }
}
