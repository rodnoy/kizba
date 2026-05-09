//
//  LivePassManager.swift
//  Kizba
//
//  Phase 6.5 wiring: production conformance to ``PassManaging`` that
//  composes the read paths added in earlier phases.
//
//  Listing goes through ``PasswordStoreScanning`` (filesystem traversal
//  per `.ai/decisions.md`, "Listing via PasswordStoreScanner, not
//  pass ls"). Decryption goes through ``LivePassCLI`` (which lazily
//  resolves the `pass` binary via ``BinaryLocating`` and shells out to
//  `pass show <entry>`).
//
//  ## Threading contract
//
//  `actor`. The store root is sourced via a `@Sendable` closure
//  (``storeRootProvider``) so live overrides from ``SettingsStoring``
//  are honoured per call without forcing the manager itself to be
//  rebuilt. ``storeLocation()`` reads the provider synchronously and
//  is therefore `nonisolated`. `Sendable` is satisfied via the actor
//  model.
//
//  ## Logging
//
//  No additional `os.Logger` calls are emitted here — the underlying
//  scanner and `PassCLI` already log shape-only metadata; doubling it
//  up at this layer would only add noise.
//

import Foundation

/// Production ``PassManaging`` implementation backed by
/// ``PasswordStoreScanning`` (listing) and ``LivePassCLI`` (decryption).
public actor LivePassManager: PassManaging {

    /// Filesystem scanner used by ``listEntries()``.
    private let scanner: any PasswordStoreScanning

    /// Lazy `pass show` wrapper used by ``show(_:)``.
    private let passCLI: LivePassCLI

    /// Live provider for the active password store root. Evaluated on
    /// every public method invocation so changes to
    /// ``SettingsKeys/storePathOverride`` take effect on the next
    /// operation without an app restart.
    private let storeRootProvider: @Sendable () -> URL

    /// Designated initialiser.
    ///
    /// - Parameters:
    ///   - scanner: Filesystem scanner. Production wires
    ///     ``PasswordStoreScanner``; tests inject a fake.
    ///   - passCLI: Lazy `pass` CLI wrapper. Production wires the
    ///     real ``LivePassCLI``; tests inject one over a fake shell.
    ///   - storeRootProvider: Live closure returning the active store
    ///     root. Use ``LivePassManager/defaultStoreRoot`` inside the
    ///     closure to fall back to `~/.password-store` when no
    ///     override is configured.
    public init(
        scanner: any PasswordStoreScanning,
        passCLI: LivePassCLI,
        storeRootProvider: @escaping @Sendable () -> URL
    ) {
        self.scanner = scanner
        self.passCLI = passCLI
        self.storeRootProvider = storeRootProvider
    }

    /// Convenience initialiser for tests/preview wiring that have a
    /// fixed store root.
    public init(
        scanner: any PasswordStoreScanning,
        passCLI: LivePassCLI,
        storeRoot: URL
    ) {
        self.init(
            scanner: scanner,
            passCLI: passCLI,
            storeRootProvider: { storeRoot }
        )
    }

    /// Standard `~/.password-store` location used when no override is
    /// available from settings.
    nonisolated public static var defaultStoreRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".password-store", isDirectory: true)
    }

    // MARK: - PassManaging

    public func listEntries() async throws -> [PassEntry] {
        // Snapshot the store root once per public call so a single
        // operation is internally consistent even if the underlying
        // setting is mutated mid-flight.
        let root = storeRootProvider()
        let paths = try await scanner.listEntries(in: root)
        // Scanner already returns deterministically sorted paths;
        // preserve order. Each entry is identified by its path —
        // `PassEntry.id` is the path itself, so identity is stable
        // across refresh.
        //
        // Domain value-type initialisers are `MainActor`-isolated by
        // default under Swift 6's strict-concurrency mode, so the
        // mapping is performed via a MainActor hop.
        return await MainActor.run {
            paths.map { PassEntry(path: $0) }
        }
    }

    public func show(_ entry: PassEntry) async throws -> PassSecret {
        // Snapshot the store root for this call and forward it as
        // `PASSWORD_STORE_DIR` so `pass show` and the scanner agree on
        // which store to hit.
        let root = storeRootProvider()
        let result = try await passCLI.show(
            entryPath: entry.path,
            passwordStoreDirOverride: root
        )
        // Compose the domain value types on the MainActor — see the
        // note in ``listEntries()`` above. The decrypted body never
        // leaves this actor hop except as an opaque ``PassSecret``.
        return await MainActor.run {
            let fields = result.metadata.map { key, value in
                PassMetadata.Field(key: key, value: value)
            }
            let metadata = PassMetadata(fields: fields, notes: result.notes)
            return PassSecret(password: result.password, metadata: metadata)
        }
    }

    nonisolated public func storeLocation() -> URL {
        storeRootProvider()
    }
}
