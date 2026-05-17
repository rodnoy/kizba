import XCTest
@testable import Kizba

@MainActor
final class MenuBarModelTests: XCTestCase {

    func testSearch_populatesResults() async throws {
        let expected = [
            SearchResult(id: "mail/gmail", title: "gmail", subtitle: "mail", score: 0.9),
            SearchResult(id: "mail/work", title: "work", subtitle: "mail", score: 0.8)
        ]
        let model = makeModel(searchEngine: FakeSearchEngine(cannedResults: expected))

        model.updateQuery("ma")
        try await Task.sleep(for: .milliseconds(350))

        XCTAssertEqual(model.results, expected)
    }

    func testSearch_emptyQueryClearsResults() async throws {
        let expected = [
            SearchResult(id: "mail/gmail", title: "gmail", subtitle: "mail", score: 0.9)
        ]
        let model = makeModel(searchEngine: FakeSearchEngine(cannedResults: expected))

        model.results = expected
        model.updateQuery("")
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertTrue(model.results.isEmpty)
    }

    func testSelection_and_copy() async {
        let expected = [
            SearchResult(id: "mail/gmail", title: "gmail", subtitle: "mail", score: 0.9)
        ]
        let fakeClipboard = FakeClipboardServicing()
        let model = makeModel(
            searchEngine: FakeSearchEngine(cannedResults: expected),
            clipboard: fakeClipboard
        )

        model.results = expected

        XCTAssertEqual(model.selectResult(0), expected[0])

        await model.copyResultPassword(0)

        XCTAssertEqual(fakeClipboard.lastCall?.value, "pw:mail/gmail")
        XCTAssertEqual(fakeClipboard.lastCall?.clearAfter, .seconds(5))
    }

    private func makeModel(
        searchEngine: any EntrySearching,
        clipboard: FakeClipboardServicing = FakeClipboardServicing()
    ) -> MenuBarModel {
        MenuBarModel(
            searchEngine: searchEngine,
            recentStore: FakeRecentEntriesStore(),
            favoritesStore: FakeFavoritesStore(),
            clipboard: clipboard,
            passManager: FakePassManager()
        )
    }
}

actor FakeSearchEngine: EntrySearching {
    private let cannedResults: [SearchResult]

    init(cannedResults: [SearchResult]) {
        self.cannedResults = cannedResults
    }

    func search(_ query: String, context: SearchContext?) async throws -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? [] : cannedResults
    }
}

actor FakePassManager: PassManaging {
    func listEntries() async throws -> [PassEntry] {
        []
    }

    func show(_ entry: PassEntry) async throws -> PassSecret {
        PassSecret(password: "pw:\(entry.path)")
    }

    func storeLocation() -> URL {
        URL(fileURLWithPath: "/tmp", isDirectory: true)
    }

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        fatalError("Not used in these tests")
    }

    func generate(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool,
        force: Bool
    ) async throws -> PassSecret {
        fatalError("Not used in these tests")
    }

    func generateInPlace(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool
    ) async throws -> PassSecret {
        fatalError("Not used in these tests")
    }

    func remove(_ entry: PassEntry) async throws {
        fatalError("Not used in these tests")
    }

    func move(from: PassEntry, to newPath: String, force: Bool) async throws -> PassEntry {
        fatalError("Not used in these tests")
    }

    var changes: AsyncStream<StoreChange> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
