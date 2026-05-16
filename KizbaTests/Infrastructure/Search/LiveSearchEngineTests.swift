import XCTest
@testable import Kizba

@MainActor
final class LiveSearchEngineTests: XCTestCase {

    func testSearch_returnsResultsForMatchingQuery() async throws {
        let entries = [
            PassEntry(path: "work/alpha/needle"),
            PassEntry(path: "personal/needle-box"),
            PassEntry(path: "archive/misc/item")
        ]
        let manager = MockPassManager(entries: entries, secrets: [:])
        let engine = LiveSearchEngine(passManager: manager)

        let results = try await engine.search("needle", context: nil)

        XCTAssertEqual(results.map(\.id), ["work/alpha/needle", "personal/needle-box"])
        XCTAssertTrue(results.allSatisfy { $0.score > 0 })
    }

    func testSearch_emptyQueryReturnsEmpty() async throws {
        let manager = MockPassManager(entries: [PassEntry(path: "work/alpha/needle")], secrets: [:])
        let engine = LiveSearchEngine(passManager: manager)

        let results = try await engine.search("", context: SearchContext())

        XCTAssertTrue(results.isEmpty)
    }

    func testSearch_exactMatchScoresHighest() async throws {
        let entries = [
            PassEntry(path: "work/needle"),
            PassEntry(path: "work/needle-box"),
            PassEntry(path: "archive/some-needle-item")
        ]
        let manager = MockPassManager(entries: entries, secrets: [:])
        let engine = LiveSearchEngine(passManager: manager)

        let results = try await engine.search("needle", context: nil)

        guard let first = results.first else {
            XCTFail("Expected at least one search result")
            return
        }

        XCTAssertEqual(first.id, "work/needle")
        XCTAssertEqual(first.score, 1.0, accuracy: 0.000_001)
        XCTAssertGreaterThan(results[0].score, results[1].score)
    }

    func testSearch_favoriteGetsBoost() async throws {
        let entries = [
            PassEntry(path: "work/portal-alpha"),
            PassEntry(path: "personal/portal-beta")
        ]
        let manager = MockPassManager(entries: entries, secrets: [:])
        let engine = LiveSearchEngine(passManager: manager)
        let context = SearchContext(favoritePaths: ["personal/portal-beta"], recentPaths: [])

        let results = try await engine.search("portal", context: context)

        guard let first = results.first else {
            XCTFail("Expected at least one search result")
            return
        }

        XCTAssertEqual(first.id, "personal/portal-beta")
        XCTAssertEqual(first.score, 0.95, accuracy: 0.000_001)
    }

    func testSearch_recentGetsBoost() async throws {
        let entries = [
            PassEntry(path: "work/portal-alpha"),
            PassEntry(path: "personal/portal-beta")
        ]
        let manager = MockPassManager(entries: entries, secrets: [:])
        let engine = LiveSearchEngine(passManager: manager)
        let context = SearchContext(favoritePaths: [], recentPaths: ["personal/portal-beta"])

        let results = try await engine.search("portal", context: context)

        guard let first = results.first else {
            XCTFail("Expected at least one search result")
            return
        }

        XCTAssertEqual(first.id, "personal/portal-beta")
        XCTAssertEqual(first.score, 0.93, accuracy: 0.000_001)
    }

    func testSearch_favoriteAndRecentBoostStack() async throws {
        let entries = [
            PassEntry(path: "work/portal-alpha"),
            PassEntry(path: "personal/portal-beta")
        ]
        let manager = MockPassManager(entries: entries, secrets: [:])
        let engine = LiveSearchEngine(passManager: manager)
        let context = SearchContext(
            favoritePaths: ["personal/portal-beta"],
            recentPaths: ["personal/portal-beta"]
        )

        let results = try await engine.search("portal", context: context)

        guard let first = results.first else {
            XCTFail("Expected at least one search result")
            return
        }

        XCTAssertEqual(first.id, "personal/portal-beta")
        XCTAssertEqual(first.score, 0.98, accuracy: 0.000_001)
    }

    func testSearch_boostDoesNotExceedOne() async throws {
        let entries = [PassEntry(path: "work/needle")]
        let manager = MockPassManager(entries: entries, secrets: [:])
        let engine = LiveSearchEngine(passManager: manager)
        let context = SearchContext(favoritePaths: ["work/needle"], recentPaths: ["work/needle"])

        let results = try await engine.search("needle", context: context)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].score, 1.0, accuracy: 0.000_001)
    }

    func testSearch_noContextSameAsBefore() async throws {
        let entries = [
            PassEntry(path: "work/portal-alpha"),
            PassEntry(path: "personal/portal-beta")
        ]
        let manager = MockPassManager(entries: entries, secrets: [:])
        let engine = LiveSearchEngine(passManager: manager)

        let baseline = try await engine.search("portal")
        let withNilContext = try await engine.search("portal", context: nil)

        XCTAssertEqual(withNilContext, baseline)
    }
}
