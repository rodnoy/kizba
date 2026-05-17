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

    private func startObservation(model: RecentsModel) async -> Task<Void, Never> {
        let task = Task { await model.load() }
        for _ in 0..<5 { await Task.yield() }
        try? await Task.sleep(for: .milliseconds(20))
        return task
    }
}
