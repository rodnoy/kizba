//
//  PassCLI+Write.swift
//  Kizba
//
//  Phase E.5 — write-side `pass` invocations layered on top of
//  ``PassCLI``. Composes `pass insert -m`, `pass generate`,
//  `pass generate --in-place`, `pass rm` and `pass mv` invocations,
//  runs them through the injected ``ShellCommandRunning`` and maps
//  any failure to a typed ``PassError`` via ``PassErrorMapper``.
//
//  Hard rules (per `.ai/decisions.md`, Phase E.5):
//
//  - ``insert(path:body:force:timeout:)`` accepts the body as raw
//    `Data` (bytes). Callers (typically `LivePassManager` in Phase
//    E.6) are responsible for serialising the ``PassSecret`` /
//    ``SecretDraft`` via ``PassSecretSerializer`` and encoding the
//    resulting String as UTF-8. The CLI layer adds NO extra bytes:
//    no leading/trailing newline, no separator. Whatever the
//    serializer produced is fed verbatim to the child's stdin.
//  - The body MUST NEVER be logged, copied to user-visible diagnostic
//    fields, or otherwise echoed. The runner records only
//    `stdinByteCount` per `.ai/decisions.md`.
//  - The argv shapes match the table in `.ai/plan.md` Phase E.5
//    exactly. Force / no-symbols flag positions are stable so callers
//    and tests can rely on them.
//  - `pass insert -m -f` over an existing entry silently overwrites
//    — the UI handles confirmation BEFORE setting `force: true`.
//  - Always uses `pass insert -m` (multiline / read-until-EOF), never
//    the two-prompt interactive form, per the locked decision in
//    `.ai/decisions.md`.
//

import Foundation
import os

public extension PassCLI {

    /// Default wall-clock timeout for `pass insert` / `pass generate`
    /// / `pass mv`. Decision rationale: `pass insert` has to spawn
    /// `gpg` which may invoke pinentry the FIRST time a recipient is
    /// touched (cache miss); 15s gives ample headroom for that vs.
    /// the read-side default of 120s where pinentry is the *common*
    /// path.
    static let kizbaPassWriteDefaultTimeout: Duration = .seconds(15)

    /// Default wall-clock timeout for `pass rm`. Pure filesystem op,
    /// no GPG / pinentry involvement; 10s is comfortable.
    static let kizbaPassRemoveDefaultTimeout: Duration = .seconds(10)

    // MARK: - insert

    /// Calls `pass insert -m [-f] <path>` and feeds the supplied
    /// `body` bytes to the child's stdin.
    ///
    /// - Parameters:
    ///   - path: Pass entry path (without the `.gpg` suffix).
    ///   - body: Raw stdin payload. MUST be the UTF-8 bytes produced
    ///     by ``PassSecretSerializer`` — the CLI layer does not add a
    ///     leading or trailing newline, and never logs these bytes.
    ///   - force: When `true`, adds the `-f` flag so `pass` silently
    ///     overwrites an existing entry. The UI is expected to render
    ///     a confirmation banner BEFORE setting `force` to `true`.
    ///   - timeout: Wall-clock deadline. Defaults to
    ///     ``kizbaPassWriteDefaultTimeout`` (15s).
    /// - Throws: A typed ``PassError`` mapped via
    ///   ``PassErrorMapper`` (`commandContext == .insert`). Notable
    ///   cases: ``PassError/entryAlreadyExists(path:)`` when `force`
    ///   is `false` and the path exists;
    ///   ``PassError/recipientNotFound(emailOrKeyId:)`` when `gpg`
    ///   cannot resolve a recipient from `.gpg-id`.
    func insert(
        path: String,
        body: Data,
        force: Bool,
        timeout: Duration = .seconds(15)
    ) async throws {
        var arguments: [String] = ["insert", "-m"]
        if force { arguments.append("-f") }
        arguments.append(path)

        let invocation = ShellInvocation(
            executable: executable,
            arguments: arguments,
            environment: composedEnvironment(),
            stdin: .data(body),
            timeout: timeout
        )

        let result = try await runWriteInvocation(
            invocation,
            commandContext: .insert,
            verb: "insert"
        )

        // `pass insert` produces no stdout we care about. Log only
        // shape-only metadata; never the body or any stdout text.
        Log.pass.info(
            """
            pass insert ok: exe=\(self.executable.path, privacy: .private) \
            argc=\(arguments.count, privacy: .public) \
            status=\(result.exitCode, privacy: .public) \
            bytesIn=\(invocation.stdinByteCount, privacy: .public) \
            stderrBytes=\(result.standardError.count, privacy: .public)
            """
        )
    }

    // MARK: - generate (commit-new)

    /// Calls `pass generate [-f] [-n] <path> <length>`.
    ///
    /// - Parameters:
    ///   - path: Pass entry path (without the `.gpg` suffix).
    ///   - length: Requested password length. Forwarded verbatim as
    ///     `argv[N]`; `pass generate` itself enforces `pass-length`
    ///     bounds and surfaces ``PassError/invalidLength`` when the
    ///     value is rejected.
    ///   - noSymbols: When `true`, adds the `-n` flag so the
    ///     generator omits the symbols character class.
    ///   - force: When `true`, adds the `-f` flag so `pass` silently
    ///     overwrites an existing entry.
    ///   - timeout: Wall-clock deadline. Defaults to
    ///     ``kizbaPassWriteDefaultTimeout`` (15s).
    /// - Returns: The newly generated password, parsed from stdout
    ///   via ``PassGenerateParser``.
    /// - Throws: A typed ``PassError`` mapped via
    ///   ``PassErrorMapper`` (`commandContext == .generate`).
    @discardableResult
    func generate(
        path: String,
        length: Int,
        noSymbols: Bool,
        force: Bool,
        timeout: Duration = .seconds(15)
    ) async throws -> String {
        var arguments: [String] = ["generate"]
        if force { arguments.append("-f") }
        if noSymbols { arguments.append("-n") }
        arguments.append(path)
        arguments.append(String(length))

        let invocation = ShellInvocation(
            executable: executable,
            arguments: arguments,
            environment: composedEnvironment(),
            stdin: .none,
            timeout: timeout
        )

        let result = try await runWriteInvocation(
            invocation,
            commandContext: .generate,
            verb: "generate"
        )

        return try parseGeneratePassword(
            from: result,
            arguments: arguments,
            verb: "generate"
        )
    }

    // MARK: - generate (in-place)

    /// Calls `pass generate [-n] --in-place <path> <length>`.
    ///
    /// `--in-place` rewrites the password line of an existing entry
    /// while preserving the metadata + notes block atomically — the
    /// ideal "rotate the password" path. There is no force flag for
    /// the in-place variant; if the entry is missing, `pass` emits
    /// a `not in the password store` stderr that maps to
    /// ``PassError/sourceNotFound(path:)``.
    ///
    /// - Parameters:
    ///   - path: Pass entry path (without the `.gpg` suffix). Must
    ///     already exist in the store.
    ///   - length: Requested password length.
    ///   - noSymbols: When `true`, adds the `-n` flag.
    ///   - timeout: Wall-clock deadline. Defaults to
    ///     ``kizbaPassWriteDefaultTimeout`` (15s).
    /// - Returns: The newly generated password.
    /// - Throws: A typed ``PassError`` mapped via
    ///   ``PassErrorMapper`` (`commandContext == .generate`).
    @discardableResult
    func generateInPlace(
        path: String,
        length: Int,
        noSymbols: Bool,
        timeout: Duration = .seconds(15)
    ) async throws -> String {
        // Argv order chosen to match `pass`'s own usage examples and
        // to keep the optional `-n` flag adjacent to the other
        // generation flags rather than buried after `--in-place`.
        var arguments: [String] = ["generate"]
        if noSymbols { arguments.append("-n") }
        arguments.append("--in-place")
        arguments.append(path)
        arguments.append(String(length))

        let invocation = ShellInvocation(
            executable: executable,
            arguments: arguments,
            environment: composedEnvironment(),
            stdin: .none,
            timeout: timeout
        )

        let result = try await runWriteInvocation(
            invocation,
            commandContext: .generate,
            verb: "generate-in-place"
        )

        return try parseGeneratePassword(
            from: result,
            arguments: arguments,
            verb: "generate-in-place"
        )
    }

    // MARK: - rm

    /// Calls `pass rm -f <path>`.
    ///
    /// Always passes `-f` (`--force`) — `pass rm` without `-f` would
    /// prompt on stdin for confirmation, which we cannot satisfy from
    /// a GUI. The UI is expected to render the two-step destructive
    /// confirmation BEFORE invoking this method.
    ///
    /// - Parameters:
    ///   - path: Pass entry path (without the `.gpg` suffix).
    ///   - timeout: Wall-clock deadline. Defaults to
    ///     ``kizbaPassRemoveDefaultTimeout`` (10s).
    /// - Throws: A typed ``PassError`` mapped via
    ///   ``PassErrorMapper`` (`commandContext == .remove`). Notable:
    ///   ``PassError/sourceNotFound(path:)`` when the entry does not
    ///   exist (listing was stale).
    func remove(
        path: String,
        timeout: Duration = .seconds(10)
    ) async throws {
        let arguments: [String] = ["rm", "-f", path]

        let invocation = ShellInvocation(
            executable: executable,
            arguments: arguments,
            environment: composedEnvironment(),
            stdin: .none,
            timeout: timeout
        )

        let result = try await runWriteInvocation(
            invocation,
            commandContext: .remove,
            verb: "rm"
        )

        Log.pass.info(
            """
            pass rm ok: exe=\(self.executable.path, privacy: .private) \
            argc=\(arguments.count, privacy: .public) \
            status=\(result.exitCode, privacy: .public) \
            stderrBytes=\(result.standardError.count, privacy: .public)
            """
        )
    }

    // MARK: - mv

    /// Calls `pass mv [-f] <from> <to>`.
    ///
    /// - Parameters:
    ///   - from: Source pass entry path.
    ///   - newPath: Destination pass entry path.
    ///   - force: When `true`, adds the `-f` flag so `pass` silently
    ///     overwrites an existing destination.
    ///   - timeout: Wall-clock deadline. Defaults to
    ///     ``kizbaPassWriteDefaultTimeout`` (15s).
    /// - Throws: A typed ``PassError`` mapped via
    ///   ``PassErrorMapper`` (`commandContext == .move`). Notable:
    ///   ``PassError/sourceNotFound(path:)`` when `from` does not
    ///   exist; ``PassError/entryAlreadyExists(path:)`` when `to`
    ///   exists and `force` is `false`.
    func move(
        from: String,
        to newPath: String,
        force: Bool,
        timeout: Duration = .seconds(15)
    ) async throws {
        var arguments: [String] = ["mv"]
        if force { arguments.append("-f") }
        arguments.append(from)
        arguments.append(newPath)

        let invocation = ShellInvocation(
            executable: executable,
            arguments: arguments,
            environment: composedEnvironment(),
            stdin: .none,
            timeout: timeout
        )

        let result = try await runWriteInvocation(
            invocation,
            commandContext: .move,
            verb: "mv"
        )

        Log.pass.info(
            """
            pass mv ok: exe=\(self.executable.path, privacy: .private) \
            argc=\(arguments.count, privacy: .public) \
            status=\(result.exitCode, privacy: .public) \
            stderrBytes=\(result.standardError.count, privacy: .public)
            """
        )
    }

    // MARK: - Shared write plumbing

    /// Runs a write-side ``ShellInvocation`` and surfaces a
    /// ``PassError`` on failure. Returns the raw ``ShellResult`` on
    /// success so per-method post-processing (e.g. `generate` stdout
    /// parsing) can run in the caller.
    ///
    /// Failure routing mirrors ``PassCLI/show(entryPath:timeout:)``:
    /// runner-thrown ``PassError`` (timeout / cancellation /
    /// spawn-time shell failure) is logged shape-only and re-thrown
    /// verbatim; non-zero exit codes are routed through
    /// ``PassErrorMapper/map(stderr:exitCode:commandContext:)`` with
    /// the supplied `commandContext` so ambiguous stderr signatures
    /// (notably "is not in the password store") resolve to the right
    /// case.
    private func runWriteInvocation(
        _ invocation: ShellInvocation,
        commandContext: PassErrorMapper.CommandContext,
        verb: String
    ) async throws -> ShellResult {
        let result: ShellResult
        do {
            result = try await shellRunner.run(invocation)
        } catch let error as PassError {
            switch error {
            case .timedOut:
                Log.pass.error(
                    """
                    pass \(verb, privacy: .public) timed out: \
                    exe=\(self.executable.path, privacy: .private) \
                    argc=\(invocation.arguments.count, privacy: .public) \
                    bytesIn=\(invocation.stdinByteCount, privacy: .public)
                    """
                )
            case .cancelled:
                Log.pass.info(
                    """
                    pass \(verb, privacy: .public) cancelled: \
                    exe=\(self.executable.path, privacy: .private) \
                    argc=\(invocation.arguments.count, privacy: .public) \
                    bytesIn=\(invocation.stdinByteCount, privacy: .public)
                    """
                )
            default:
                Log.pass.error(
                    """
                    pass \(verb, privacy: .public) shell error: \
                    exe=\(self.executable.path, privacy: .private) \
                    argc=\(invocation.arguments.count, privacy: .public) \
                    bytesIn=\(invocation.stdinByteCount, privacy: .public)
                    """
                )
            }
            throw error
        }

        if result.exitCode != 0 {
            let stderrString = String(data: result.standardError, encoding: .utf8) ?? ""
            let (mapped, excerpt) = PassErrorMapper.map(
                stderr: stderrString,
                exitCode: Int(result.exitCode),
                commandContext: commandContext
            )
            Log.pass.error(
                """
                pass \(verb, privacy: .public) failed: \
                exe=\(self.executable.path, privacy: .private) \
                argc=\(invocation.arguments.count, privacy: .public) \
                status=\(result.exitCode, privacy: .public) \
                bytesIn=\(invocation.stdinByteCount, privacy: .public) \
                stderrBytes=\(result.standardError.count, privacy: .public) \
                excerpt=\(excerpt, privacy: .private)
                """
            )
            throw mapped
        }

        return result
    }

    /// Parse the freshly-minted password out of `pass generate`
    /// stdout. The parser strips ANSI SGR sequences and returns the
    /// last non-empty trimmed line; the result is the cleartext
    /// password and MUST NEVER be logged.
    private func parseGeneratePassword(
        from result: ShellResult,
        arguments: [String],
        verb: String
    ) throws -> String {
        guard let stdout = String(data: result.standardOutput, encoding: .utf8) else {
            Log.pass.error(
                """
                pass \(verb, privacy: .public): stdout was not valid UTF-8 \
                (\(result.standardOutput.count, privacy: .public) bytes)
                """
            )
            throw PassError.parsingFailed(reason: "stdout was not valid UTF-8")
        }

        do {
            let password = try PassGenerateParser.parse(stdout)
            // Shape-only success log. NEVER include `password`.
            Log.pass.info(
                """
                pass \(verb, privacy: .public) ok: \
                exe=\(self.executable.path, privacy: .private) \
                argc=\(arguments.count, privacy: .public) \
                status=\(result.exitCode, privacy: .public) \
                stdoutBytes=\(result.standardOutput.count, privacy: .public) \
                stderrBytes=\(result.standardError.count, privacy: .public)
                """
            )
            return password
        } catch {
            Log.pass.error(
                """
                pass \(verb, privacy: .public): parser rejected stdout \
                (\(result.standardOutput.count, privacy: .public) bytes)
                """
            )
            throw PassError.parsingFailed(reason: "could not parse generated password")
        }
    }
}
