//
//  SettingsStoring.swift
//  Kizba
//
//  Domain abstraction over persistent user preferences. Production
//  implementation is `UserDefaultsSettingsStore` (Phase 8); tests use
//  an in-memory fake.
//

import Foundation

/// Whitelisted value types acceptable to ``SettingsStoring``.
///
/// Per `.ai/decisions.md`, the persistence layer enforces an
/// allow-list (`String`, `URL`, `Int`, `Double`, `Bool`) to prevent
/// accidental serialisation of arbitrary `Codable` types — and most
/// importantly, of anything containing a ``PassSecret``.
public protocol SettingsValue: Sendable {}

extension String: SettingsValue {}
extension URL: SettingsValue {}
extension Int: SettingsValue {}
extension Double: SettingsValue {}
extension Bool: SettingsValue {}

/// Type-safe key for a settings entry.
///
/// The `name` is namespaced (e.g. `"app.kizba.settings.storePathOverride"`)
/// by the implementation to avoid collisions with other domains in
/// the shared `UserDefaults` suite.
public struct SettingsKey<Value: SettingsValue>: Sendable, Hashable {

    /// Bare key name; the store prepends the `app.kizba.settings.`
    /// namespace.
    public let name: String

    public init(_ name: String) {
        self.name = name
    }
}

/// Persistent key-value store for user preferences.
///
/// ## Threading contract
///
/// `Sendable`. Reads and writes are synchronous and safe from any
/// actor; the underlying `UserDefaults` is itself thread-safe. UI
/// callers typically observe via `@Observable` view models that
/// re-read on demand.
public protocol SettingsStoring: Sendable {

    /// Read the stored value for `key`, or `nil` if unset.
    func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value?

    /// Write `value` for `key`, or remove the entry when `value` is
    /// `nil`.
    func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>)

    /// Remove the entry for the given bare key name.
    func removeValue(forKey key: String)

    /// Remove all keys belonging to the store's namespace.
    func resetAll()

    /// Register default values for bare key names. Keys provided here
    /// should be the un-prefixed names (e.g. `clipboardClearDelaySeconds`).
func registerDefaults(_ defaults: [String: Any])
}

// Backwards-compatible no-op defaults so lightweight test doubles
// don't have to implement the entire surface unless needed.
extension SettingsStoring {
    public func removeValue(forKey key: String) {}
    public func resetAll() {}
    public func registerDefaults(_ defaults: [String: Any]) {}
}
