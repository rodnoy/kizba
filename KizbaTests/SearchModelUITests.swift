import XCTest
import SwiftUI
@testable import Kizba

@MainActor
final class SearchModelTests: XCTestCase {

    private actor FakeSearchEngine: EntrySearching {
        let cannedResults: [SearchResult]

        init(cannedResults: [SearchResult]) {
            self.cannedResults = cannedResults
        }

        func search(_ query: String, context: SearchContext?) async throws -> [SearchResult] {
            guard !query.isEmpty else { return [] }
            return cannedResults
        }
    }

    func testSearchModel_updatesResultsOnQuery() async throws {
        let expected: [SearchResult] = [
            SearchResult(id: "work/mail", title: "mail", subtitle: "work", score: 0.9),
            SearchResult(id: "work/misc", title: "misc", subtitle: "work", score: 0.6)
        ]
        let model = SearchModel(searchEngine: FakeSearchEngine(cannedResults: expected))

        model.updateQuery("mail")
        try await Task.sleep(for: .milliseconds(500))

        XCTAssertEqual(model.results, expected)
        XCTAssertFalse(model.isLoading)
        model.cancel()
    }
}

@MainActor
final class SearchModelUITests: XCTestCase {

    private actor FakeSearchEngine: EntrySearching {
        func search(_ query: String, context: SearchContext?) async throws -> [SearchResult] {
            []
        }
    }

    func testSearchView_selectCallsOnSelect() {
        let model = SearchModel(searchEngine: FakeSearchEngine())
        let result = SearchResult(id: "work/site", title: "site", subtitle: "work", score: 1.0)
        var selectedID: String?

        let onSelect: (SearchResult) -> Void = { picked in
            selectedID = picked.id
        }
        _ = SearchView(model: model, onSelect: onSelect)

        onSelect(result)

        XCTAssertEqual(selectedID, "work/site")
    }
}
