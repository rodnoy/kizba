import Foundation
import Observation

@MainActor
@Observable
final class MenuBarModel {
    var query: String = ""
    var results: [SearchResult] = []
    var isLoading: Bool = false

    private let searchEngine: any EntrySearching
    private let recentStore: any RecentEntriesStoring
    private let favoritesStore: any FavoritesStoring
    private let clipboard: any ClipboardServicing
    private let passManager: any PassManaging
    private var currentTask: Task<Void, Never>?

    init(
        searchEngine: any EntrySearching,
        recentStore: any RecentEntriesStoring,
        favoritesStore: any FavoritesStoring,
        clipboard: any ClipboardServicing,
        passManager: any PassManaging
    ) {
        self.searchEngine = searchEngine
        self.recentStore = recentStore
        self.favoritesStore = favoritesStore
        self.clipboard = clipboard
        self.passManager = passManager
    }

    func updateQuery(_ q: String) {
        query = q
        currentTask?.cancel()

        currentTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: .milliseconds(150))
            } catch {
                return
            }
            await self.performSearch(q)
        }
    }

    func selectResult(_ index: Int) -> SearchResult? {
        guard results.indices.contains(index) else {
            return nil
        }
        return results[index]
    }

    func copyResultPassword(_ index: Int) async {
        guard let result = selectResult(index) else {
            return
        }

        let entry = PassEntry(path: result.id)
        guard let secret = try? await passManager.show(entry) else {
            return
        }

        await clipboard.copy(secret.password, clearAfter: .seconds(5))
    }

    private func performSearch(_ q: String) async {
        let trimmed = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            isLoading = false
            return
        }

        isLoading = true
        async let favoritePaths = favoritesStore.allFavorites()
        async let recentPaths = recentStore.recentPaths()

        let context = SearchContext(
            favoritePaths: await favoritePaths,
            recentPaths: Set(await recentPaths)
        )
        let found = try? await searchEngine.search(trimmed, context: context)

        if Task.isCancelled {
            return
        }

        results = found ?? []
        isLoading = false
    }
}
