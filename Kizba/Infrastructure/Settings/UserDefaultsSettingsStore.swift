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
import os

/// Production implementation of `SettingsStoring` backed by
/// `UserDefaults`.
///
/// Threading: declared `nonisolated` so live-override providers wired
/// into actor-isolated services (e.g. `BinaryDiscoveryService`,
/// `LivePassManager`) can sample settings without an actor hop. The
/// underlying `UserDefaults` is documented as safe for concurrent
/// access.
public final class UserDefaultsSettingsStore: SettingsStoring, @unchecked Sendable {

    // `nonisolated(unsafe)` because `UserDefaults` is not Sendable in
    // the SDK headers but is documented as thread-safe. We confine all
    // access to thread-safe methods.
    nonisolated(unsafe) private let userDefaults: UserDefaults
    nonisolated private let namespacePrefix = "app.kizba.settings."

    /// Inject a `UserDefaults` for testability. Tests should pass
    /// `UserDefaults(suiteName:)` and clean up with
    /// `removePersistentDomain(forName:)`.
    public nonisolated init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        // Ensure sensible default for clipboard clear delay when nothing
        // has been registered by the caller. The literal lives in
        // ``SettingsKeys`` so ``SettingsModel`` and ``EntryDetailModel``
        // share the same source of truth.
        let key = namespaced(SettingsKeys.clipboardClearDelaySeconds)
        if userDefaults.object(forKey: key) == nil {
            userDefaults.register(defaults: [key: SettingsKeys.defaultClipboardClearDelaySeconds])
        }
        // Ensure default for Touch ID per-reveal setting is false when
        // the key has not been set yet.
        let touchKey = namespaced(SettingsKeys.touchIDPerRevealEnabled)
        if userDefaults.object(forKey: touchKey) == nil {
            userDefaults.register(defaults: [touchKey: false])
        }
        // Ensure default for git operation timeout.
        let gitTimeoutKey = namespaced(SettingsKeys.gitOperationTimeoutSeconds)
        if userDefaults.object(forKey: gitTimeoutKey) == nil {
            userDefaults.register(defaults: [gitTimeoutKey: SettingsKeys.defaultGitOperationTimeoutSeconds])
        }
    }

    // MARK: - Namespacing helper

    private nonisolated func namespaced(_ key: String) -> String {
        return namespacePrefix + key
    }

    // MARK: - SettingsStoring

    /// Read the stored value for `key`, or `nil` if unset.
    public nonisolated func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? {
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
    public nonisolated func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {
        let nsKey = namespaced(key.name)

        guard let v = value else {
            userDefaults.removeObject(forKey: nsKey)
            return
        }

        // Phase A.3: replace force-casts with safe `as?` patterns. The
        // protocol's generic constraint already restricts `Value` to the
        // allow-list, so a mismatch here is genuinely a programmer error
        // — assert in DEBUG, degrade gracefully (drop the write) in
        // release rather than crashing the host process.
        switch Value.self {
        case is String.Type:
            guard let typed = v as? String else {
                assertionFailure("Settings type mismatch for key \(key.name): expected String, got \(type(of: v))")
                Log.settings.error("Settings write skipped: type mismatch for key \(key.name, privacy: .public)")
                return
            }
            userDefaults.set(typed, forKey: nsKey)
        case is URL.Type:
            // Persist URL as absoluteString to avoid platform-specific
            // storage semantics. Do not log the value.
            guard let url = v as? URL else {
                assertionFailure("Settings type mismatch for key \(key.name): expected URL, got \(type(of: v))")
                Log.settings.error("Settings write skipped: type mismatch for key \(key.name, privacy: .public)")
                return
            }
            userDefaults.set(url.absoluteString, forKey: nsKey)
        case is Int.Type:
            guard let typed = v as? Int else {
                assertionFailure("Settings type mismatch for key \(key.name): expected Int, got \(type(of: v))")
                Log.settings.error("Settings write skipped: type mismatch for key \(key.name, privacy: .public)")
                return
            }
            userDefaults.set(typed, forKey: nsKey)
        case is Double.Type:
            guard let typed = v as? Double else {
                assertionFailure("Settings type mismatch for key \(key.name): expected Double, got \(type(of: v))")
                Log.settings.error("Settings write skipped: type mismatch for key \(key.name, privacy: .public)")
                return
            }
            userDefaults.set(typed, forKey: nsKey)
        case is Bool.Type:
            guard let typed = v as? Bool else {
                assertionFailure("Settings type mismatch for key \(key.name): expected Bool, got \(type(of: v))")
                Log.settings.error("Settings write skipped: type mismatch for key \(key.name, privacy: .public)")
                return
            }
            userDefaults.set(typed, forKey: nsKey)
        default:
            // Drop unsupported types silently — preserves the allow-list.
            break
        }
    }

    // MARK: - Additional convenience API

    /// Register a dictionary of defaults. Keys are treated as bare names
    /// (without the `app.kizba.settings.` prefix) and are namespaced by
    /// this store before being forwarded to `UserDefaults.register`.
    public nonisolated func registerDefaults(_ defaults: [String: Any]) {
        var mapped: [String: Any] = [:]
        for (k, v) in defaults {
            mapped[namespaced(k)] = v
        }
        userDefaults.register(defaults: mapped)
    }

    /// Remove a value for a typed `SettingsKey`.
    public nonisolated func remove<Value: SettingsValue>(for key: SettingsKey<Value>) {
        userDefaults.removeObject(forKey: namespaced(key.name))
    }

    /// Remove a value by raw (bare) key name — useful for callers that
    /// keep string keys.
    public nonisolated func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: namespaced(key))
    }

    /// Reset (remove) all keys stored under this store's namespace.
    /// This method only touches keys that begin with
    /// `app.kizba.settings.` and leaves other suites untouched.
    public nonisolated func resetAll() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for k in keys where k.hasPrefix(namespacePrefix) {
            userDefaults.removeObject(forKey: k)
        }
    }
}
