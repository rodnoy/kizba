//
//  ProcessShellRunnerStdinTests.swift
//  KizbaTests
//
//  Phase E.2 — verifies the production stdin pipe path of
//  `ProcessShellRunner`. All tests use absolute paths to system
//  binaries (`/bin/cat`, `/bin/sh`) guaranteed present on every macOS
//  host. Covers:
//
//   - Round-trip: bytes written to stdin must reach stdout via `cat`.
//   - Large payloads: 10 MB through `cat` without pipe-buffer deadlock
//     (proves the stdin write task runs concurrently with the
//     stdout/stderr drain).
//   - `closeImmediately`: empty stdin path produces empty echo.
//   - Cancellation mid-write: the wrapping `Task.cancel()` terminates
//     the child quickly and surfaces ``PassError/cancelled``.
//   - Logger / Diagnostics never see the payload — only
//     ``Invocation/stdinByteCount``.
//   - Cross-actor invocation works from a `Task.detached` (Sendable
//     contract).
//

import XCTest
@testable import Kizba

final class ProcessShellRunnerStdinTests: XCTestCase {

    private let cat = URL(fileURLWithPath: "/bin/cat")
    private let sh = URL(fileURLWithPath: "/bin/sh")

    // MARK: - Basic stdin round-trip

    func testStdinEchoViaCat() async throws {
        let runner = ProcessShellRunner()
        let payload = "hello\nworld\n".data(using: .utf8)!

        let invocation = ShellInvocation(
            executable: cat,
            arguments: [],
            environment: [:],
            stdin: .data(payload),
            timeout: .seconds(5)
        )

        let result = try await runner.run(invocation)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput, payload, "cat must echo stdin verbatim")
        XCTAssertTrue(result.standardError.isEmpty)
    }

    // MARK: - Large stdin (no pipe-buffer deadlock)

    /// 10 MB through `cat`. The classic `Foundation.Process` mistake is
    /// to write stdin synchronously while also draining stdout — the
    /// child's stdout pipe fills up, the parent's stdin write blocks,
    /// and the whole thing deadlocks. The runner avoids this by
    /// running the stdin writer on a detached task in parallel with
    /// the readability-handler-driven stdout/stderr drain.
    func testLargeStdinViaCat_noDeadlock() async throws {
        let runner = ProcessShellRunner()

        // 10 MB of pseudo-random-ish bytes (deterministic for replay).
        let size = 10 * 1024 * 1024
        var payload = Data(count: size)
        payload.withUnsafeMutableBytes { raw in
            let bytes = raw.bindMemory(to: UInt8.self)
            for i in 0..<size {
                bytes[i] = UInt8(truncatingIfNeeded: i &* 0x9E_37 &+ 0x5A)
            }
        }

        let invocation = ShellInvocation(
            executable: cat,
            arguments: [],
            environment: [:],
            stdin: .data(payload),
            timeout: .seconds(30)
        )

        let result = try await runner.run(invocation)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(
            result.standardOutput.count, size,
            "Expected exact byte-count round-trip for 10 MB stdin"
        )
        XCTAssertEqual(
            result.standardOutput, payload,
            "Expected byte-for-byte fidelity through stdin → cat → stdout"
        )
    }

    // MARK: - closeImmediately

    func testCloseImmediatelyProducesEmptyEcho() async throws {
        let runner = ProcessShellRunner()

        let invocation = ShellInvocation(
            executable: cat,
            arguments: [],
            environment: [:],
            stdin: .closeImmediately,
            timeout: .seconds(5)
        )

        let result = try await runner.run(invocation)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(
            result.standardOutput.isEmpty,
            "cat with closed stdin must produce no output"
        )
    }

    // MARK: - Cancellation mid-write

    /// A long-running child reading stdin. Cancelling the wrapping
    /// task must terminate the process within seconds and surface
    /// ``PassError/cancelled``. The stdin write task observes the
    /// broken pipe and exits cleanly without crashing.
    func testCancellationMidWrite() async throws {
        let runner = ProcessShellRunner()

        // Modest payload — large enough that a 200 ms cancellation
        // lands while the writer is still alive, but small enough to
        // avoid stressing the macOS pipe buffers in CI.
        let payload = Data(repeating: 0x41, count: 256_000)

        let invocation = ShellInvocation(
            executable: sh,
            arguments: ["-c", "sleep 5; cat"],
            environment: [:],
            stdin: .data(payload),
            timeout: .seconds(30)
        )

        let start = ContinuousClock.now
        let task = Task { try await runner.run(invocation) }
        try await Task.sleep(for: .milliseconds(200))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected PassError.cancelled")
        } catch PassError.cancelled {
            let elapsed = ContinuousClock.now - start
            XCTAssertLessThan(
                elapsed, .seconds(3),
                "Cancellation should terminate the child quickly"
            )
        } catch is CancellationError {
            // Acceptable race outcome — same as for the existing
            // cancellation test in `ProcessShellRunnerTests`.
            let elapsed = ContinuousClock.now - start
            XCTAssertLessThan(elapsed, .seconds(3))
        } catch {
            XCTFail("Expected PassError.cancelled, got \(error)")
        }
    }

    // MARK: - Logger / Diagnostics never see payload bytes

    /// Run with a known sentinel string in stdin. The published
    /// ``Invocation`` must record ``Invocation/stdinByteCount`` equal
    /// to the payload length, but no field on the record may contain
    /// the sentinel (executable, args, stderr excerpt, anything that
    /// `String(describing:)` would surface).
    func testInvocationRecordContainsByteCountButNotPayload() async throws {
        let log = InvocationLog()
        let runner = ProcessShellRunner(invocationLog: log)

        let sentinel = "ULTRA_SECRET_VALUE_42"
        let payload = sentinel.data(using: .utf8)!

        let invocation = ShellInvocation(
            executable: cat,
            arguments: [],
            environment: [:],
            stdin: .data(payload),
            timeout: .seconds(5)
        )

        let result = try await runner.run(invocation)
        XCTAssertEqual(result.exitCode, 0)

        // Poll for the published record (sink writes are detached).
        var recorded: [Invocation] = []
        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while ContinuousClock.now < deadline {
            recorded = await log.recent()
            if !recorded.isEmpty { break }
            try? await Task.sleep(for: .milliseconds(20))
        }

        XCTAssertEqual(recorded.count, 1, "Expected exactly one invocation record")
        let record = try XCTUnwrap(recorded.first)

        XCTAssertEqual(record.stdinByteCount, payload.count)

        // Sentinel must not appear anywhere in the publishable fields.
        XCTAssertFalse(record.executable.contains(sentinel))
        for arg in record.args {
            XCTAssertFalse(arg.contains(sentinel), "Argument leaked sentinel: \(arg)")
        }
        XCTAssertFalse(record.stderrExcerpt.contains(sentinel))
        // Defensive catch-all: full mirror dump must not contain it
        // either (nothing else holds the bytes by design).
        XCTAssertFalse(
            String(describing: record).contains(sentinel),
            "Mirror representation of Invocation leaked sentinel"
        )
    }

    // MARK: - Sendable / detached invocation

    /// Spawning the runner from a `Task.detached` exercises the
    /// `Sendable` contract on ``ShellInvocation`` and confirms no
    /// implicit MainActor isolation leaks into the call path.
    func testRunFromDetachedTask() async throws {
        let runner = ProcessShellRunner()
        let payload = Data("from-detached\n".utf8)

        let result = try await Task.detached { () -> ShellResult in
            let invocation = ShellInvocation(
                executable: URL(fileURLWithPath: "/bin/cat"),
                arguments: [],
                environment: [:],
                stdin: .data(payload),
                timeout: .seconds(5)
            )
            return try await runner.run(invocation)
        }.value

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput, payload)
    }
}
