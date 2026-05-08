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

    /// Binary discovery / locator service. `nil` in preview / unit-test
    /// wirings that have no real binaries to talk to.
    let discovery: (any BinaryLocating)?

    /// Optional diagnostics invocation log. `nil` in preview / test
    /// wirings that do not publish invocations.
    let invocationLog: InvocationLog?

    /// Lazily-discovered `pass` CLI wrapper. `nil` in preview / unit-
    /// test wirings that have no real binary to talk to. Populated by
    /// ``live()`` once Phase 5.3 wiring is complete.
    let passCLI: LivePassCLI?

    /// Designated initialiser. All collaborators are required so the
    /// composition root is explicit at every call site.
    init(
        passManager: any PassManaging,
        clipboard: any ClipboardServicing,
        settings: any SettingsStoring,
        passCLI: LivePassCLI? = nil,
        discovery: (any BinaryLocating)? = nil,
        invocationLog: InvocationLog? = nil
    ) {
        self.passManager = passManager
        self.clipboard = clipboard
        self.settings = settings
        self.passCLI = passCLI
        self.discovery = discovery
        self.invocationLog = invocationLog
    }
}

// MARK: - Factories

extension AppEnvironment {

    /// Production wiring.
    ///
    /// `live()` constructs the real infrastructure collaborators that
    /// already exist (`ProcessShellRunner`, `BinaryDiscoveryService`,
    /// `LivePassCLI`) and wires them into the environment. The
    /// remaining services that are still scheduled for later phases
    /// (`PassManaging` end-to-end, `ClipboardServicing`,
    /// `SettingsStoring` production stores) keep their existing
    /// behaviour: in DEBUG they fall through to ``preview()``-style
    /// doubles, in RELEASE they are deterministic-failing
    /// placeholders. `passCLI` itself is always populated so
    /// downstream phases can flip the read path entry-by-entry.
    static func live() -> AppEnvironment {
        let invocationLog = InvocationLog()
        let shellRunner = ProcessShellRunner(invocationLog: invocationLog)
        let discovery = BinaryDiscoveryService()
        let passCLI = LivePassCLI(
            discovery: discovery,
            shellRunner: shellRunner
        )

        // Phase 6.5: filesystem-backed listing + lazy `pass show`
        // composed into a single ``PassManaging`` for `live()`. Store
        // root override via ``SettingsStoring`` is wired in Phase 8;
        // for now we use the standard `~/.password-store` location.
        let scanner = PasswordStoreScanner()
        let passManager = LivePassManager(
            scanner: scanner,
            passCLI: passCLI,
            storeRoot: LivePassManager.defaultStoreRoot
        )

        // Phase 7.2: production clipboard wiring. `ClipboardService()`
        // (no-arg) wires the real `SystemPasteboardAdapter` on macOS;
        // outside `canImport(AppKit)` we fall back to the deterministic
        // failing placeholder so the surface still compiles.
        #if canImport(AppKit)
        let clipboard: any ClipboardServicing = ClipboardService()
        #else
        let clipboard: any ClipboardServicing = UnavailableClipboard()
        #endif

        // Use UserDefaults-backed settings store in the live wiring for
        // both DEBUG and RELEASE. The preview wiring below keeps the
        // in-memory store for SwiftUI previews and unit tests.
        return AppEnvironment(
            passManager: passManager,
            clipboard: clipboard,
            settings: UserDefaultsSettingsStore(),
            passCLI: passCLI,
            discovery: discovery,
            invocationLog: invocationLog
        )
    }

    /// Preview / SwiftUI / unit-test wiring.
    ///
    /// `passCLI` is left `nil` here — previews and unit tests must
    /// not reach for the real `pass` binary. In DEBUG builds the
    /// `passManager` is wired to `MockPassManager.preview()` so the
    /// SwiftUI vertical slice and previews can render without
    /// touching `pass`/`gpg`/`pinentry`. In RELEASE builds (where
    /// `MockPassManager` is compiled out) the preview environment
    /// falls back to a placeholder that fails deterministically —
    /// `preview()` itself stays callable so the surface compiles in
    /// both configurations.
    static func preview() -> AppEnvironment {
        #if DEBUG
        return AppEnvironment(
            passManager: MockPassManager.preview(),
            clipboard: NoopClipboard(),
            settings: InMemorySettingsStore(),
            passCLI: nil,
            discovery: nil,
            invocationLog: nil
        )
        #else
        return AppEnvironment(
            passManager: UnavailablePassManager(),
            clipboard: UnavailableClipboard(),
            settings: UnavailableSettingsStore(),
            passCLI: nil,
            discovery: nil
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
    func removeValue(forKey key: String) {}
    func resetAll() {}
    func registerDefaults(_ defaults: [String : Any]) {}
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

#endif

// MARK: - DEBUG nested test doubles

#if DEBUG
extension AppEnvironment {
    /// In-memory `SettingsStoring` for previews and unit tests.
    /// Phase 8 introduces the real `UserDefaultsSettingsStore`.
    final class InMemorySettingsStore: SettingsStoring, @unchecked Sendable {
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

        func removeValue(forKey key: String) {
            lock.lock(); defer { lock.unlock() }
            storage.removeValue(forKey: key)
        }

        func resetAll() {
            lock.lock(); defer { lock.unlock() }
            storage.removeAll()
        }

        func registerDefaults(_ defaults: [String : Any]) {
            // Convert only known types from defaults into storage if absent.
            lock.lock(); defer { lock.unlock() }
            for (k, v) in defaults {
                if storage[k] == nil {
                    if let s = v as? String { storage[k] = s }
                    else if let i = v as? Int { storage[k] = i }
                    else if let d = v as? Double { storage[k] = d }
                    else if let b = v as? Bool { storage[k] = b }
                    else if let s = v as? NSString, let str = s as String? { storage[k] = str }
                }
            }
        }
    }
}
#endif
