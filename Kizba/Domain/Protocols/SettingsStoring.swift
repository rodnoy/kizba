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

    /// `nonisolated` so live override providers (closures captured
    /// inside actor-isolated services like `BinaryDiscoveryService`
    /// and `LivePassManager`) can construct keys without hopping to
    /// the main actor under the project's `default-isolation=MainActor`
    /// setting.
    public nonisolated init(_ name: String) {
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
    ///
    /// `nonisolated` so live override providers running inside
    /// actor-isolated services (e.g. `BinaryDiscoveryService`,
    /// `LivePassManager`) can sample settings without an actor hop.
    /// Conformers must back this with thread-safe storage —
    /// `UserDefaults` qualifies.
    nonisolated func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value?

    /// Write `value` for `key`, or remove the entry when `value` is
    /// `nil`.
    nonisolated func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>)

    /// Remove the entry for the given bare key name.
    nonisolated func removeValue(forKey key: String)

    /// Remove all keys belonging to the store's namespace.
    nonisolated func resetAll()

    /// Register default values for bare key names. Keys provided here
    /// should be the un-prefixed names (e.g. `clipboardClearDelaySeconds`).
    nonisolated func registerDefaults(_ defaults: [String: Any])
}

// NOTE: Phase A.3 deliberately removes the previous protocol-extension
// no-op defaults for `removeValue(forKey:)`, `resetAll()` and
// `registerDefaults(_:)`. Silently no-oping mutating operations is a
// footgun for write features that depend on settings actually being
// writable; every conformer must now implement them explicitly.

/// Well-known persisted settings key constants.
///
/// These are the single source of truth for keys used by the
/// settings store. Keys are fully namespaced to avoid collisions in
/// shared `UserDefaults` suites.
public enum SettingsKeys {
    // Bare key names (the store will namespace them for storage).
    // Declared `nonisolated` so they remain reachable from the live
    // override providers wired into actor-isolated services.
    public nonisolated static let storePathOverride = "storePathOverride"
    public nonisolated static let passBinaryOverride = "passBinaryOverride"
    public nonisolated static let gpgBinaryOverride = "gpgBinaryOverride"
    public nonisolated static let pinentryBinaryOverride = "pinentryBinaryOverride"
    public nonisolated static let clipboardClearDelaySeconds = "clipboardClearDelaySeconds"
    /// When true, require biometric authentication (Touch ID / Face ID)
    /// for each password reveal in the detail view.
    public nonisolated static let touchIDPerRevealEnabled = "touchIDPerRevealEnabled"
    /// Timeout in seconds for git operations (pull, push).
    public nonisolated static let gitOperationTimeoutSeconds = "gitOperationTimeoutSeconds"
    public nonisolated static let showInMenuBar = "showInMenuBar"
    /// When true, the sidebar renders the Recents section. When false,
    /// the entire section is elided (MVP6 Phase A).
    public nonisolated static let showRecents = "showRecents"
    /// When true, the sidebar renders the Favorites section. When
    /// false, the entire section is elided (MVP6 Phase G.1). Symmetric
    /// with ``showRecents``.
    public nonisolated static let showFavorites = "showFavorites"
    /// Soft cap on the number of recently-viewed entries surfaced in
    /// the sidebar Recents section. Persisted user preference; clamped
    /// to ``recentsLimitBounds`` on write.
    public nonisolated static let recentsLimit = "recentsLimit"

    // MARK: - Defaults & sane bounds
    //
    // Single source of truth for the clipboard clear-delay default and
    // the accepted range. Phase A.6: every consumer
    // (`UserDefaultsSettingsStore` register-defaults, `SettingsModel`
    // initial value / reset, `EntryDetailModel` per-copy read) must
    // reference these constants instead of duplicating literals.

    /// Default clipboard auto-clear delay applied when no explicit
    /// value is persisted. Matches the original MVP-1 hardcoded value.
    public nonisolated static let defaultClipboardClearDelaySeconds: Int = 30

    /// Inclusive bounds enforced by the Settings UI stepper and at
    /// read time inside ``EntryDetailModel`` so an out-of-range
    /// persisted value cannot produce a useless 0-second delay or a
    /// runaway multi-hour delay.
    public nonisolated static let clipboardClearDelayBounds: ClosedRange<Int> = 5...300

    /// Default git operation timeout applied when no explicit value is persisted.
    public nonisolated static let defaultGitOperationTimeoutSeconds: Int = 60
    public nonisolated static let defaultShowInMenuBar: Bool = true

    /// Inclusive bounds enforced by the Settings UI stepper and at
    /// read time inside ``GitStatusModel``.
    public nonisolated static let gitOperationTimeoutBounds: ClosedRange<Int> = 10...300

    /// Default for ``showRecents``: section is visible until the user
    /// explicitly hides it.
    public nonisolated static let defaultShowRecents: Bool = true

    /// Default for ``showFavorites``: section is visible until the user
    /// explicitly hides it. Mirrors ``defaultShowRecents`` (MVP6 G.1).
    public nonisolated static let defaultShowFavorites: Bool = true

    /// Default Recents cap. Replaces the previously-hardcoded `20`
    /// literal in the production and DEBUG stores (MVP6 Phase A).
    public nonisolated static let defaultRecentsLimit: Int = 7

    /// Inclusive bounds enforced by the Settings UI stepper and at
    /// write time inside ``UserDefaultsSettingsStore`` so an
    /// out-of-range value cannot reach the Recents store.
    public nonisolated static let recentsLimitBounds: ClosedRange<Int> = 3...7

    /// Convenience lower bound — equivalent to
    /// ``recentsLimitBounds.lowerBound`` but exposed as a top-level
    /// constant for test readability.
    public nonisolated static let minRecentsLimit: Int = 3

    /// Convenience upper bound — equivalent to
    /// ``recentsLimitBounds.upperBound``.
    public nonisolated static let maxRecentsLimit: Int = 7
}
