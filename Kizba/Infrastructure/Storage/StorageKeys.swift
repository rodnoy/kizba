import Foundation

/// Namespaced `UserDefaults` keys for persistent stores (Recents, Favorites, etc.).
/// Separate from `SettingsKeys` to keep persistence keys distinct from user preferences.
/// Versioned suffix (`.v1`, `.v2`, …) lets us discard polluted schema generations
/// without renaming the logical key.
///
/// Declared `nonisolated` so they remain reachable from actor-isolated stores
/// (matching the convention used by `SettingsKeys`).
public enum StorageKeys {
    // MVP6.H.1: Recents bumped v1 → v2 to discard fixture pollution from DEBUG builds
    // that pre-G.3 wrote `MockPassManager` paths directly under the `.v1` key.
    // DEBUG and Release share `UserDefaults.standard` via the bundle id, so any value
    // ever written by a DEBUG build under `.v1` would otherwise persist into Release.
    public nonisolated static let recentsEntriesV2 = "app.kizba.recents.entries.v2"
    public nonisolated static let favoritesEntriesV1 = "app.kizba.favorites.entries.v1"

    // Legacy keys retained for one-shot cleanup only — never written.
    public nonisolated static let legacyRecentsEntries = "kizba.recentEntries"
    public nonisolated static let legacyRecentsEntriesV1 = "app.kizba.recents.entries.v1"
    public nonisolated static let legacyFavoritesEntries = "kizba.favorites"
}
