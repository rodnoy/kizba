//
//  FakeShellRunner.swift
//  KizbaTests
//
//  Canonical `ShellCommandRunning` test double for MVP 2 write-side
//  tests. Captures every invocation (executable, arguments,
//  environment, timeout) and replays a programmed sequence of
//  responses. Honours Task cancellation by translating it into
//  ``PassError/cancelled`` — mirroring the production
//  ``ProcessShellRunner`` contract so `PassCLI` exercises the same
//  code path.
//
//  ## Concurrency
//
//  The fake is `final class` (mutable state) and `@unchecked Sendable`
//  via an internal `NSLock`, because `ShellCommandRunning` is itself a
//  `Sendable` protocol and the runner is invoked from arbitrary actor
//  contexts. All state mutations happen under the lock.
//
//  ## Defaults
//
//  Default-init returns a runner that succeeds once with empty output.
//  Callers either pass a single ``Response`` (back-compat with the
//  inline fakes that previously lived inside `PassCLITests`) or push
//  multiple scripted responses ahead of time via ``script(_:)`` /
//  ``push(_:)``. Once the script is exhausted the runner replays the
//  last response indefinitely; this matches the documented
//  "happy path = succeed once" promise.
//

import Foundation
@testable import Kizba

/// Deterministic ``ShellCommandRunning`` test double. Records every
/// call and replays scripted responses in FIFO order.
final class FakeShellRunner: ShellCommandRunning, @unchecked Sendable {

    /// Snapshot of one `run(...)` call as observed by the fake.
    struct Invocation: Sendable, Equatable {
        let executable: URL
        let arguments: [String]
        let environment: [String: String]
        let timeout: Duration
    }

    /// Programmed response for a single `run(...)` call.
    enum Response: Sendable {
        /// Return a `ShellResult` (optionally after a delay).
        case success(exitCode: Int32, stdout: Data, stderr: Data, delay: Duration = .zero)
        /// Throw a `PassError` after the given delay.
        case throwing(error: PassError, after: Duration = .zero)
    }

    private let lock = NSLock()
    private var invocations: [Invocation] = []
    private var responses: [Response] = []

    // MARK: - Init

    /// Empty default: a single happy-path success with no payload.
    init() {
        self.responses = [.success(exitCode: 0, stdout: Data(), stderr: Data())]
    }

    /// Convenience initialiser matching the call sites that previously
    /// declared an inline `FakeShellRunner(response:)`. Wraps the
    /// supplied response in the script.
    convenience init(response: Response) {
        self.init()
        self.responses = [response]
    }

    /// Compatibility initialiser supporting the old `(response:delay:)`
    /// shape used by `PassCLITests`. Folds the explicit `delay` into a
    /// `.success(...)` response.
    convenience init(response: Response, delay: Duration) {
        self.init()
        switch response {
        case .success(let code, let out, let err, let existing):
            // Caller's `delay` argument wins over any embedded value.
            _ = existing
            self.responses = [.success(exitCode: code, stdout: out, stderr: err, delay: delay)]
        case .throwing(let error, _):
            self.responses = [.throwing(error: error, after: delay)]
        }
    }

    // MARK: - Scripting

    /// Replaces the response queue with the supplied script.
    func script(_ responses: [Response]) {
        lock.lock(); defer { lock.unlock() }
        self.responses = responses
    }

    /// Appends a single response to the queue.
    func push(_ response: Response) {
        lock.lock(); defer { lock.unlock() }
        responses.append(response)
    }

    // MARK: - Inspection

    /// All invocations recorded so far, in order.
    var allInvocations: [Invocation] {
        lock.lock(); defer { lock.unlock() }
        return invocations
    }

    /// Most recent invocation, if any.
    var lastInvocation: Invocation? {
        lock.lock(); defer { lock.unlock() }
        return invocations.last
    }

    /// Number of recorded invocations (cheap snapshot for assertions).
    var invocationCount: Int {
        lock.lock(); defer { lock.unlock() }
        return invocations.count
    }

    // MARK: - ShellCommandRunning

    func run(
        executable: URL,
        arguments: [String],
        environment: [String: String],
        timeout: Duration
    ) async throws -> ShellResult {
        let invocation = Invocation(
            executable: executable,
            arguments: arguments,
            environment: environment,
            timeout: timeout
        )

        // Pop the next response (or replay the last one if exhausted).
        let response: Response = {
            lock.lock(); defer { lock.unlock() }
            invocations.append(invocation)
            if responses.count > 1 {
                return responses.removeFirst()
            }
            // Single (or last) response is replayed indefinitely so
            // tests that fire multiple shell calls without scripting
            // each one still get deterministic behaviour.
            return responses.first ?? .success(
                exitCode: 0, stdout: Data(), stderr: Data()
            )
        }()

        let activeDelay: Duration
        switch response {
        case .success(_, _, _, let d): activeDelay = d
        case .throwing(_, let d):      activeDelay = d
        }

        if activeDelay > .zero {
            do {
                try await Task.sleep(for: activeDelay)
            } catch {
                throw PassError.cancelled
            }
        } else {
            // Even with no delay, give cancellation a chance to fire
            // for tests that race a `cancel()` against a fast reply.
            try Task.checkCancellation()
        }

        switch response {
        case .success(let code, let out, let err, _):
            return ShellResult(exitCode: code, standardOutput: out, standardError: err)
        case .throwing(let error, _):
            throw error
        }
    }
}
