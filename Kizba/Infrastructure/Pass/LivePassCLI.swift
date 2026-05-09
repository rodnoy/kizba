//
//  LivePassCLI.swift
//  Kizba
//
//  Phase 5.3 wiring helper. Wraps a ``PassCLI`` so the absolute path
//  of the `pass` binary can be resolved lazily through
//  ``BinaryLocating`` at the first ``show(entryPath:timeout:)`` call,
//  rather than synchronously at composition-root construction time
//  (which would force `AppEnvironment.live()` to be `async`).
//
//  ## Threading contract
//
//  `actor`. The cached ``PassCLI`` instance is internal actor state.
//  `Sendable` is satisfied trivially via the actor model.
//
//  ## Discovery semantics
//
//  - On first invocation, ``locate`` is asked for ``BinaryName/pass``.
//  - A `nil` result raises ``PassError/binaryNotFound`` so the UI can
//    surface the Settings nudge per the architecture mapping.
//  - The resolved ``PassCLI`` is cached for subsequent calls. Use
//    ``invalidate()`` after the user changes the override path or
//    triggers a "Re-detect binaries" action so the next call re-walks
//    discovery.
//
//  ## Logging
//
//  No additional `os.Logger` calls are emitted here — `PassCLI` and
//  `BinaryDiscoveryService` already log shape-only metadata; doubling
//  it up at this layer would only add noise.
//

import Foundation

/// Production wrapper around ``PassCLI`` that lazily resolves the
/// `pass` executable through ``BinaryLocating``.
public actor LivePassCLI {

    /// Discovery service used to resolve ``BinaryName/pass``.
    public let discovery: any BinaryLocating

    /// Process spawner forwarded to the underlying ``PassCLI``.
    private let shellRunner: any ShellCommandRunning

    /// Optional `PASSWORD_STORE_DIR` override forwarded to ``PassCLI``.
    private let passwordStoreDir: URL?

    /// Optional `GNUPGHOME` override forwarded to ``PassCLI``.
    private let gnupgHome: URL?

    /// Optional `PATH` override forwarded to ``PassCLI``.
    private let pathOverride: String?

    /// Optional `HOME` override forwarded to ``PassCLI``.
    private let homeOverride: String?

    /// Cached `PassCLI` once discovery has succeeded.
    private var resolved: PassCLI?

    /// Designated initialiser.
    public init(
        discovery: any BinaryLocating,
        shellRunner: any ShellCommandRunning,
        passwordStoreDir: URL? = nil,
        gnupgHome: URL? = nil,
        pathOverride: String? = nil,
        homeOverride: String? = nil
    ) {
        self.discovery = discovery
        self.shellRunner = shellRunner
        self.passwordStoreDir = passwordStoreDir
        self.gnupgHome = gnupgHome
        self.pathOverride = pathOverride
        self.homeOverride = homeOverride
    }

    /// Run `pass show <entryPath>` against the lazily-resolved binary.
    ///
    /// - Parameters:
    ///   - entryPath: pass entry path forwarded as the second `argv`
    ///     element (`pass show <entry>`).
    ///   - timeout: wall-clock timeout. Defaults to
    ///     ``kizbaPassShowDefaultTimeout``.
    ///   - passwordStoreDirOverride: per-call override for
    ///     `PASSWORD_STORE_DIR`. When non-`nil`, takes precedence over
    ///     the value supplied at construction time. Lets ``LivePassManager``
    ///     keep the env in sync with its live store-root provider.
    /// - Throws: ``PassError/binaryNotFound`` if discovery returns
    ///   `nil`; otherwise any error surfaced by ``PassCLI/show(entryPath:timeout:)``.
    public func show(
        entryPath: String,
        timeout: Duration = kizbaPassShowDefaultTimeout,
        passwordStoreDirOverride: URL? = nil
    ) async throws -> PassShowResult {
        let cli = try await resolveCLI(passwordStoreDirOverride: passwordStoreDirOverride)
        return try await cli.show(entryPath: entryPath, timeout: timeout)
    }

    /// Drop the cached ``PassCLI`` so the next call re-runs discovery.
    /// Hook for the Settings "Re-detect binaries" action (Phase 8).
    public func invalidate() {
        resolved = nil
    }

    // MARK: - Write surface (Phase E.6 wiring)
    //
    // Each write helper resolves the `pass` binary lazily through the
    // same discovery path as ``show(entryPath:timeout:)`` and forwards
    // the call to the matching ``PassCLI`` write method. The optional
    // `passwordStoreDirOverride` keeps the env in sync with
    // ``LivePassManager``'s live store-root provider on every call.

    /// Run `pass insert -m [-f] <path>` against the lazily-resolved
    /// `pass` binary. See ``PassCLI/insert(path:body:force:timeout:)``
    /// for the body / force / timeout semantics.
    public func insert(
        path: String,
        body: Data,
        force: Bool,
        passwordStoreDirOverride: URL? = nil
    ) async throws {
        let cli = try await resolveCLI(passwordStoreDirOverride: passwordStoreDirOverride)
        try await cli.insert(path: path, body: body, force: force)
    }

    /// Run `pass generate [-f] [-n] <path> <length>`. See
    /// ``PassCLI/generate(path:length:noSymbols:force:timeout:)`` for
    /// the flag / parsing semantics.
    public func generate(
        path: String,
        length: Int,
        noSymbols: Bool,
        force: Bool,
        passwordStoreDirOverride: URL? = nil
    ) async throws -> String {
        let cli = try await resolveCLI(passwordStoreDirOverride: passwordStoreDirOverride)
        return try await cli.generate(
            path: path,
            length: length,
            noSymbols: noSymbols,
            force: force
        )
    }

    /// Run `pass generate [-n] --in-place <path> <length>`. See
    /// ``PassCLI/generateInPlace(path:length:noSymbols:timeout:)``.
    public func generateInPlace(
        path: String,
        length: Int,
        noSymbols: Bool,
        passwordStoreDirOverride: URL? = nil
    ) async throws -> String {
        let cli = try await resolveCLI(passwordStoreDirOverride: passwordStoreDirOverride)
        return try await cli.generateInPlace(
            path: path,
            length: length,
            noSymbols: noSymbols
        )
    }

    /// Run `pass rm -f <path>`. See ``PassCLI/remove(path:timeout:)``.
    public func remove(
        path: String,
        passwordStoreDirOverride: URL? = nil
    ) async throws {
        let cli = try await resolveCLI(passwordStoreDirOverride: passwordStoreDirOverride)
        try await cli.remove(path: path)
    }

    /// Run `pass mv [-f] <from> <to>`. See
    /// ``PassCLI/move(from:to:force:timeout:)``.
    public func move(
        from: String,
        to newPath: String,
        force: Bool,
        passwordStoreDirOverride: URL? = nil
    ) async throws {
        let cli = try await resolveCLI(passwordStoreDirOverride: passwordStoreDirOverride)
        try await cli.move(from: from, to: newPath, force: force)
    }

    // MARK: - Private

    private func resolveCLI(passwordStoreDirOverride: URL? = nil) async throws -> PassCLI {
        // The cached `PassCLI` is reusable only when no per-call
        // store-dir override is supplied; otherwise the environment
        // dictionary would be wrong for this invocation. Building a
        // fresh `PassCLI` value type is cheap (it does not spawn
        // anything) so we accept that cost on the override path.
        if passwordStoreDirOverride == nil, let resolved { return resolved }

        guard let executable = await discovery.locate(.pass) else {
            throw PassError.binaryNotFound(BinaryName.pass.rawValue)
        }

        let effectiveStoreDir = passwordStoreDirOverride ?? passwordStoreDir
        let cli = PassCLI(
            executable: executable,
            shellRunner: shellRunner,
            passwordStoreDir: effectiveStoreDir,
            gnupgHome: gnupgHome,
            pathOverride: pathOverride,
            homeOverride: homeOverride
        )
        if passwordStoreDirOverride == nil {
            resolved = cli
        }
        return cli
    }
}
