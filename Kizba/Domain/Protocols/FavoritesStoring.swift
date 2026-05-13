import Foundation

/// Asynchronous favorite-entry storage and change notifications.
public protocol FavoritesStoring: Sendable {
    /// Returns `true` when the id is favorited.
    func isFavorite(_ id: String) async -> Bool

    /// Adds the id to favorites.
    func addFavorite(_ id: String) async

    /// Removes the id from favorites.
    func removeFavorite(_ id: String) async

    /// Toggles favorite status for the id.
    func toggleFavorite(_ id: String) async

    /// Returns all favorite ids.
    func allFavorites() async -> Set<String>

    /// Emits after every favorites mutation.
    var favoritesChanged: AsyncStream<Void> { get }
}
