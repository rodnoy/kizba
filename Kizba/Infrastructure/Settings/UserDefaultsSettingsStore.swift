//
//  UserDefaultsSettingsStore.swift
//  Kizba
//
//  Concurrency-safe, testable UserDefaults-backed settings store.
//  Keys are namespaced to avoid collisions. Only a small allow-list
//  of value types are persisted: String, URL (stored as absoluteString),
//  Int, Double and Bool.
//
import Foundation

/// Production implementation of `SettingsStoring` backed by
/// `UserDefaults`.
///
/// Threading: marked `@MainActor` to align with the project's
/// default actor isolation. The underlying `UserDefaults` is safe for
/// concurrent access from multiple threads.
public final class UserDefaultsSettingsStore: SettingsStoring {

    private let userDefaults: UserDefaults
    private let namespacePrefix = "app.kizba.settings."

    /// Inject a `UserDefaults` for testability. Tests should pass
    /// `UserDefaults(suiteName:)` and clean up with
    /// `removePersistentDomain(forName:)`.
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        // Ensure sensible default for clipboard clear delay when nothing
        // has been registered by the caller.
        if userDefaults.object(forKey: namespaced("clipboardClearDelaySeconds")) == nil {
            userDefaults.register(defaults: [namespaced("clipboardClearDelaySeconds"): 30])
        }
    }

    // MARK: - Namespacing helper

    private func namespaced(_ key: String) -> String {
        return namespacePrefix + key
    }

    // MARK: - SettingsStoring

    /// Read the stored value for `key`, or `nil` if unset.
    public func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? {
        let nsKey = namespaced(key.name)

        switch Value.self {
        case is String.Type:
            return userDefaults.string(forKey: nsKey) as? Value
        case is URL.Type:
            if let s = userDefaults.string(forKey: nsKey) {
                return URL(string: s) as? Value
            }
            return nil
        case is Int.Type:
            return userDefaults.object(forKey: nsKey) as? Value
        case is Double.Type:
            return userDefaults.object(forKey: nsKey) as? Value
        case is Bool.Type:
            // `bool(forKey:)` returns false when absent, so detect absence
            // via `object(forKey:)`.
            guard userDefaults.object(forKey: nsKey) != nil else { return nil }
            return userDefaults.bool(forKey: nsKey) as? Value
        default:
            // Unknown/unsupported type — do not attempt to decode.
            return nil
        }
    }

    /// Write `value` for `key`, or remove the entry when `value` is
    /// `nil`.
    public func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {
        let nsKey = namespaced(key.name)

        guard let v = value else {
            userDefaults.removeObject(forKey: nsKey)
            return
        }

        switch Value.self {
        case is String.Type:
            userDefaults.set(v as! String, forKey: nsKey)
        case is URL.Type:
            // Persist URL as absoluteString to avoid platform-specific
            // storage semantics. Do not log the value.
            let url = v as! URL
            userDefaults.set(url.absoluteString, forKey: nsKey)
        case is Int.Type:
            userDefaults.set(v as! Int, forKey: nsKey)
        case is Double.Type:
            userDefaults.set(v as! Double, forKey: nsKey)
        case is Bool.Type:
            userDefaults.set(v as! Bool, forKey: nsKey)
        default:
            // Drop unsupported types silently — preserves the allow-list.
            break
        }
    }

    // MARK: - Additional convenience API

    /// Register a dictionary of defaults. Keys are treated as bare names
    /// (without the `app.kizba.settings.` prefix) and are namespaced by
    /// this store before being forwarded to `UserDefaults.register`.
    public func registerDefaults(_ defaults: [String: Any]) {
        var mapped: [String: Any] = [:]
        for (k, v) in defaults {
            mapped[namespaced(k)] = v
        }
        userDefaults.register(defaults: mapped)
    }

    /// Remove a value for a typed `SettingsKey`.
    public func remove<Value: SettingsValue>(for key: SettingsKey<Value>) {
        userDefaults.removeObject(forKey: namespaced(key.name))
    }

    /// Remove a value by raw (bare) key name — useful for callers that
    /// keep string keys.
    public func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: namespaced(key))
    }

    /// Reset (remove) all keys stored under this store's namespace.
    /// This method only touches keys that begin with
    /// `app.kizba.settings.` and leaves other suites untouched.
    public func resetAll() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for k in keys where k.hasPrefix(namespacePrefix) {
            userDefaults.removeObject(forKey: k)
        }
    }
}
