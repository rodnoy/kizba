import Foundation
import XCTest

@testable import Kizba

final class FSEventsStoreWatcherTests: XCTestCase {
    func testFSEventsEmitsOnRealFSChange() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["KIZBA_FSEVENTS_TEST"] == "1", "Opt-in")

        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("kizba-fsevents-\(UUID())")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

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

        // Give the registration a moment.
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Create a file inside tmpDir to trigger FSEvents.
        let file = tmpDir.appendingPathComponent("touch.txt")
        try "hello".write(to: file, atomically: true, encoding: .utf8)

        wait(for: [exp], timeout: 1.0)

        await watcher.stop()
        try FileManager.default.removeItem(at: tmpDir)
    }
}
