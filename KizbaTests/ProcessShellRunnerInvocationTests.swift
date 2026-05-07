//
//  ProcessShellRunnerInvocationTests.swift
//  KizbaTests
//
//  Verifies that `ProcessShellRunner` publishes one ``Invocation``
//  per call to its injected ``InvocationLog`` sink — for success,
//  non-zero exit, timeout, and cancellation paths (Phase 8.4).
//

import XCTest
@testable import Kizba

final class ProcessShellRunnerInvocationTests: XCTestCase {

    private let echo = URL(fileURLWithPath: "/bin/echo")
    private let sleepBin = URL(fileURLWithPath: "/bin/sleep")

    /// Detached tasks publish to the actor; poll briefly so tests stay
    /// deterministic without sprinkling arbitrary `sleep`s.
    private func waitForCount(_ log: InvocationLog, atLeast: Int, timeout: Duration = .seconds(2)) async -> [Invocation] {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            let snapshot = await log.recent()
            if snapshot.count >= atLeast {
                return snapshot
            }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return await log.recent()
    }

    func testSuccessfulRunPublishesInvocation() async throws {
        let log = InvocationLog()
        let runner = ProcessShellRunner(invocationLog: log)

        let result = try await runner.run(
            executable: echo,
            arguments: ["hello"],
            environment: [:],
            timeout: .seconds(5)
        )
        XCTAssertEqual(result.exitCode, 0)

        let recent = await waitForCount(log, atLeast: 1)
        XCTAssertEqual(recent.count, 1)

        let invocation = try XCTUnwrap(recent.first)
        XCTAssertEqual((invocation.executable as NSString).lastPathComponent, "echo")
        XCTAssertEqual(invocation.args, ["hello"])
        XCTAssertEqual(invocation.exitCode, 0)
        XCTAssertEqual(invocation.stderrExcerpt, "")
        XCTAssertGreaterThanOrEqual(invocation.duration, 0)
    }

    func testTimeoutPublishesInvocation() async {
        let log = InvocationLog()
        let runner = ProcessShellRunner(invocationLog: log)

        do {
            _ = try await runner.run(
                executable: sleepBin,
                arguments: ["5"],
                environment: [:],
                timeout: .milliseconds(100)
            )
            XCTFail("Expected timeout")
        } catch let error as PassError {
            XCTAssertEqual(error, PassError.timedOut)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let recent = await waitForCount(log, atLeast: 1)
        XCTAssertEqual(recent.count, 1)
        let invocation = try? XCTUnwrap(recent.first)
        // Timeout sentinel exit code is -3 in the runner.
        XCTAssertEqual(invocation?.exitCode, -3)
        XCTAssertEqual(invocation?.stderrExcerpt, "timed out")
    }

    func testCancelPublishesInvocation() async {
        let log = InvocationLog()
        let runner = ProcessShellRunner(invocationLog: log)

        let task = Task {
            try await runner.run(
                executable: sleepBin,
                arguments: ["5"],
                environment: [:],
                timeout: .seconds(10)
            )
        }
        // Give the child a moment to actually start.
        try? await Task.sleep(for: .milliseconds(80))
        task.cancel()
        _ = try? await task.value

        let recent = await waitForCount(log, atLeast: 1)
        XCTAssertEqual(recent.count, 1)
        let invocation = recent.first
        // Cancellation sentinel exit code is -2 in the runner.
        XCTAssertEqual(invocation?.exitCode, -2)
        XCTAssertEqual(invocation?.stderrExcerpt, "cancelled")
    }
}
