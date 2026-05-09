//
//  ShellInvocation.swift
//  Kizba
//
//  Structured value type describing a single shell invocation. Carries
//  everything `ShellCommandRunning` needs to spawn the child, including
//  optional stdin payload.
//
//  Introduced in MVP 2 Phase E.1 to plumb stdin support for write-side
//  CLI calls (`pass insert -m`). The legacy parameter-list signature on
//  ``ShellCommandRunning/run(executable:arguments:environment:timeout:)``
//  is preserved as a compat extension that delegates with `stdin: .none`,
//  so existing call sites (read-side `pass show`, scanner discovery,
//  diagnostics) keep compiling unchanged.
//
//  Hard rules (per `.ai/decisions.md`):
//
//  - `stdin` payload bytes MUST NEVER be logged. Implementations log
//    only `stdinByteCount` (sanitised metadata).
//  - `environment` is non-optional; callers compose it explicitly.
//    Empty dict means "child gets an empty environment". The runner
//    never inherits the parent's environment.
//  - `Sendable` so the runner can dispatch across actor boundaries.
//  - `Equatable` so test fakes can assert exact-shape captures
//    (including stdin bytes).
//

import Foundation

/// Structured description of one external-command invocation.
public struct ShellInvocation: Sendable, Equatable {

    /// Stdin handling mode for the child process.
    ///
    /// - `none`: the runner attaches `FileHandle.nullDevice` (or the
    ///   equivalent) so the child sees an immediate EOF. This is the
    ///   default for the read-side path.
    /// - `data(_:)`: the runner attaches a `Pipe`, writes the bytes,
    ///   then closes the write end so the child observes EOF.
    /// - `closeImmediately`: the runner attaches a `Pipe` and closes
    ///   the write end without writing anything. Some CLIs distinguish
    ///   "no input" from "stdin closed by parent" — this case is here
    ///   for that scenario.
    public enum Stdin: Sendable, Equatable {
        case none
        case data(Data)
        case closeImmediately
    }

    /// Absolute path to the binary to spawn. Resolved by
    /// ``BinaryLocating`` upstream; the runner does not consult `PATH`.
    public let executable: URL

    /// Argument vector (excluding `argv[0]`).
    public let arguments: [String]

    /// Full environment dictionary. Empty dict ⇒ empty child environment.
    public let environment: [String: String]

    /// Stdin handling mode; see ``Stdin``.
    public let stdin: Stdin

    /// Maximum wall-clock duration before the child is terminated and
    /// ``PassError/timedOut`` is thrown.
    public let timeout: Duration

    public init(
        executable: URL,
        arguments: [String] = [],
        environment: [String: String] = [:],
        stdin: Stdin = .none,
        timeout: Duration
    ) {
        self.executable = executable
        self.arguments = arguments
        self.environment = environment
        self.stdin = stdin
        self.timeout = timeout
    }

    /// Number of bytes that will be written to the child's stdin.
    /// `0` for ``Stdin/none`` and ``Stdin/closeImmediately``.
    /// Safe to log — content is never exposed.
    public var stdinByteCount: Int {
        switch stdin {
        case .none, .closeImmediately: return 0
        case .data(let data):          return data.count
        }
    }
}
