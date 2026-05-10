import Foundation
import XCTest
@testable import Kizba

final class LivePassManagerFSEventsTests: XCTestCase {

    private static let fakePassURL = URL(fileURLWithPath: "/opt/homebrew/bin/pass")
    private static let storeRoot = URL(fileURLWithPath: "/tmp/kizba-fsevents-tests-store", isDirectory: true)

    // Minimal scanner used for wiring — operations are no-ops but
    // satisfy the protocol.
    private actor SimpleScanner: PasswordStoreScanning {
        func listEntries(in storeRoot: URL) async throws -> [String] { [] }
        func validateStoreRoot(_ storeRoot: URL) async -> Bool { true }
        func invalidate(storeRoot: URL) async {}
        func contains(path: String, in storeRoot: URL) async -> Bool { false }
    }

    private struct FixedLocator: BinaryLocating {
        func locate(_ binary: BinaryName) async -> URL? { LivePassManagerFSEventsTests.fakePassURL }
        func reDetect() async {}
    }

    private func makeManager(storeWatcher: FakeStoreWatcher) -> LivePassManager {
        let runner = FakeShellRunner()
        let cli = LivePassCLI(discovery: FixedLocator(), shellRunner: runner)
        let scanner = SimpleScanner()
        return LivePassManager(
            scanner: scanner,
            passCLI: cli,
            storeRoot: Self.storeRoot,
            storeWatcher: storeWatcher
        )
    }

    // MARK: - Tests

    func testWatcher_lazyStartsOnFirstSubscriber() async throws {
        let fake = FakeStoreWatcher()
        let manager = makeManager(storeWatcher: fake)

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        XCTAssertEqual(fake.getStartCount(), 1)

        await collector.cancel()
    }

    func testWatcher_doesNotStartTwiceOnSecondSubscriber() async throws {
        let fake = FakeStoreWatcher()
        let manager = makeManager(storeWatcher: fake)

        let collectorA = await makeStoreChangeCollector(for: manager.changes)
        let collectorB = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(30))

        XCTAssertEqual(fake.getStartCount(), 1)

        await collectorA.cancel()
        await collectorB.cancel()
    }

    func testWatcher_stopsOnLastUnsubscribe() async throws {
        let fake = FakeStoreWatcher()
        let manager = makeManager(storeWatcher: fake)

        let collectorA = await makeStoreChangeCollector(for: manager.changes)
        let collectorB = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(30))

        await collectorA.cancel()
        await collectorB.cancel()
        try await Task.sleep(for: .milliseconds(60))

        XCTAssertEqual(fake.getStopCount(), 1)
    }

    func testWatcher_emitsBulkOnSimulateChange() async throws {
        let fake = FakeStoreWatcher()
        let manager = makeManager(storeWatcher: fake)

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        fake.simulateChange()

        let events = await collector.collected(timeout: .seconds(1))
        XCTAssertEqual(events, [.bulk])

        await collector.cancel()
    }

    func testWatcher_multipleEmitsDeliveredToAllSubscribers() async throws {
        let fake = FakeStoreWatcher()
        let manager = makeManager(storeWatcher: fake)

        let collectorA = await makeStoreChangeCollector(for: manager.changes)
        let collectorB = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(30))

        fake.simulateChange()
        fake.simulateChange()

        let eventsA = await collectorA.collected(timeout: .seconds(1))
        let eventsB = await collectorB.collected(timeout: .seconds(1))
        XCTAssertEqual(eventsA, [.bulk, .bulk])
        XCTAssertEqual(eventsB, [.bulk, .bulk])

        await collectorA.cancel()
        await collectorB.cancel()
    }

    func testWatcher_stopDoesNotCrashIfNoSubscribers() async throws {
        let fake = FakeStoreWatcher()
        // Calling stop directly on the fake should be safe even with
        // zero subscribers.
        await fake.stop()
        XCTAssertGreaterThanOrEqual(fake.getStopCount(), 1)
    }
}

// MARK: - StoreChangeCollector (test-local)

private actor StoreChangeCollector {
    private var buffer: [StoreChange] = []
    private var task: Task<Void, Never>?

    init() {}

    fileprivate func start(stream: AsyncStream<StoreChange>) {
        task = Task { [self] in
            for await change in stream {
                await self.append(change)
            }
        }
    }

    private func append(_ change: StoreChange) {
        buffer.append(change)
    }

    func collected(timeout: Duration) async -> [StoreChange] {
        try? await Task.sleep(for: timeout)
        return buffer
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

private extension XCTestCase {
    func makeStoreChangeCollector(
        for stream: AsyncStream<StoreChange>
    ) async -> StoreChangeCollector {
        let c = StoreChangeCollector()
        await c.start(stream: stream)
        return c
    }
}
