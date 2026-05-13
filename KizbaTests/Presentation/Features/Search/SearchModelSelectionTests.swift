import XCTest
@testable import Kizba

@MainActor
final class SearchModelSelectionTests: XCTestCase {

    private actor FakeSearchEngine: EntrySearching {
        let cannedResults: [SearchResult]

        init(cannedResults: [SearchResult]) {
            self.cannedResults = cannedResults
        }

        func search(_ query: String) async throws -> [SearchResult] {
            guard !query.isEmpty else { return [] }
            return cannedResults
        }
    }

    func testSelection_defaultsToFirstResult_afterSearch() async throws {
        let expected: [SearchResult] = [
            SearchResult(id: "work/mail", title: "mail", subtitle: "work", score: 1.0),
            SearchResult(id: "work/docs", title: "docs", subtitle: "work", score: 0.8)
        ]
        let model = SearchModel(searchEngine: FakeSearchEngine(cannedResults: expected))

        model.updateQuery("ma")
        try await Task.sleep(for: .milliseconds(350))

        XCTAssertEqual(model.selectedIndex, 0)
        XCTAssertEqual(model.selectCurrent(), expected[0])
    }

    func testMoveSelection_downAndUp_clampsCorrectly() {
        let expected: [SearchResult] = [
            SearchResult(id: "a", title: "a", subtitle: nil, score: 1),
            SearchResult(id: "b", title: "b", subtitle: nil, score: 0.9),
            SearchResult(id: "c", title: "c", subtitle: nil, score: 0.8)
        ]
        let model = SearchModel(searchEngine: FakeSearchEngine(cannedResults: expected))
        model.results = expected
        model.selectedIndex = nil

        model.moveSelection(down: true)
        XCTAssertEqual(model.selectedIndex, 0)

        model.moveSelection(down: true)
        model.moveSelection(down: true)
        XCTAssertEqual(model.selectedIndex, 2)

        model.selectedIndex = nil
        model.moveSelection(down: false)
        XCTAssertEqual(model.selectedIndex, 2)

        model.moveSelection(down: false)
        model.moveSelection(down: false)
        XCTAssertEqual(model.selectedIndex, 0)
    }

    func testSelection_resetsOnEmptyQuery() async throws {
        let expected: [SearchResult] = [
            SearchResult(id: "work/mail", title: "mail", subtitle: "work", score: 1.0)
        ]
        let model = SearchModel(searchEngine: FakeSearchEngine(cannedResults: expected))

        model.updateQuery("mail")
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertEqual(model.selectedIndex, 0)

        model.updateQuery("")
        try await Task.sleep(for: .milliseconds(300))

        XCTAssertTrue(model.results.isEmpty)
        XCTAssertNil(model.selectedIndex)
    }
}
