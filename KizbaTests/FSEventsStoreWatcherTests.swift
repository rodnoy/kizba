import XCTest
import Foundation

@testable import Kizba

final class FSEventsStoreWatcherTests: XCTestCase {
    func testFSEventsEmitsOnRealFSChange() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["KIZBA_FSEVENTS_TEST"] == "1", "Opt-in")

        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("kizba-fsevents-test-")
        let dir = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: tmp, create: true)

        let watcher = FSEventsStoreWatcher()
        await watcher.start(at: dir)

        let stream = watcher.events

        let expectation = expectation(description: "received fsevent")

        let task = Task {
            for await _ in stream {
                expectation.fulfill()
                break
            }
        }

        // Make a filesystem change
        let file = dir.appendingPathComponent("touch-me.txt")
        try "hello".write(to: file, atomically: true, encoding: .utf8)

        wait(for: [expectation], timeout: 1.0)

        task.cancel()
        await watcher.stop()
    }
}
