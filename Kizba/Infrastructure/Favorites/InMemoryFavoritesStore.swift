#if DEBUG
import Foundation

/// In-memory favorites store used by preview wiring.
actor InMemoryFavoritesStore: FavoritesStoring {

    private var favorites: Set<String>
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    init(initialFavorites: Set<String> = []) {
        self.favorites = initialFavorites
    }

    func isFavorite(_ id: String) async -> Bool {
        favorites.contains(id)
    }

    func addFavorite(_ id: String) async {
        let inserted = favorites.insert(id).inserted
        guard inserted else { return }
        emitChange()
    }

    func removeFavorite(_ id: String) async {
        let removed = favorites.remove(id) != nil
        guard removed else { return }
        emitChange()
    }

    func toggleFavorite(_ id: String) async {
        if favorites.contains(id) {
            _ = favorites.remove(id)
        } else {
            _ = favorites.insert(id)
        }
        emitChange()
    }

    func allFavorites() async -> Set<String> {
        favorites
    }

    nonisolated var favoritesChanged: AsyncStream<Void> {
        AsyncStream { continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.register(id: id, continuation: continuation)
            }
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.unregister(id: id)
                }
            }
        }
    }

    private func emitChange() {
        for continuation in continuations.values {
            continuation.yield(())
        }
    }

    private func register(id: UUID, continuation: AsyncStream<Void>.Continuation) {
        continuations[id] = continuation
    }

    private func unregister(id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
#endif
