import XCTest
@testable import Kizba

@MainActor
final class SearchTests: XCTestCase {

    private actor LocalMockPassManager: PassManaging {
        private let entries: [PassEntry]
        private let listDelay: Duration?

        init(entries: [PassEntry], listDelay: Duration? = nil) {
            self.entries = entries
            self.listDelay = listDelay
        }

        func listEntries() async throws -> [PassEntry] {
            if let listDelay {
                try await Task.sleep(for: listDelay)
            }
            return entries
        }

        func show(_ entry: PassEntry) async throws -> PassSecret {
            fatalError("show(_:) is not used by SearchTests")
        }

        nonisolated func storeLocation() -> URL {
            URL(fileURLWithPath: "/tmp/kizba-search-tests")
        }
    }

    func testSearch_returnsResults_forSimpleQuery() async throws {
        let entries: [PassEntry] = [
            PassEntry(path: "work/alpha/needle"),
            PassEntry(path: "personal/needle-box"),
            PassEntry(path: "archive/misc/some-needle-item")
        ]
        let mock = LocalMockPassManager(entries: entries)
        let engine = LiveSearchEngine(passManager: mock)

        let results = try await engine.search("needle")

        XCTAssertEqual(results.map(\.id), [
            "work/alpha/needle",
            "personal/needle-box",
            "archive/misc/some-needle-item"
        ])
        XCTAssertTrue(results.allSatisfy { $0.score > 0 })
    }

    func testSearch_emptyQuery_returnsEmpty() async throws {
        let mock = LocalMockPassManager(entries: [PassEntry(path: "work/alpha/needle")])
        let engine = LiveSearchEngine(passManager: mock)

        let results = try await engine.search("")

        XCTAssertTrue(results.isEmpty)
    }

    func testSearch_caseInsensitive() async throws {
        let mock = LocalMockPassManager(entries: [
            PassEntry(path: "work/alpha/needle"),
            PassEntry(path: "work/alpha/other")
        ])
        let engine = LiveSearchEngine(passManager: mock)

        let results = try await engine.search("NeEdLe")

        XCTAssertEqual(results.map(\.id), ["work/alpha/needle"])
    }

    func testSearch_cancellation() async {
        let mock = LocalMockPassManager(
            entries: [PassEntry(path: "work/alpha/needle")],
            listDelay: .milliseconds(300)
        )
        let engine = LiveSearchEngine(passManager: mock)

        let task = Task {
            try await engine.search("needle")
        }

        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
