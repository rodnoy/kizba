import Foundation
import Observation

@MainActor
@Observable
final class SearchModel {
    var query: String = ""
    var results: [SearchResult] = []
    var isLoading: Bool = false

    private let searchEngine: any EntrySearching
    private var currentTask: Task<Void, Never>?

    init(searchEngine: any EntrySearching) {
        self.searchEngine = searchEngine
    }

    func updateQuery(_ q: String) {
        query = q
        currentTask?.cancel()

        currentTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: .milliseconds(200))
            } catch {
                return
            }
            await self.performSearch(q)
        }
    }

    private func performSearch(_ q: String) async {
        let trimmed = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            isLoading = false
            return
        }

        isLoading = true
        let res = try? await searchEngine.search(trimmed)

        if Task.isCancelled {
            return
        }

        results = res ?? []
        isLoading = false
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
    }
}
