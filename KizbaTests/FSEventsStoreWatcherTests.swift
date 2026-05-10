import Foundation
import XCTest

@testable import Kizba

final class FSEventsStoreWatcherTests: XCTestCase {
    func testFSEventsEmitsOnRealFSChange() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["KIZBA_FSEVENTS_TEST"] == "1", "Opt-in")

        let tmpDir = try TempStoreFixture.createTempStore(prefix: "kizba-fsevents-")

        let watcher = FSEventsStoreWatcher()
        await watcher.start(at: tmpDir)

        let exp = expectation(description: "fsevents")

        // Register subscriber before creating file.
        Task {
            var stream = watcher.events
            for await _ in stream {
                exp.fulfill()
                break
            }
        }

        // Give the registration a moment and then mutate the store from a Task.
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        Task {
            // Create a file inside tmpDir to trigger FSEvents.
            let _ = try TempStoreFixture.writeFile(store: tmpDir, relativePath: "touch.txt", contents: Data("hello".utf8))
        }

        wait(for: [exp], timeout: 1.0)

        await watcher.stop()
        try TempStoreFixture.removeTempStore(store: tmpDir)
    }
}
