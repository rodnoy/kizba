//
//  ProcessShellRunnerTests.swift
//  KizbaTests
//
//  Deterministic unit tests for `ProcessShellRunner`. All tests use
//  absolute paths to system binaries that are guaranteed present on
//  every macOS host (`/bin/echo`, `/usr/bin/false`, `/bin/sleep`,
//  `/bin/sh`). No network, no fixtures on disk.
//

import XCTest
@testable import Kizba

final class ProcessShellRunnerTests: XCTestCase {

    private let echo = URL(fileURLWithPath: "/bin/echo")
    private let falseBin = URL(fileURLWithPath: "/usr/bin/false")
    private let sh = URL(fileURLWithPath: "/bin/sh")
    private let sleepBin = URL(fileURLWithPath: "/bin/sleep")

    // MARK: - Success path

    func testEchoSuccess() async throws {
        let runner = ProcessShellRunner()
        let result = try await runner.run(
            executable: echo,
            arguments: ["hello"],
            environment: [:],
            timeout: .seconds(5)
        )

        XCTAssertEqual(result.exitCode, 0)
        // `/bin/echo hello` writes "hello\n".
        XCTAssertEqual(String(data: result.standardOutput, encoding: .utf8), "hello\n")
        XCTAssertTrue(result.standardError.isEmpty)
    }

    // MARK: - Non-zero exit

    func testNonZeroExit() async throws {
        let runner = ProcessShellRunner()
        let result = try await runner.run(
            executable: falseBin,
            arguments: [],
            environment: [:],
            timeout: .seconds(5)
        )

        // The protocol surfaces non-zero exits as a successful
        // ShellResult — error mapping happens one layer up in PassCLI.
        XCTAssertNotEqual(result.exitCode, 0)
        XCTAssertTrue(result.standardOutput.isEmpty)
    }

    // MARK: - Timeout

    func testTimeoutTerminatesProcess() async throws {
        let runner = ProcessShellRunner()
        let start = ContinuousClock.now

        do {
            _ = try await runner.run(
                executable: sleepBin,
                arguments: ["5"],
                environment: [:],
                timeout: .milliseconds(200)
            )
            XCTFail("Expected timedOut error")
        } catch PassError.timedOut {
            let elapsed = ContinuousClock.now - start
            // Should resolve well before the 5s sleep would naturally end.
            XCTAssertLessThan(elapsed, .seconds(2), "Timeout did not terminate the child quickly enough")
        } catch {
            XCTFail("Expected PassError.timedOut, got \(error)")
        }
    }

    // MARK: - Cancellation

    func testCancellationPropagates() async throws {
        let runner = ProcessShellRunner()
        let start = ContinuousClock.now

        let task = Task {
            try await runner.run(
                executable: sleepBin,
                arguments: ["5"],
                environment: [:],
                timeout: .seconds(30)
            )
        }

        // Give the child a moment to actually start before we cancel.
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation error")
        } catch PassError.cancelled {
            let elapsed = ContinuousClock.now - start
            XCTAssertLessThan(elapsed, .seconds(2), "Cancellation did not terminate the child quickly enough")
        } catch is CancellationError {
            // Acceptable alternative if Swift's structured cancellation
            // races ahead — process must still have been killed.
            let elapsed = ContinuousClock.now - start
            XCTAssertLessThan(elapsed, .seconds(2))
        } catch {
            XCTFail("Expected PassError.cancelled, got \(error)")
        }
    }

    // MARK: - Large stdout drain

    func testLargeStdoutDrain() async throws {
        let runner = ProcessShellRunner()
        // ~200 KB of 'x' characters. `head -c 200000` is exactly 200000.
        let result = try await runner.run(
            executable: sh,
            arguments: ["-c", "yes x | head -c 200000"],
            environment: [:],
            timeout: .seconds(10)
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput.count, 200_000,
                       "Expected exactly 200000 bytes drained without deadlock")
    }
}
