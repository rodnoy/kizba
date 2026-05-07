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
    /// - Throws: ``PassError/binaryNotFound`` if discovery returns
    ///   `nil`; otherwise any error surfaced by ``PassCLI/show(entryPath:timeout:)``.
    public func show(
        entryPath: String,
        timeout: Duration = kizbaPassShowDefaultTimeout
    ) async throws -> PassShowResult {
        let cli = try await resolveCLI()
        return try await cli.show(entryPath: entryPath, timeout: timeout)
    }

    /// Drop the cached ``PassCLI`` so the next call re-runs discovery.
    /// Hook for the Settings "Re-detect binaries" action (Phase 8).
    public func invalidate() {
        resolved = nil
    }

    // MARK: - Private

    private func resolveCLI() async throws -> PassCLI {
        if let resolved { return resolved }

        guard let executable = await discovery.locate(.pass) else {
            throw PassError.binaryNotFound(BinaryName.pass.rawValue)
        }

        let cli = PassCLI(
            executable: executable,
            shellRunner: shellRunner,
            passwordStoreDir: passwordStoreDir,
            gnupgHome: gnupgHome,
            pathOverride: pathOverride,
            homeOverride: homeOverride
        )
        resolved = cli
        return cli
    }
}
