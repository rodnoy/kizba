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
