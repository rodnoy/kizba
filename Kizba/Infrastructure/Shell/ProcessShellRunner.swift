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

    public nonisolated init() {}

    public nonisolated func run(
        executable: URL,
        arguments: [String],
        environment: [String: String],
        timeout: Duration
    ) async throws -> ShellResult {

        let box = ProcessBox()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ShellResult, Error>) in
                Self.spawn(
                    executable: executable,
                    arguments: arguments,
                    environment: environment,
                    timeout: timeout,
                    box: box,
                    continuation: continuation
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
        executable: URL,
        arguments: [String],
        environment: [String: String],
        timeout: Duration,
        box: ProcessBox,
        continuation: CheckedContinuation<ShellResult, Error>
    ) {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        process.standardInput = FileHandle.nullDevice

        let drain = DrainState()

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

            switch outcome {
            case .exited(let exitCode, let stdout, let stderr):
                Log.shell.info(
                    "shell exit: exe=\(exePath, privacy: .private) argc=\(argc, privacy: .public) status=\(exitCode, privacy: .public) stderrBytes=\(stderr.count, privacy: .public)"
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
}

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
