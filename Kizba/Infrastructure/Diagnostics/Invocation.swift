//
//  Invocation.swift
//  Kizba
//
//  Value type recording a single shell invocation for the in-memory
//  Diagnostics ring buffer (`InvocationLog`).
//
//  Hard rules (per `.ai/decisions.md` and `.ai/plan.md` Phase 8.4):
//
//  - Captured `stdout` is **intentionally excluded** from this struct
//    and from any sink that publishes it. Diagnostics surface only
//    metadata + sanitised `stderr` excerpts.
//  - `args` and `stderrExcerpt` are expected to be sanitised at the
//    publisher (`ProcessShellRunner`) via `PassErrorMapper.sanitize`
//    before being stored here.
//  - The struct is `Sendable` so it can be passed across actor
//    boundaries (notably from `ProcessShellRunner` into the
//    `InvocationLog` actor and back to the `@MainActor`
//    `DiagnosticsModel`).
//

import Foundation

/// One recorded shell invocation, as surfaced to the Diagnostics view.
///
/// `stdout` is **never** stored — secrets must not enter the ring
/// buffer under any circumstances. See `.ai/decisions.md`.
public struct Invocation: Sendable, Identifiable, Equatable {

    /// Unique identifier (used by SwiftUI list diffing in
    /// `DiagnosticsView`).
    public let id: UUID

    /// Absolute path of the spawned executable (or its basename if the
    /// publisher chose to redact). Stored verbatim for diagnostics —
    /// callers are responsible for marking it `.private` when feeding
    /// it through `os.Logger`.
    public let executable: String

    /// Argument vector as seen by the child process, after publisher
    /// sanitisation (emails / hex IDs redacted, length-capped).
    public let args: [String]

    /// Process exit code. `0` denotes success; negative sentinels are
    /// used for spawn-time / cancellation / timeout outcomes.
    public let exitCode: Int32

    /// Sanitised, length-limited excerpt of the child's stderr.
    public let stderrExcerpt: String

    /// Wall-clock timestamp captured when the child was spawned.
    public let startedAt: Date

    /// Wall-clock duration between spawn and termination.
    public let duration: TimeInterval

    public nonisolated init(
        id: UUID = UUID(),
        executable: String,
        args: [String],
        exitCode: Int32,
        stderrExcerpt: String,
        startedAt: Date,
        duration: TimeInterval
    ) {
        self.id = id
        self.executable = executable
        self.args = args
        self.exitCode = exitCode
        self.stderrExcerpt = stderrExcerpt
        self.startedAt = startedAt
        self.duration = duration
    }
}
