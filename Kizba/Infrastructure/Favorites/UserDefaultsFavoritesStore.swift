import Foundation

/// UserDefaults-backed favorites store for entry ids.
public actor UserDefaultsFavoritesStore: FavoritesStoring {

    private enum Keys {
        static let favorites = "kizba.favorites"
    }

    nonisolated(unsafe) private let userDefaults: UserDefaults
    private var favorites: Set<String>
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let stored = userDefaults.array(forKey: Keys.favorites) as? [String] {
            self.favorites = Set(stored)
        } else {
            self.favorites = []
        }
    }

    public func isFavorite(_ id: String) async -> Bool {
        favorites.contains(id)
    }

    public func addFavorite(_ id: String) async {
        let inserted = favorites.insert(id).inserted
        guard inserted else { return }
        persistFavorites()
        emitChange()
    }

    public func removeFavorite(_ id: String) async {
        let removed = favorites.remove(id) != nil
        guard removed else { return }
        persistFavorites()
        emitChange()
    }

    public func toggleFavorite(_ id: String) async {
        if favorites.contains(id) {
            _ = favorites.remove(id)
        } else {
            _ = favorites.insert(id)
        }
        persistFavorites()
        emitChange()
    }

    public func allFavorites() async -> Set<String> {
        favorites
    }

    public nonisolated var favoritesChanged: AsyncStream<Void> {
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

    private func persistFavorites() {
        userDefaults.set(Array(favorites), forKey: Keys.favorites)
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
