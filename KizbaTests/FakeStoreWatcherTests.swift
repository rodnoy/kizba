import XCTest
@testable import Kizba

@MainActor
final class FakeStoreWatcherTests: XCTestCase {

    func testStartStopCounts() async {
        let watcher = FakeStoreWatcher()
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("kizba-test-store")

        await watcher.start(at: tmp)
        XCTAssertEqual(watcher.getStartCount(), 1)

        await watcher.stop()
        XCTAssertEqual(watcher.getStopCount(), 1)
    }

    func testSimulateChangeEmitsEvent() async {
        let watcher = FakeStoreWatcher()
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("kizba-test-store")

        let ready = expectation(description: "subscriber ready")
        let observed = expectation(description: "observed")

        let task = Task { @MainActor in
            // Signal that the subscriber task has started and is about to register
            // its AsyncStream iteration (so the continuation will be added).
            ready.fulfill()
            for await _ in watcher.events {
                observed.fulfill()
                break
            }
        }

        // Wait until the subscriber task has started and registered.
        await fulfillment(of: [ready], timeout: 0.5)

        await watcher.start(at: tmp)
        watcher.simulateChange()

        await fulfillment(of: [observed], timeout: 1.0)

        task.cancel()
        await watcher.stop()
    }

    func testMultipleSubscribersReceiveEvents() async {
        let watcher = FakeStoreWatcher()
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("kizba-test-store")

        let ready1 = expectation(description: "subscriber ready")
        let ready2 = expectation(description: "subscriber ready")
        let observed1 = expectation(description: "observed1")
        let observed2 = expectation(description: "observed2")

        let t1 = Task { @MainActor in
            ready1.fulfill()
            for await _ in watcher.events {
                observed1.fulfill()
                break
            }
        }

        let t2 = Task { @MainActor in
            ready2.fulfill()
            for await _ in watcher.events {
                observed2.fulfill()
                break
            }
        }

        // Ensure both subscribers have started and registered their continuations
        await fulfillment(of: [ready1, ready2], timeout: 0.5)

        await watcher.start(at: tmp)
        watcher.simulateChange()

        await fulfillment(of: [observed1, observed2], timeout: 1.0)

        t1.cancel()
        t2.cancel()
        await watcher.stop()
    }
}
