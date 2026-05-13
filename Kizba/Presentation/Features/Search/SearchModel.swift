import Foundation
import Observation

@MainActor
@Observable
final class SearchModel {
    var query: String = ""
    var results: [SearchResult] = []
    var isLoading: Bool = false
    var selectedIndex: Int? = nil

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
            selectedIndex = nil
            isLoading = false
            return
        }

        isLoading = true
        let res = try? await searchEngine.search(trimmed)

        if Task.isCancelled {
            return
        }

        results = res ?? []
        selectedIndex = results.isEmpty ? nil : 0
        isLoading = false
    }

    func moveSelection(down: Bool) {
        guard !results.isEmpty else {
            selectedIndex = nil
            return
        }

        guard let current = selectedIndex else {
            selectedIndex = down ? 0 : results.count - 1
            return
        }

        let delta = down ? 1 : -1
        let next = min(max(current + delta, 0), results.count - 1)
        selectedIndex = next
    }

    func selectCurrent() -> SearchResult? {
        guard let selectedIndex, results.indices.contains(selectedIndex) else {
            return nil
        }

        return results[selectedIndex]
    }

    func resetSelection() {
        selectedIndex = results.isEmpty ? nil : 0
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
    }
}
