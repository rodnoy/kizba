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

        var observed = false

        let task = Task {
            for await _ in watcher.events {
                observed = true
                break
            }
        }

        await watcher.start(at: tmp)
        watcher.simulateChange()

        // wait until observed or timeout
        await waitUntil({ observed }, timeout: 1.0)
        XCTAssertTrue(observed)

        task.cancel()
        await watcher.stop()
    }

    func testMultipleSubscribersReceiveEvents() async {
        let watcher = FakeStoreWatcher()
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("kizba-test-store")

        var observed1 = false
        var observed2 = false

        let t1 = Task {
            for await _ in watcher.events {
                observed1 = true
                break
            }
        }

        let t2 = Task {
            for await _ in watcher.events {
                observed2 = true
                break
            }
        }

        await watcher.start(at: tmp)
        watcher.simulateChange()

        await waitUntil({ observed1 && observed2 }, timeout: 1.0)

        XCTAssertTrue(observed1)
        XCTAssertTrue(observed2)

        t1.cancel()
        t2.cancel()
        await watcher.stop()
    }
}
