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

    /// Pure password generator used by the New Entry / Move flows to
    /// preview a candidate password before it is committed to the
    /// store. In-place regeneration of an existing entry uses
    /// `pass generate --in-place` instead (see Phase G) and does NOT
    /// route through this collaborator. Always populated — there is
    /// no environment in which generation is unsupported.
    let passwordGenerator: any PasswordGenerating

    /// Search engine used by entry-list filtering (`⌘F` sidebar search)
    /// and command-palette style queries.
    let searchEngine: any EntrySearching
    /// Optional biometric authenticator. Injected in `live()` to the
    /// LA-backed implementation. `nil` in preview/test wirings.
    let biometricAuth: (any BiometricAuthenticating)?

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

    /// Absolute path of the active password store.
    var storeURL: URL {
        passManager.storeLocation()
    }

    /// Designated initialiser. All collaborators are required so the
    /// composition root is explicit at every call site.
    init(
        passManager: any PassManaging,
        clipboard: any ClipboardServicing,
        settings: any SettingsStoring,
        passwordGenerator: any PasswordGenerating,
        searchEngine: any EntrySearching,
        biometricAuth: (any BiometricAuthenticating)? = nil,
        passCLI: LivePassCLI? = nil,
        discovery: (any BinaryLocating)? = nil,
        invocationLog: InvocationLog? = nil
    ) {
        self.passManager = passManager
        self.clipboard = clipboard
        self.settings = settings
        self.passwordGenerator = passwordGenerator
        self.searchEngine = searchEngine
        self.biometricAuth = biometricAuth
        self.passCLI = passCLI
        self.discovery = discovery
        self.invocationLog = invocationLog
    }

    /// Backward-compatible convenience initializer used by existing
    /// test/preview call sites that do not pass a dedicated
    /// `EntrySearching` implementation yet.
    init(
        passManager: any PassManaging,
        clipboard: any ClipboardServicing,
        settings: any SettingsStoring,
        passwordGenerator: any PasswordGenerating,
        biometricAuth: (any BiometricAuthenticating)? = nil,
        passCLI: LivePassCLI? = nil,
        discovery: (any BinaryLocating)? = nil,
        invocationLog: InvocationLog? = nil
    ) {
        self.init(
            passManager: passManager,
            clipboard: clipboard,
            settings: settings,
            passwordGenerator: passwordGenerator,
            searchEngine: LiveSearchEngine(passManager: passManager),
            biometricAuth: biometricAuth,
            passCLI: passCLI,
            discovery: discovery,
            invocationLog: invocationLog
        )
    }
}

// MARK: - Factories

extension AppEnvironment {

    func makeLivePassGitManager(
        passExecutable: URL,
        gitExecutable: URL,
        shellRunner: (any ShellCommandRunning)? = nil
    ) -> LivePassGitManager {
        let runner = shellRunner ?? ProcessShellRunner(invocationLog: invocationLog)
        let passCLI = PassCLI(executable: passExecutable, shellRunner: runner)
        let storeRootProvider = Self.makeStoreRootProvider(settings: settings)

        return LivePassGitManager(
            passCLI: passCLI,
            gitExecutable: gitExecutable,
            storeLocationProvider: {
                storeRootProvider()
            }
        )
    }

    @MainActor
    func wireGitModelIfAvailable(
        into appState: AppState,
        usingShellRunner shellRunner: (any ShellCommandRunning)? = nil
    ) async {
        guard let discovery else { return }
        guard let gitExecutable = await discovery.locate(.git) else { return }
        guard let passExecutable = await discovery.locate(.pass) else { return }

        let gitManager = makeLivePassGitManager(
            passExecutable: passExecutable,
            gitExecutable: gitExecutable,
            shellRunner: shellRunner
        )

        guard let status = try? await gitManager.gitStatus(), status.isGitRepository else {
            return
        }

        let model = GitStatusModel(
            gitManager: gitManager,
            passManager: passManager,
            appState: appState,
            router: appState.router,
            toastCenter: appState.toastCenter,
            settingsStore: settings
        )
        model.status = status
        appState.gitStatusModel = model

        Task {
            await model.observeChanges()
        }
    }

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

        // Use UserDefaults-backed settings store in the live wiring for
        // both DEBUG and RELEASE. The preview wiring below keeps the
        // in-memory store for SwiftUI previews and unit tests.
        let settings: any SettingsStoring = UserDefaultsSettingsStore()

        // Phase A.4: ONE shared `BinaryDiscoveryService` per process,
        // reused by `LivePassCLI` and the Settings UI. The override
        // closure reads the persisted per-binary path overrides on
        // every cache miss, so changes saved through the Settings
        // window take effect on the next `locate(_:)` call (after a
        // `reDetect()`) without rebuilding the service.
        let discovery = BinaryDiscoveryService(
            overrideProvider: Self.makeBinaryOverrideProvider(settings: settings)
        )

        let passCLI = LivePassCLI(
            discovery: discovery,
            shellRunner: shellRunner
        )

        // Phase A.5: filesystem-backed listing + lazy `pass show`
        // composed into a single ``PassManaging`` for `live()`. The
        // store-root provider honours
        // ``SettingsKeys/storePathOverride`` live so edits saved
        // through Settings take effect on the next operation; the
        // scanner and `PASSWORD_STORE_DIR` env exported to `pass`
        // therefore always agree.
        let scanner = PasswordStoreScanner()
        // Phase C.6: wire real FSEvents watcher into live wiring so the
        // LivePassManager can observe external filesystem changes.
        let storeWatcher = FSEventsStoreWatcher()

        let passManager = LivePassManager(
            scanner: scanner,
            passCLI: passCLI,
            storeRootProvider: Self.makeStoreRootProvider(settings: settings),
            storeWatcher: storeWatcher
        )

        let searchEngine: any EntrySearching = LiveSearchEngine(passManager: passManager)

        // Phase 7.2: production clipboard wiring. `ClipboardService()`
        // (no-arg) wires the real `SystemPasteboardAdapter` on macOS;
        // outside `canImport(AppKit)` we fall back to the deterministic
        // failing placeholder so the surface still compiles.
        #if canImport(AppKit)
        let clipboard: any ClipboardServicing = ClipboardService()
        #else
        let clipboard: any ClipboardServicing = UnavailableClipboard()
        #endif

        return AppEnvironment(
            passManager: passManager,
            clipboard: clipboard,
            settings: settings,
            passwordGenerator: LivePasswordGenerator(),
            searchEngine: searchEngine,
            biometricAuth: LocalAuthBiometricAuthenticator(),
            passCLI: passCLI,
            discovery: discovery,
            invocationLog: invocationLog
        )
    }

    // MARK: - Live providers

    /// Build the closure used by the shared ``BinaryDiscoveryService``
    /// to resolve per-binary path overrides on demand. Reads bare
    /// settings keys for `pass`, `gpg` and `pinentry-mac` and converts
    /// non-empty filesystem paths into `URL` values. Empty strings and
    /// missing entries are dropped — the discovery service then falls
    /// back to its well-known and PATH searches for that binary.
    static func makeBinaryOverrideProvider(
        settings: any SettingsStoring
    ) -> @Sendable () -> [BinaryName: URL] {
        return { [settings] in
            var out: [BinaryName: URL] = [:]
            if let p = settings.value(for: SettingsKey<String>(SettingsKeys.passBinaryOverride)),
               !p.isEmpty {
                out[.pass] = URL(fileURLWithPath: p)
            }
            if let p = settings.value(for: SettingsKey<String>(SettingsKeys.gpgBinaryOverride)),
               !p.isEmpty {
                out[.gpg] = URL(fileURLWithPath: p)
            }
            if let p = settings.value(for: SettingsKey<String>(SettingsKeys.pinentryBinaryOverride)),
               !p.isEmpty {
                out[.pinentryMac] = URL(fileURLWithPath: p)
            }
            return out
        }
    }

    /// Build the closure used by ``LivePassManager`` to source the
    /// active password-store root. Returns the user override when
    /// configured, falling back to ``LivePassManager/defaultStoreRoot``
    /// (`~/.password-store`).
    static func makeStoreRootProvider(
        settings: any SettingsStoring
    ) -> @Sendable () -> URL {
        return { [settings] in
            if let raw = settings.value(for: SettingsKey<String>(SettingsKeys.storePathOverride)),
               !raw.isEmpty {
                return URL(fileURLWithPath: raw, isDirectory: true)
            }
            return LivePassManager.defaultStoreRoot
        }
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
        let searchEngine: any EntrySearching = LiveSearchEngine(passManager: MockPassManager.preview())
        return AppEnvironment(
            passManager: MockPassManager.preview(),
            clipboard: NoopClipboard(),
            settings: InMemorySettingsStore(),
            passwordGenerator: LivePasswordGenerator(),
            searchEngine: searchEngine,
            passCLI: nil,
            discovery: nil,
            invocationLog: nil
        )
        #else
        return AppEnvironment(
            passManager: UnavailablePassManager(),
            clipboard: UnavailableClipboard(),
            settings: UnavailableSettingsStore(),
            passwordGenerator: LivePasswordGenerator(),
            searchEngine: UnavailableSearchEngine(),
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

    // Phase E.5 write surface — placeholder fatals mirror the read
    // methods above; release-config preview wirings never invoke them.
    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        fatalError("AppEnvironment: PassManaging not yet wired in this build configuration.")
    }
    func generate(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool,
        force: Bool
    ) async throws -> PassSecret {
        fatalError("AppEnvironment: PassManaging not yet wired in this build configuration.")
    }
    func generateInPlace(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool
    ) async throws -> PassSecret {
        fatalError("AppEnvironment: PassManaging not yet wired in this build configuration.")
    }
    func remove(_ entry: PassEntry) async throws {
        fatalError("AppEnvironment: PassManaging not yet wired in this build configuration.")
    }
    func move(from: PassEntry, to newPath: String, force: Bool) async throws -> PassEntry {
        fatalError("AppEnvironment: PassManaging not yet wired in this build configuration.")
    }

    /// Empty stream that never emits — release-config preview wirings
    /// don't emit store changes (no real store is wired).
    var changes: AsyncStream<StoreChange> {
        AsyncStream { _ in }
    }
}

private struct UnavailableClipboard: ClipboardServicing {
    func copy(_ value: String, clearAfter: Duration) async {
        fatalError("AppEnvironment: ClipboardServicing not yet wired in this build configuration.")
    }
}

private struct UnavailableSettingsStore: SettingsStoring {
    nonisolated func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? { nil }
    nonisolated func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {}
    nonisolated func removeValue(forKey key: String) {}
    nonisolated func resetAll() {}
    nonisolated func registerDefaults(_ defaults: [String : Any]) {}
}

private struct UnavailableSearchEngine: EntrySearching {
    func search(_ query: String) async throws -> [SearchResult] {
        fatalError("AppEnvironment: EntrySearching is unavailable in this build configuration.")
    }
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
        // `nonisolated(unsafe)` for `storage` — access is serialised
        // by `lock`. `NSLock` is already Sendable.
        nonisolated private let lock = NSLock()
        nonisolated(unsafe) private var storage: [String: any SettingsValue] = [:]

        nonisolated init() {}

        nonisolated func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? {
            lock.lock(); defer { lock.unlock() }
            return storage[key.name] as? Value
        }

        nonisolated func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {
            lock.lock(); defer { lock.unlock() }
            if let value {
                storage[key.name] = value
            } else {
                storage.removeValue(forKey: key.name)
            }
        }

        nonisolated func removeValue(forKey key: String) {
            lock.lock(); defer { lock.unlock() }
            storage.removeValue(forKey: key)
        }

        nonisolated func resetAll() {
            lock.lock(); defer { lock.unlock() }
            storage.removeAll()
        }

        nonisolated func registerDefaults(_ defaults: [String : Any]) {
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
