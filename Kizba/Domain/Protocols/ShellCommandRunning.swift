//
//  ShellCommandRunning.swift
//  Kizba
//
//  Domain-level abstraction for spawning external processes. The real
//  implementation is `ProcessShellRunner` (Phase 3); tests use
//  `FakeShellRunner`.
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
/// - enforce the supplied `timeout` and surface `PassError.timedOut`;
/// - honour `Task` cancellation by terminating the child process and
///   throwing `PassError.cancelled`.
///
/// Per `.ai/decisions.md`, implementations under `Infrastructure/Shell/`
/// must never log captured `stdout`.
public protocol ShellCommandRunning: Sendable {

    /// Execute `executable` with the given arguments and environment.
    ///
    /// - Parameters:
    ///   - executable: Absolute path to the binary. Resolved by
    ///     ``BinaryLocating`` upstream — no PATH lookup happens here.
    ///   - arguments: Argument vector (excluding `argv[0]`).
    ///   - environment: Full environment dictionary. Inherited
    ///     environment is **not** trusted; callers compose this map.
    ///   - timeout: Maximum wall-clock duration before the child is
    ///     terminated and ``PassError/timedOut`` is thrown.
    /// - Returns: The captured ``ShellResult``.
    /// - Throws: ``PassError/timedOut``, ``PassError/cancelled``, or
    ///   ``PassError/shellFailure(exitCode:stderrExcerpt:)`` for
    ///   spawn-time failures.
    func run(
        executable: URL,
        arguments: [String],
        environment: [String: String],
        timeout: Duration
    ) async throws -> ShellResult
}
