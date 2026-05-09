//
//  ShellCommandRunning.swift
//  Kizba
//
//  Domain-level abstraction for spawning external processes. The real
//  implementation is `ProcessShellRunner` (Phase 3); tests use
//  `FakeShellRunner`.
//
//  Phase E.1 introduced the structured ``ShellInvocation`` value type
//  as the primary call surface. The historical parameter-list signature
//  (`run(executable:arguments:environment:timeout:)`) is preserved as a
//  default-implemented compat method that delegates to ``run(_:)`` with
//  ``ShellInvocation/Stdin/none``. Existing read-side call sites
//  (`PassCLI.show`, scanner, discovery) keep compiling unchanged; new
//  write-side callers (`pass insert -m`) use ``run(_:)`` directly.
//

import Foundation

/// Result of a single shell invocation.
///
/// Captures `stdout` and `stderr` as raw bytes so that callers can
/// decide whether decoding is appropriate. `pass show` output, for
/// example, must never round-trip through `String` lossily.
public struct ShellResult: Sendable, Equatable {

    /// Process exit code. `0` denotes success.
    public let exitCode: Int32

    /// Captured standard output bytes (possibly empty).
    public let standardOutput: Data

    /// Captured standard error bytes (possibly empty).
    public let standardError: Data

    public nonisolated init(exitCode: Int32, standardOutput: Data, standardError: Data) {
        self.exitCode = exitCode
        self.standardOutput = standardOutput
        self.standardError = standardError
    }
}

/// Abstraction over `Foundation.Process` for running short-lived
/// external commands.
///
/// ## Threading contract
///
/// `Sendable`. Calls are `async` and isolated to a non-MainActor
/// context internally. Implementations must:
///
/// - drain stdout and stderr concurrently to avoid pipe deadlocks;
/// - feed ``ShellInvocation/stdin`` (when non-`.none`) on a separate
///   detached task so the write does not block the drain;
/// - enforce the supplied `timeout` and surface `PassError.timedOut`;
/// - honour `Task` cancellation by terminating the child process and
///   throwing `PassError.cancelled`.
///
/// Per `.ai/decisions.md`, implementations under `Infrastructure/Shell/`
/// must never log captured `stdout` or any `stdin` payload bytes —
/// only sanitised metadata (executable path private, argument count,
/// exit code, stderr byte length, `stdinByteCount`).
public protocol ShellCommandRunning: Sendable {

    /// Primary entry point — execute the supplied ``ShellInvocation``.
    ///
    /// - Parameter invocation: Structured description of the call,
    ///   including the optional stdin payload.
    /// - Returns: The captured ``ShellResult``.
    /// - Throws: ``PassError/timedOut``, ``PassError/cancelled``, or
    ///   ``PassError/shellFailure(exitCode:stderrExcerpt:)`` for
    ///   spawn-time failures.
    func run(_ invocation: ShellInvocation) async throws -> ShellResult
}

public extension ShellCommandRunning {

    /// Backwards-compatible parameter-list overload preserved for
    /// pre-Phase-E call sites (read-side `pass show`, scanner,
    /// discovery, diagnostics tests).
    ///
    /// Delegates to ``run(_:)`` with ``ShellInvocation/Stdin/none``.
    /// New write-side code should use ``run(_:)`` directly so it can
    /// supply a stdin payload.
    func run(
        executable: URL,
        arguments: [String],
        environment: [String: String],
        timeout: Duration
    ) async throws -> ShellResult {
        try await run(ShellInvocation(
            executable: executable,
            arguments: arguments,
            environment: environment,
            stdin: .none,
            timeout: timeout
        ))
    }
}
