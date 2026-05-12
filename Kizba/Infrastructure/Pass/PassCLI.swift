//
//  PassCLI.swift
//  Kizba
//
//  Production `PassManaging.show(_:)` collaborator: composes a
//  `pass show <entry>` invocation, runs it through `ShellCommandRunning`,
//  parses the decrypted body with `PassShowParser`, and maps any
//  failure stderr through `PassErrorMapper` to a sanitised
//  `PassError`.
//
//  Hard rules (per `.ai/decisions.md`, Phase 4.5):
//
//  - Captured `stdout` (the decrypted secret) is NEVER logged. Only
//    sanitised metadata reaches `Log.pass`: executable path (private),
//    arg count (public), exit code (public), stderr byte length
//    (public), sanitised excerpt (private).
//  - `Foundation.Process` is not touched here. All process work goes
//    through the injected `ShellCommandRunning` so this type is
//    deterministically testable with a `FakeShellRunner`.
//  - The runner contract requires an absolute executable URL — PATH
//    lookup is the job of `BinaryDiscoveryService` (Phase 5). `PassCLI`
//    therefore takes a pre-resolved `executable: URL` at construction.
//  - Empty environment dictionaries do not inherit the parent — so we
//    explicitly compose `PATH` (plus optional `PASSWORD_STORE_DIR` /
//    `GNUPGHOME` / `HOME`) on every invocation. Inherited launchd PATH
//    is not trusted; the default is a sanitised hard-coded list.
//

import Foundation
import os

/// Default wall-clock timeout for `pass show` invocations.
///
/// `.ai/decisions.md`: "pass show timeout = 120s with visible Cancel.
/// Pinentry can take arbitrary user time; default 20s is too aggressive."
public nonisolated let kizbaPassShowDefaultTimeout: Duration = .seconds(120)

/// Composes and executes `pass show <entry>` and surfaces the result
/// as a parsed ``PassShowResult`` or a mapped ``PassError``.
///
/// ## Threading contract
///
/// `Sendable`. Calls are `async` and may be invoked from any actor.
/// Cooperative cancellation is honoured by the underlying
/// `ShellCommandRunning` implementation — cancelling the calling
/// `Task` terminates the child `pass` process.
///
/// ## Logging
///
/// Every invocation emits at most one `Log.pass.info` record on
/// success and one `Log.pass.error` record on failure. Records carry
/// only sanctioned shape-only fields plus `.private`-marked path /
/// excerpt strings. Decrypted stdout is never logged.
public nonisolated struct PassCLI: Sendable {

    /// Absolute path of the `pass` binary (resolved upstream by
    /// `BinaryLocating` in Phase 5).
    public let executable: URL

    /// Process spawner — injected for testability.
    public let shellRunner: any ShellCommandRunning

    /// Optional override for `PASSWORD_STORE_DIR`. When `nil`, the
    /// variable is not exported and `pass` falls back to its default
    /// (`~/.password-store`).
    public let passwordStoreDir: URL?

    /// Optional override for `GNUPGHOME`. When `nil`, the variable is
    /// not exported and `gpg` uses the default (`~/.gnupg`).
    public let gnupgHome: URL?

    /// Optional override for the child's `PATH`. When `nil`, a
    /// sanitised hard-coded list is exported (see ``defaultPATH``).
    public let pathOverride: String?

    /// Optional override for the child's `HOME`. When `nil`, the
    /// process' own `HOME` is forwarded if present — required for
    /// `gpg`'s default `GNUPGHOME` resolution and for `pinentry-mac`
    /// preferences. No other parent env vars are forwarded.
    public let homeOverride: String?

    /// Sanitised default `PATH` exported when no override is supplied.
    /// Mirrors the `BinaryLocating` resolution order, which is the
    /// only PATH topology Kizba is willing to vouch for.
    public static let defaultPATH: String =
        "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

    /// Designated initialiser.
    ///
    /// - Parameters:
    ///   - executable: Absolute path of the `pass` binary.
    ///   - shellRunner: Process spawner (real `ProcessShellRunner` in
    ///     production, `FakeShellRunner` in tests).
    ///   - passwordStoreDir: Optional override for `PASSWORD_STORE_DIR`.
    ///   - gnupgHome: Optional override for `GNUPGHOME`.
    ///   - pathOverride: Optional override for `PATH`. `nil` exports
    ///     ``defaultPATH``.
    ///   - homeOverride: Optional override for `HOME`. `nil` forwards
    ///     the parent's `HOME` if defined.
    public init(
        executable: URL,
        shellRunner: any ShellCommandRunning,
        passwordStoreDir: URL? = nil,
        gnupgHome: URL? = nil,
        pathOverride: String? = nil,
        homeOverride: String? = nil
    ) {
        self.executable = executable
        self.shellRunner = shellRunner
        self.passwordStoreDir = passwordStoreDir
        self.gnupgHome = gnupgHome
        self.pathOverride = pathOverride
        self.homeOverride = homeOverride
    }

    /// Runs `pass show <entryPath>` and returns the parsed body.
    ///
    /// - Parameters:
    ///   - entryPath: Pass entry path, e.g. `"personal/email/gmail"`.
    ///     Forwarded as a single discrete `argv` entry — no shell
    ///     re-parsing — so spaces and other shell-meaningful
    ///     characters are safe.
    ///   - timeout: Hard wall-clock deadline. Defaults to
    ///     ``kizbaPassShowDefaultTimeout`` (120s).
    /// - Returns: A ``PassShowResult`` parsed from the child's stdout.
    /// - Throws: A ``PassError`` mapped from stderr / exit code via
    ///   ``PassErrorMapper``, or ``PassError/cancelled`` /
    ///   ``PassError/timedOut`` propagated from the runner.
    public func show(
        entryPath: String,
        timeout: Duration = kizbaPassShowDefaultTimeout
    ) async throws -> PassShowResult {

        let arguments = ["show", entryPath]
        let environment = composedEnvironment()

        let result: ShellResult
        do {
            result = try await shellRunner.run(
                executable: executable,
                arguments: arguments,
                environment: environment,
                timeout: timeout
            )
        } catch let error as PassError {
            // Runner already produced a domain error (timedOut /
            // cancelled / spawn-time shellFailure). Log shape-only and
            // re-throw — never log the underlying message body.
            switch error {
            case .timedOut:
                Log.pass.error(
                    "pass show timed out: exe=\(executable.path, privacy: .private) argc=\(arguments.count, privacy: .public)"
                )
            case .cancelled:
                Log.pass.info(
                    "pass show cancelled: exe=\(executable.path, privacy: .private) argc=\(arguments.count, privacy: .public)"
                )
            default:
                Log.pass.error(
                    "pass show shell error: exe=\(executable.path, privacy: .private) argc=\(arguments.count, privacy: .public)"
                )
            }
            throw error
        }

        let stderrString = String(data: result.standardError, encoding: .utf8) ?? ""

        // Non-zero exit, or empty stdout with stderr signal: route through
        // the mapper to obtain a sanitised excerpt and a domain error.
        if result.exitCode != 0 {
            let (mapped, excerpt) = PassErrorMapper.map(
                stderr: stderrString,
                exitCode: Int(result.exitCode),
                commandContext: .show
            )
            Log.pass.error(
                """
                pass show failed: exe=\(self.executable.path, privacy: .private) \
                argc=\(arguments.count, privacy: .public) \
                status=\(result.exitCode, privacy: .public) \
                stderrBytes=\(result.standardError.count, privacy: .public) \
                excerpt=\(excerpt, privacy: .private)
                """
            )
            throw mapped
        }

        // Success path. Decode stdout strictly as UTF-8; on lossy data
        // we surface a parsing failure rather than risk garbled output
        // reaching the clipboard.
        guard let body = String(data: result.standardOutput, encoding: .utf8) else {
            Log.pass.error(
                "pass show: stdout was not valid UTF-8 (\(result.standardOutput.count, privacy: .public) bytes)"
            )
            throw PassError.parsingFailed(reason: "stdout was not valid UTF-8")
        }

        do {
            let parsed = try PassShowParser.parse(body)
            Log.pass.info(
                """
                pass show ok: exe=\(self.executable.path, privacy: .private) \
                argc=\(arguments.count, privacy: .public) \
                status=\(result.exitCode, privacy: .public) \
                stderrBytes=\(result.standardError.count, privacy: .public)
                """
            )
            return parsed
        } catch {
            Log.pass.error(
                "pass show: parser rejected body (\(result.standardOutput.count, privacy: .public) bytes)"
            )
            throw error
        }
    }

    // MARK: - Private

    /// Build the environment dictionary forwarded to the child.
    ///
    /// The runner does not inherit the parent environment when given
    /// `[:]`; we therefore compose the minimum sufficient set:
    /// `PATH` (always), plus `PASSWORD_STORE_DIR`, `GNUPGHOME`, `HOME`
    /// when configured / available. No other parent env vars are
    /// forwarded — keeps the failure surface predictable.
    ///
    /// Exposed at `internal` visibility so the write-method extension
    /// (`PassCLI+Write.swift`) can reuse the exact same env composition
    /// as `show`. Still not part of the public API.
    internal func composedEnvironment() -> [String: String] {
        var env: [String: String] = [
            "PATH": pathOverride ?? Self.defaultPATH,
        ]
        if let passwordStoreDir {
            env["PASSWORD_STORE_DIR"] = passwordStoreDir.path
        }
        if let gnupgHome {
            env["GNUPGHOME"] = gnupgHome.path
        }
        if let homeOverride {
            env["HOME"] = homeOverride
        } else if let parentHome = ProcessInfo.processInfo.environment["HOME"] {
            // `gpg`/`pinentry-mac` rely on $HOME for default paths and
            // GUI prompt placement; forward the parent's value when no
            // explicit override is provided.
            env["HOME"] = parentHome
        }
        // Force the classic RFC 4880 OpenPGP format (MDC, NOT AEAD) for
        // every `gpg --encrypt` invocation triggered by `pass`. GnuPG 2.4+
        // defaults to AEAD packets when the recipient's self-signature
        // advertises AEAD support (e.g. cv25519 ECDH subkeys), but AEAD
        // packets are not yet readable by every OpenPGP client in the
        // wild — Pass for iOS (OpenPGP.js), Android Password Store,
        // older GnuPG (< 2.4), and other RFC 4880 implementations all
        // fail to decrypt with errors like "OpenPGP chain error".
        // `pass` forwards `$PASSWORD_STORE_GPG_OPTS` to every `gpg`
        // invocation (encrypt AND decrypt). For decrypt the flag is a
        // no-op (gpg ignores format selectors when reading); for encrypt
        // it pins the universally-compatible classic packet format.
        // This single env var is the cleanest fix and avoids touching
        // recipients, cipher selection, or the gpg binary in use.
        env["PASSWORD_STORE_GPG_OPTS"] = "--rfc4880"
        return env
    }
}
