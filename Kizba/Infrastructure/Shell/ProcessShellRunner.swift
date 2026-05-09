//
//  ProcessShellRunner.swift
//  Kizba
//
//  Production `ShellCommandRunning` implementation backed by
//  `Foundation.Process`. Concurrent stdout/stderr drain via pipe
//  readability handlers prevents pipe-buffer deadlocks; a `Task.sleep`
//  race enforces the timeout; `withTaskCancellationHandler` propagates
//  cooperative cancellation by terminating the child.
//
//  Logging discipline (`.ai/decisions.md`):
//    - never log captured stdout bytes;
//    - log only sanitised metadata (executable path with `.private`,
//      argument count, exit code, stderr byte length);
//    - if a stderr excerpt is ever logged elsewhere, it must use the
//      `.private` privacy marker. This file does not log stderr bytes.
//
//  Note: the project default actor isolation is `MainActor`. Every
//  declaration in this file is therefore explicitly `nonisolated` so
//  that the runner can be invoked from any context and so that pipe
//  readability handlers and `terminationHandler` (which run on private
//  Foundation queues) can call into our state without crossing actor
//  boundaries.
//

import Foundation
import os

/// Concurrency-safe `ShellCommandRunning` implementation.
///
/// Stateless — every `run(...)` call spawns a fresh `Process`. Marked
/// as a `final class` rather than an `actor` because each invocation is
/// already self-contained; serialisation across calls is unnecessary
/// and would only inflate latency for parallel `pass show` requests.
public final class ProcessShellRunner: ShellCommandRunning {

    /// Optional sink that receives one ``Invocation`` per `run` call
    /// (success, non-zero, timeout, or cancellation). `nil` disables
    /// publishing entirely so existing call sites keep their previous
    /// behaviour. See `.ai/plan.md` Phase 8.4.
    private let invocationLog: (any InvocationLogging)?

    public nonisolated init() {
        Self.installSIGPIPEHandlerIfNeeded()
        self.invocationLog = nil
    }

    /// Designated initialiser when a Diagnostics sink is desired.
    /// The sink is invoked from a detached task per call so the
    /// runner's hot path is not blocked by the actor's mailbox.
    public nonisolated init(invocationLog: (any InvocationLogging)?) {
        Self.installSIGPIPEHandlerIfNeeded()
        self.invocationLog = invocationLog
    }

    /// Disable the default `SIGPIPE` action for the host process.
    ///
    /// When the runner feeds stdin to a child that exits before
    /// consuming all the bytes (timeout, cancellation, error in the
    /// child, etc.), the `write(2)` call into the pipe receives
    /// `SIGPIPE`. The default action is to terminate the host process
    /// — fatal in tests and unacceptable in the GUI. We instead get
    /// `EPIPE` from `write(2)`, which is caught by the `do/catch`
    /// around `FileHandle.write(contentsOf:)` and surfaced as a
    /// sanitised debug log entry (no payload).
    ///
    /// Idempotent: only the first call wins; subsequent calls are
    /// no-ops thanks to the once-token. Safe to invoke from any
    /// thread.
    private nonisolated static func installSIGPIPEHandlerIfNeeded() {
        sigpipeOnce.perform {
            signal(SIGPIPE, SIG_IGN)
        }
    }

    public nonisolated func run(_ invocation: ShellInvocation) async throws -> ShellResult {

        let box = ProcessBox()
        let sink = self.invocationLog

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ShellResult, Error>) in
                Self.spawn(
                    invocation: invocation,
                    box: box,
                    continuation: continuation,
                    invocationLog: sink
                )
            }
        } onCancel: {
            // Cancellation handler runs synchronously on the cancelling
            // task. Mark the box and ask the child (if any) to die.
            box.cancel()
        }
    }

    // MARK: - Private

    /// Runs the child process and resolves `continuation` exactly once.
    private nonisolated static func spawn(
        invocation: ShellInvocation,
        box: ProcessBox,
        continuation: CheckedContinuation<ShellResult, Error>,
        invocationLog: (any InvocationLogging)?
    ) {
        let executable = invocation.executable
        let arguments = invocation.arguments
        let environment = invocation.environment
        let timeout = invocation.timeout

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        // Stdin wiring. `.none` keeps the historical behaviour (child
        // sees an immediate EOF via `/dev/null`). The two pipe-backed
        // modes attach a `Pipe`; the bytes (if any) are written from a
        // detached task once the process is running, so the write does
        // not block the stdout/stderr drain.
        let stdinPipe: Pipe?
        switch invocation.stdin {
        case .none:
            process.standardInput = FileHandle.nullDevice
            stdinPipe = nil
        case .data, .closeImmediately:
            let pipe = Pipe()
            process.standardInput = pipe
            stdinPipe = pipe
        }
        // Captured stdin byte count for sanitised logging / Diagnostics.
        // Content is NEVER captured anywhere.
        let recordedStdinByteCount: Int?
        switch invocation.stdin {
        case .none:                  recordedStdinByteCount = nil
        case .closeImmediately:      recordedStdinByteCount = 0
        case .data(let data):        recordedStdinByteCount = data.count
        }

        let drain = DrainState()
        let startedAt = Date()

        // Concurrent draining: each handler appends as bytes arrive.
        // Empty `Data` from the handler signals EOF — we tear the
        // handler down to release the file descriptor.
        outPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                handle.readabilityHandler = nil
            } else {
                drain.appendStdout(chunk)
            }
        }
        errPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                handle.readabilityHandler = nil
            } else {
                drain.appendStderr(chunk)
            }
        }

        // Single-shot resolution: termination, timeout, and
        // cancellation all funnel through `box.finish`.
        process.terminationHandler = { proc in
            // Drain any tail bytes still in the pipe buffers. Reading
            // to EOF here is safe because the child has exited.
            let tailOut = (try? outPipe.fileHandleForReading.readToEnd()) ?? Data()
            let tailErr = (try? errPipe.fileHandleForReading.readToEnd()) ?? Data()
            if !tailOut.isEmpty { drain.appendStdout(tailOut) }
            if !tailErr.isEmpty { drain.appendStderr(tailErr) }
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil

            let (out, err) = drain.snapshot()
            box.finish(.exited(exitCode: proc.terminationStatus, stdout: out, stderr: err))
        }

        do {
            try process.run()
        } catch {
            // Spawn-time failure (binary missing, not executable, …).
            // Map to `shellFailure` with exit code -1 so the UI still
            // has a stable contract.
            Log.shell.error(
                "process spawn failed for \(executable.path, privacy: .private): \(String(describing: error), privacy: .public)"
            )
            // Publish a sanitised invocation record so spawn-time
            // failures are still visible in Diagnostics.
            if let sink = invocationLog {
                let invocation = Self.makeInvocation(
                    executable: executable.path,
                    arguments: arguments,
                    exitCode: -1,
                    stderr: "spawn failed",
                    startedAt: startedAt,
                    finishedAt: Date(),
                    stdinByteCount: recordedStdinByteCount
                )
                Task.detached { await sink.record(invocation) }
            }
            continuation.resume(
                throwing: PassError.shellFailure(
                    exitCode: -1,
                    stderrExcerpt: "spawn failed"
                )
            )
            return
        }

        box.attach(process: process)

        // Already-cancelled tasks: terminate immediately. The
        // termination handler will resolve the continuation with
        // `.cancelled` because the box was pre-marked.
        if box.isCancelled {
            process.terminate()
        }

        // Stdin feed: write the payload (if any) on a detached task so
        // the write does not contend with the stdout/stderr drain. The
        // pipe's write end is closed unconditionally to signal EOF
        // (both `.data` and `.closeImmediately` need this). A broken
        // pipe (the child exited before consuming the bytes) is
        // logged as a sanitised debug-level event — never crashes,
        // never logs the payload content.
        if let pipe = stdinPipe {
            let stdinKind = invocation.stdin
            let exePathForStdin = executable.path
            Task.detached {
                let writer = pipe.fileHandleForWriting
                defer { try? writer.close() }
                if case .data(let data) = stdinKind, !data.isEmpty {
                    do {
                        try writer.write(contentsOf: data)
                    } catch {
                        // Broken pipe / child died early. Log shape
                        // only — `bytesIn` count, never content.
                        Log.shell.debug(
                            "shell stdin feed interrupted: exe=\(exePathForStdin, privacy: .private) bytesIn=\(data.count, privacy: .public) error=\(String(describing: type(of: error)), privacy: .public)"
                        )
                    }
                }
            }
        }

        // Timeout race: a detached task fires after `timeout` and asks
        // the box to surface a timeout. If the process exits first,
        // `box.finish(.exited)` wins and the timeout task becomes a
        // no-op when it eventually runs.
        let timeoutTask = Task.detached { [box] in
            do {
                try await Task.sleep(for: timeout)
            } catch {
                return // sleep cancelled — process already finished.
            }
            box.timeout()
        }

        // Resolve the continuation when the box reaches a terminal
        // state. The handler receives the first outcome to win the
        // race and logs sanitised metadata before resuming.
        let argc = arguments.count
        let exePath = executable.path
        box.onResolved { outcome in
            timeoutTask.cancel()
            let finishedAt = Date()

            // Compute the (exitCode, stderrBytes) pair the sink and
            // logger need. Errors carry no captured stderr — we use
            // a small sentinel string so Diagnostics still has
            // something useful.
            let recordedExit: Int32
            let recordedStderr: Data
            switch outcome {
            case .exited(let exitCode, _, let stderr):
                recordedExit = exitCode
                recordedStderr = stderr
            case .cancelled:
                recordedExit = -2
                recordedStderr = Data("cancelled".utf8)
            case .timedOut:
                recordedExit = -3
                recordedStderr = Data("timed out".utf8)
            }

            if let sink = invocationLog {
                let stderrString = String(data: recordedStderr, encoding: .utf8) ?? ""
                let invocation = Self.makeInvocation(
                    executable: exePath,
                    arguments: arguments,
                    exitCode: recordedExit,
                    stderr: stderrString,
                    startedAt: startedAt,
                    finishedAt: finishedAt,
                    stdinByteCount: recordedStdinByteCount
                )
                let excerptLength = invocation.stderrExcerpt.count
                Log.shell.debug(
                    "invocation recorded: exe=\(exePath, privacy: .private) status=\(recordedExit, privacy: .public) excerptLen=\(excerptLength, privacy: .public) bytesIn=\(recordedStdinByteCount ?? 0, privacy: .public)"
                )
                Task.detached { await sink.record(invocation) }
            }

            switch outcome {
            case .exited(let exitCode, let stdout, let stderr):
                Log.shell.info(
                    "shell exit: exe=\(exePath, privacy: .private) argc=\(argc, privacy: .public) status=\(exitCode, privacy: .public) stderrBytes=\(stderr.count, privacy: .public) bytesIn=\(recordedStdinByteCount ?? 0, privacy: .public)"
                )
                continuation.resume(returning: ShellResult(
                    exitCode: exitCode,
                    standardOutput: stdout,
                    standardError: stderr
                ))

            case .cancelled:
                Log.shell.info(
                    "shell cancelled: exe=\(exePath, privacy: .private) argc=\(argc, privacy: .public)"
                )
                continuation.resume(throwing: PassError.cancelled)

            case .timedOut:
                Log.shell.info(
                    "shell timeout: exe=\(exePath, privacy: .private) argc=\(argc, privacy: .public)"
                )
                continuation.resume(throwing: PassError.timedOut)
            }
        }
    }

    // MARK: - Invocation construction

    /// Build an ``Invocation`` with sanitised fields, ready to be
    /// stored in the ``InvocationLog``. Sanitisation reuses
    /// ``PassErrorMapper/sanitize(_:maxLength:)`` so emails / hex IDs
    /// are stripped consistently across UI surfaces.
    private nonisolated static func makeInvocation(
        executable: String,
        arguments: [String],
        exitCode: Int32,
        stderr: String,
        startedAt: Date,
        finishedAt: Date,
        stdinByteCount: Int?
    ) -> Invocation {
        let safeArgs = arguments.map { PassErrorMapper.sanitize($0, maxLength: 256) }
        let safeStderr = PassErrorMapper.sanitize(stderr, maxLength: Log.maxStderrExcerpt)
        return Invocation(
            executable: executable,
            args: safeArgs,
            exitCode: exitCode,
            stderrExcerpt: safeStderr,
            startedAt: startedAt,
            duration: finishedAt.timeIntervalSince(startedAt),
            stdinByteCount: stdinByteCount
        )
    }
}

// MARK: - Once-token

/// Trivial once-only execution helper used to install the SIGPIPE
/// handler exactly once, regardless of how many `ProcessShellRunner`
/// instances are constructed.
private final class OnceToken: @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var done = false
    nonisolated init() {}
    nonisolated func perform(_ block: () -> Void) {
        lock.lock()
        let alreadyDone = done
        if !alreadyDone { done = true }
        lock.unlock()
        if !alreadyDone { block() }
    }
}

nonisolated private let sigpipeOnce = OnceToken()

// MARK: - DrainState

/// Thread-safe accumulator for the two pipe readability handlers.
/// `Foundation` invokes the handlers on a private dispatch queue, so
/// access must be synchronised even though only one handler writes per
/// stream.
private final class DrainState: @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var stdoutBuffer = Data()
    nonisolated(unsafe) private var stderrBuffer = Data()

    nonisolated init() {}

    nonisolated func appendStdout(_ chunk: Data) {
        lock.lock(); defer { lock.unlock() }
        stdoutBuffer.append(chunk)
    }

    nonisolated func appendStderr(_ chunk: Data) {
        lock.lock(); defer { lock.unlock() }
        stderrBuffer.append(chunk)
    }

    nonisolated func snapshot() -> (stdout: Data, stderr: Data) {
        lock.lock(); defer { lock.unlock() }
        return (stdoutBuffer, stderrBuffer)
    }
}

// MARK: - ProcessBox

/// Single-resolution coordination primitive shared by the spawn path,
/// the cancellation handler, and the timeout task.
///
/// All state transitions are funnelled through one `NSLock` so that
/// exactly one outcome reaches the continuation regardless of which
/// path "wins" the race (normal exit, cancellation, timeout).
private final class ProcessBox: @unchecked Sendable {

    enum Outcome {
        case exited(exitCode: Int32, stdout: Data, stderr: Data)
        case cancelled
        case timedOut
    }

    private enum OverrideReason { case cancel, timeout }

    private let lock = NSLock()
    nonisolated(unsafe) private var process: Process?
    nonisolated(unsafe) private var resolved = false
    nonisolated(unsafe) private var cancelled = false
    nonisolated(unsafe) private var pendingOutcome: Outcome?
    nonisolated(unsafe) private var resolutionHandler: (@Sendable (Outcome) -> Void)?
    nonisolated(unsafe) private var overrideReason: OverrideReason?

    nonisolated init() {}

    /// `true` once `cancel()` has been called.
    nonisolated var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return cancelled
    }

    /// Stash the live `Process` so the cancellation/timeout paths can
    /// terminate it.
    nonisolated func attach(process: Process) {
        lock.lock(); defer { lock.unlock() }
        self.process = process
    }

    /// Install the resolution callback. Called exactly once with the
    /// first outcome that arrives; if the outcome already arrived, the
    /// callback fires synchronously.
    nonisolated func onResolved(_ handler: @escaping @Sendable (Outcome) -> Void) {
        lock.lock()
        if let outcome = pendingOutcome {
            pendingOutcome = nil
            lock.unlock()
            handler(outcome)
            return
        }
        resolutionHandler = handler
        lock.unlock()
    }

    /// Normal-exit path called from `terminationHandler`.
    nonisolated func finish(_ outcome: Outcome) {
        deliver(outcome)
    }

    /// Cooperative cancellation. Marks the box and terminates the
    /// child if it has been attached.
    nonisolated func cancel() {
        lock.lock()
        cancelled = true
        if case .none = overrideReason { overrideReason = .cancel }
        let proc = process
        let alreadyResolved = resolved
        lock.unlock()
        if !alreadyResolved {
            proc?.terminate()
        }
        // Do not call deliver(.cancelled) directly: rely on the
        // termination handler to fire after `terminate()`. That keeps
        // pipe drains correct.
    }

    /// Timeout fired. Same protocol as `cancel()` but with `.timedOut`.
    nonisolated func timeout() {
        lock.lock()
        if resolved {
            lock.unlock()
            return
        }
        if case .none = overrideReason { overrideReason = .timeout }
        let proc = process
        lock.unlock()
        proc?.terminate()
    }

    // MARK: Private

    /// Delivers the first outcome to win the race.
    private nonisolated func deliver(_ outcome: Outcome) {
        lock.lock()
        if resolved {
            lock.unlock()
            return
        }
        resolved = true
        // If `cancel()` or `timeout()` ran before normal exit, replace
        // the `.exited` outcome with the matching error so the caller
        // sees the user-meaningful reason.
        let final: Outcome
        switch overrideReason {
        case .cancel:  final = .cancelled
        case .timeout: final = .timedOut
        case .none:    final = outcome
        }
        let handler = resolutionHandler
        resolutionHandler = nil
        if handler == nil {
            pendingOutcome = final
        }
        lock.unlock()
        handler?(final)
    }
}
