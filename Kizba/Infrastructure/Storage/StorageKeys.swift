import Foundation

/// Namespaced `UserDefaults` keys for persistent stores (Recents, Favorites, etc.).
/// Separate from `SettingsKeys` to keep persistence keys distinct from user preferences.
/// Suffix `.v1` reserves room for future schema bumps without another rename.
///
/// Declared `nonisolated` so they remain reachable from actor-isolated stores
/// (matching the convention used by `SettingsKeys`).
public enum StorageKeys {
    public nonisolated static let recentsEntriesV1 = "app.kizba.recents.entries.v1"
    public nonisolated static let favoritesEntriesV1 = "app.kizba.favorites.entries.v1"

    // Legacy keys retained for one-shot migration only — do not write.
    public nonisolated static let legacyRecentsEntries = "kizba.recentEntries"
    public nonisolated static let legacyFavoritesEntries = "kizba.favorites"
}
