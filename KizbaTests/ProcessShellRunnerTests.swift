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

    // MARK: - Environment composition

    /// The supplied environment dictionary must reach the child verbatim.
    /// `pass` invocation depends on `PASSWORD_STORE_DIR` / `GNUPGHOME`
    /// reaching `gpg` exactly, so this is a contractual property.
    func testEnvironmentVariablesAreForwardedToChild() async throws {
        let runner = ProcessShellRunner()
        let result = try await runner.run(
            executable: sh,
            arguments: ["-c", "printf %s \"$KIZBA_TEST_VAR\""],
            environment: ["KIZBA_TEST_VAR": "kizba-marker-42"],
            timeout: .seconds(5)
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(
            String(data: result.standardOutput, encoding: .utf8),
            "kizba-marker-42",
            "Child must observe the env var verbatim"
        )
    }

    /// An empty environment dictionary must not inherit the parent's
    /// environment. `Process.environment = [:]` yields a child whose
    /// environment is empty; this pins that contract so callers
    /// (`PassCLI`) can reason about PATH composition explicitly.
    func testEmptyEnvironmentIsNotInheritedFromParent() async throws {
        let runner = ProcessShellRunner()
        // Set a marker in the parent that, if leaked, would appear in stdout.
        setenv("KIZBA_PARENT_LEAK", "should-not-appear", 1)
        defer { unsetenv("KIZBA_PARENT_LEAK") }

        let result = try await runner.run(
            executable: sh,
            arguments: ["-c", "printf %s \"${KIZBA_PARENT_LEAK-unset}\""],
            environment: [:],
            timeout: .seconds(5)
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(
            String(data: result.standardOutput, encoding: .utf8),
            "unset",
            "Parent env must not leak into child when environment is empty"
        )
    }

    // MARK: - Arguments forwarding

    /// Each argument is delivered as a discrete argv entry — no shell
    /// re-parsing, no whitespace splitting. Critical for entry paths
    /// like `Personal/Email Account` that contain spaces.
    func testArgumentsAreForwardedAsDiscreteArgvEntries() async throws {
        let runner = ProcessShellRunner()
        let result = try await runner.run(
            executable: echo,
            arguments: ["one two", "three"],
            environment: [:],
            timeout: .seconds(5)
        )

        XCTAssertEqual(result.exitCode, 0)
        // `/bin/echo` joins argv with a single space and appends `\n`.
        // If "one two" had been re-split, output would have three tokens
        // separated by single spaces — same string here, so additionally
        // assert via a sentinel that contains multiple spaces.
        XCTAssertEqual(
            String(data: result.standardOutput, encoding: .utf8),
            "one two three\n"
        )
    }

    func testArgumentWithEmbeddedDoubleSpacesIsPreservedAsSingleArgv() async throws {
        let runner = ProcessShellRunner()
        // Use `printf %s` so the runtime echoes the *first* argv entry
        // verbatim with no separator, proving it was not split.
        let result = try await runner.run(
            executable: sh,
            arguments: ["-c", "printf %s \"$1\"", "sh", "a  b  c"],
            environment: [:],
            timeout: .seconds(5)
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(
            String(data: result.standardOutput, encoding: .utf8),
            "a  b  c",
            "Embedded multiple spaces must survive round-trip through argv"
        )
    }

    // MARK: - Spawn failure

    /// A non-existent executable URL must surface as `PassError.shellFailure`
    /// with `exitCode == -1` — the stable contract documented in
    /// `ProcessShellRunner.swift`. This is the path `BinaryDiscoveryService`
    /// callers will hit if a stale override points at a deleted binary.
    func testSpawnFailureForMissingExecutable() async throws {
        let runner = ProcessShellRunner()
        let missing = URL(fileURLWithPath: "/nonexistent/kizba-definitely-not-here-\(UUID().uuidString)")

        do {
            _ = try await runner.run(
                executable: missing,
                arguments: [],
                environment: [:],
                timeout: .seconds(5)
            )
            XCTFail("Expected PassError.shellFailure for missing executable")
        } catch PassError.shellFailure(let exitCode, let stderrExcerpt) {
            XCTAssertEqual(exitCode, -1, "Spawn-time failure must use the documented sentinel exit code")
            XCTAssertEqual(stderrExcerpt, "spawn failed")
        } catch {
            XCTFail("Expected PassError.shellFailure, got \(error)")
        }
    }

    /// `pass` callers will pass a bare name like "pass" only if the
    /// discovery service failed to resolve it. The runner deliberately
    /// requires absolute URLs and does not consult PATH on its own —
    /// this test pins that behaviour by using a non-absolute file URL
    /// component that cannot be resolved as an executable.
    func testRelativeExecutableNotResolvedViaPATH() async throws {
        let runner = ProcessShellRunner()
        // `URL(fileURLWithPath:)` resolves against CWD, so pick a name
        // that cannot exist in any plausible working directory.
        let bareName = URL(fileURLWithPath: "kizba-not-a-real-binary-\(UUID().uuidString)")

        do {
            _ = try await runner.run(
                executable: bareName,
                arguments: [],
                environment: ["PATH": "/usr/bin:/bin"],
                timeout: .seconds(5)
            )
            XCTFail("Expected PassError.shellFailure — runner must not consult PATH")
        } catch PassError.shellFailure(let exitCode, _) {
            XCTAssertEqual(exitCode, -1)
        } catch {
            XCTFail("Expected PassError.shellFailure, got \(error)")
        }
    }
}
