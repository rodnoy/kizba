import Foundation
import Observation

@MainActor
@Observable
final class MenuBarModel {
    var query: String = ""
    var results: [SearchResult] = []
    var isLoading: Bool = false
    public private(set) var recents: [String] = []
    public private(set) var favorites: [String] = []
    public private(set) var isCopying: Bool = false

    private let searchEngine: any EntrySearching
    private let recentStore: any RecentEntriesStoring
    private let favoritesStore: any FavoritesStoring
    private let clipboard: any ClipboardServicing
    private let passManager: any PassManaging
    private var currentTask: Task<Void, Never>?
    private var recentsTask: Task<Void, Never>? = nil
    private var favoritesTask: Task<Void, Never>? = nil

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

        await copyEntry(path: result.id)
    }

    public func loadRecentsAndFavorites() async {
        async let recentPaths = recentStore.recentPaths()
        async let favoritePaths = favoritesStore.allFavorites()

        recents = await recentPaths
        favorites = Array(await favoritePaths).sorted()

        stop()

        recentsTask = Task { [weak self] in
            guard let self else { return }
            for await _ in recentStore.recentsChanged {
                do {
                    try Task.checkCancellation()
                } catch {
                    return
                }
                self.recents = await recentStore.recentPaths()
            }
        }

        favoritesTask = Task { [weak self] in
            guard let self else { return }
            for await _ in favoritesStore.favoritesChanged {
                do {
                    try Task.checkCancellation()
                } catch {
                    return
                }
                self.favorites = Array(await favoritesStore.allFavorites()).sorted()
            }
        }
    }

    public func stop() {
        recentsTask?.cancel()
        recentsTask = nil
        favoritesTask?.cancel()
        favoritesTask = nil
    }

    public func copyEntry(path: String) async {
        isCopying = true
        defer {
            isCopying = false
        }

        do {
            let secret = try await passManager.show(PassEntry(path: path))
            await clipboard.copy(secret.password, clearAfter: .seconds(5))
            await recentStore.record(path)
        } catch {
            // Keep parity with copyResultPassword behavior: ignore copy errors.
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
