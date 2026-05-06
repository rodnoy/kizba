//
//  AppEnvironment.swift
//  Kizba
//
//  Composition root holding the domain protocol implementations the
//  rest of the app depends on. Constructed once at process start
//  (`live()`) or per-preview (`preview()`), then injected via
//  initializers — never via `EnvironmentObject` for domain services
//  (see `.ai/decisions.md`).
//

import Foundation

/// Manual DI container for Kizba's domain services.
///
/// Per `.ai/decisions.md`, dependency injection is performed manually
/// through initializers; no third-party DI framework is used.
///
/// This struct is `Sendable` so it can be passed across actor
/// boundaries (e.g. into `@MainActor` view models or background
/// tasks).
struct AppEnvironment: Sendable {

    /// Read-only access to the `pass` password store.
    let passManager: any PassManaging

    /// Pasteboard service with token-checked auto-clear.
    let clipboard: any ClipboardServicing

    /// Persistent user preferences.
    let settings: any SettingsStoring

    /// Designated initialiser. All collaborators are required so the
    /// composition root is explicit at every call site.
    init(
        passManager: any PassManaging,
        clipboard: any ClipboardServicing,
        settings: any SettingsStoring
    ) {
        self.passManager = passManager
        self.clipboard = clipboard
        self.settings = settings
    }
}

// MARK: - Factories

extension AppEnvironment {

    /// Production wiring.
    ///
    /// TODO(phase-4..8): replace the placeholder collaborators with the
    /// real `PassCLI`, `ClipboardService`, and `UserDefaultsSettingsStore`
    /// implementations as those phases land. Until then, `live()` falls
    /// back to ``preview()`` in DEBUG builds and to a deterministic
    /// failing placeholder in RELEASE builds so the app still links.
    static func live() -> AppEnvironment {
        #if DEBUG
        return preview()
        #else
        return AppEnvironment(
            passManager: UnavailablePassManager(),
            clipboard: UnavailableClipboard(),
            settings: UnavailableSettingsStore()
        )
        #endif
    }

    /// Preview / SwiftUI / unit-test wiring.
    ///
    /// In DEBUG builds the `passManager` is wired to
    /// `MockPassManager.preview()` so the SwiftUI vertical slice and
    /// previews can render without touching `pass`/`gpg`/`pinentry`.
    /// In RELEASE builds (where `MockPassManager` is compiled out) the
    /// preview environment falls back to a placeholder that fails
    /// deterministically — `preview()` itself stays callable so the
    /// surface compiles in both configurations.
    static func preview() -> AppEnvironment {
        #if DEBUG
        return AppEnvironment(
            passManager: MockPassManager.preview(),
            clipboard: NoopClipboard(),
            settings: InMemorySettingsStore()
        )
        #else
        return AppEnvironment(
            passManager: UnavailablePassManager(),
            clipboard: UnavailableClipboard(),
            settings: UnavailableSettingsStore()
        )
        #endif
    }
}

// MARK: - Release placeholders
//
// These compile in every configuration. They exist solely to keep
// `AppEnvironment.live()` / `.preview()` callable in RELEASE while the
// real `Infrastructure/` implementations are still being written. They
// fail deterministically rather than silently — any production wiring
// gap surfaces immediately.

private struct UnavailablePassManager: PassManaging {
    func listEntries() async throws -> [PassEntry] {
        fatalError("AppEnvironment: PassManaging not yet wired in this build configuration.")
    }
    func show(_ entry: PassEntry) async throws -> PassSecret {
        fatalError("AppEnvironment: PassManaging not yet wired in this build configuration.")
    }
    func storeLocation() -> URL {
        URL(fileURLWithPath: "/var/empty")
    }
}

private struct UnavailableClipboard: ClipboardServicing {
    func copy(_ value: String, clearAfter: Duration) async {
        fatalError("AppEnvironment: ClipboardServicing not yet wired in this build configuration.")
    }
}

private struct UnavailableSettingsStore: SettingsStoring {
    func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? { nil }
    func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {}
}

// MARK: - Lightweight DEBUG fakes
//
// Tiny, self-contained doubles used by `AppEnvironment.preview()` so
// the preview environment is fully populated without pulling in the
// production `Infrastructure/Clipboard/` and `Infrastructure/Settings/`
// modules (which are scheduled for later phases).

#if DEBUG

/// Drops every `copy` call on the floor. Phase 5 introduces a proper
/// `FakeClipboard` for clipboard auto-clear tests.
private struct NoopClipboard: ClipboardServicing {
    func copy(_ value: String, clearAfter: Duration) async {}
}

/// In-memory `SettingsStoring` for previews. Phase 8 introduces the
/// real `UserDefaultsSettingsStore`.
private final class InMemorySettingsStore: SettingsStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: any SettingsValue] = [:]

    func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? {
        lock.lock(); defer { lock.unlock() }
        return storage[key.name] as? Value
    }

    func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {
        lock.lock(); defer { lock.unlock() }
        if let value {
            storage[key.name] = value
        } else {
            storage.removeValue(forKey: key.name)
        }
    }
}

#endif
