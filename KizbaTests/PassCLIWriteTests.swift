//
//  PassCLIWriteTests.swift
//  KizbaTests
//
//  Phase E.5 — deterministic unit tests for the `PassCLI` write
//  methods (`insert`, `generate`, `generateInPlace`, `remove`, `move`).
//
//  Coverage:
//   - Argv exactness for every flag combination per `.ai/plan.md`
//     Phase E.5.
//   - Stdin exact-bytes capture for `insert`.
//   - Default timeouts (15s for write methods, 10s for `remove`).
//   - Env propagation (`PATH` always; `PASSWORD_STORE_DIR`,
//     `GNUPGHOME`, `HOME` when configured).
//   - Error mapping per command context (collision, recipient,
//     length, source-not-found, target-collision).
//   - `generate` stdout parsing through `PassGenerateParser`.
//   - Cancellation propagates through to `PassError.cancelled`.
//
//  Per `.ai/decisions.md` and the phase brief: stdin payloads must
//  never appear in any logger field. We assert their bytes only via
//  `ShellInvocation.stdin == .data(...)` on the captured invocation.
//

import XCTest
@testable import Kizba

final class PassCLIWriteTests: XCTestCase {

    // MARK: - Helpers

    private static let fakePassURL = URL(fileURLWithPath: "/opt/homebrew/bin/pass")

    /// Build a `PassCLI` over an empty-success fake by default. Every
    /// individual test that needs a tailored response builds its own
    /// `FakeShellRunner` and passes it in.
    private func makeCLI(
        runner: FakeShellRunner,
        passwordStoreDir: URL? = nil,
        gnupgHome: URL? = nil,
        pathOverride: String? = nil,
        homeOverride: String? = nil
    ) -> PassCLI {
        PassCLI(
            executable: Self.fakePassURL,
            shellRunner: runner,
            passwordStoreDir: passwordStoreDir,
            gnupgHome: gnupgHome,
            pathOverride: pathOverride,
            homeOverride: homeOverride
        )
    }

    /// Canonical "successful generate" stdout used across the
    /// happy-path tests. Mirrors `pass` 1.7.x plain (non-coloured)
    /// output: banner line followed by the password line.
    private static let generateStdout: String = """
    The generated password for foo/bar is:
    Gen3ratedP@ss
    """

    // MARK: - insert: argv

    func testInsert_noForce_argvIsInsertDashMPath() async throws {
        let runner = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(), stderr: Data())
        )
        let cli = makeCLI(runner: runner)
        let body = Data("payload".utf8)

        try await cli.insert(path: "foo/bar", body: body, force: false)

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.executable, Self.fakePassURL)
        XCTAssertEqual(invocation.arguments, ["insert", "-m", "foo/bar"])
        XCTAssertEqual(invocation.timeout, .seconds(15))
    }

    func testInsert_force_addsForceFlagBeforePath() async throws {
        let runner = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(), stderr: Data())
        )
        let cli = makeCLI(runner: runner)
        let body = Data("payload".utf8)

        try await cli.insert(path: "foo/bar", body: body, force: true)

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["insert", "-m", "-f", "foo/bar"])
    }

    // MARK: - insert: stdin

    func testInsert_stdinPayloadIsCapturedExactly() async throws {
        let runner = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(), stderr: Data())
        )
        let cli = makeCLI(runner: runner)

        let body = "hello\nuser: alice\n".data(using: .utf8)!
        try await cli.insert(path: "foo/bar", body: body, force: false)

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.stdin, .data(body))
        XCTAssertEqual(invocation.stdinByteCount, body.count)
    }

    func testInsert_emptyBody_stillFedAsData() async throws {
        let runner = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(), stderr: Data())
        )
        let cli = makeCLI(runner: runner)

        try await cli.insert(path: "foo/bar", body: Data(), force: false)

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.stdin, .data(Data()))
    }

    // MARK: - generate (commit-new): argv

    func testGenerate_basic_argvIsGeneratePathLength() async throws {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: Self.generateStdout.data(using: .utf8)!,
                stderr: Data()
            )
        )
        let cli = makeCLI(runner: runner)

        _ = try await cli.generate(
            path: "foo/bar",
            length: 24,
            noSymbols: false,
            force: false
        )

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["generate", "foo/bar", "24"])
        XCTAssertEqual(invocation.stdin, .none)
        XCTAssertEqual(invocation.timeout, .seconds(15))
    }

    func testGenerate_noSymbols_addsDashN() async throws {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: Self.generateStdout.data(using: .utf8)!,
                stderr: Data()
            )
        )
        let cli = makeCLI(runner: runner)

        _ = try await cli.generate(
            path: "foo/bar",
            length: 24,
            noSymbols: true,
            force: false
        )

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["generate", "-n", "foo/bar", "24"])
    }

    func testGenerate_force_addsDashF() async throws {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: Self.generateStdout.data(using: .utf8)!,
                stderr: Data()
            )
        )
        let cli = makeCLI(runner: runner)

        _ = try await cli.generate(
            path: "foo/bar",
            length: 24,
            noSymbols: false,
            force: true
        )

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["generate", "-f", "foo/bar", "24"])
    }

    func testGenerate_forceAndNoSymbols_orderIsForceThenNoSymbols() async throws {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: Self.generateStdout.data(using: .utf8)!,
                stderr: Data()
            )
        )
        let cli = makeCLI(runner: runner)

        _ = try await cli.generate(
            path: "foo/bar",
            length: 24,
            noSymbols: true,
            force: true
        )

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["generate", "-f", "-n", "foo/bar", "24"])
    }

    // MARK: - generateInPlace: argv

    func testGenerateInPlace_basic_argvIncludesInPlaceFlag() async throws {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: Self.generateStdout.data(using: .utf8)!,
                stderr: Data()
            )
        )
        let cli = makeCLI(runner: runner)

        _ = try await cli.generateInPlace(
            path: "foo/bar",
            length: 24,
            noSymbols: false
        )

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["generate", "--in-place", "foo/bar", "24"])
        XCTAssertEqual(invocation.stdin, .none)
        XCTAssertEqual(invocation.timeout, .seconds(15))
    }

    func testGenerateInPlace_noSymbols_addsDashNBeforeInPlace() async throws {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: Self.generateStdout.data(using: .utf8)!,
                stderr: Data()
            )
        )
        let cli = makeCLI(runner: runner)

        _ = try await cli.generateInPlace(
            path: "foo/bar",
            length: 24,
            noSymbols: true
        )

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["generate", "-n", "--in-place", "foo/bar", "24"])
    }

    // MARK: - remove: argv

    func testRemove_argvIsRmDashFPath() async throws {
        let runner = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(), stderr: Data())
        )
        let cli = makeCLI(runner: runner)

        try await cli.remove(path: "foo/bar")

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["rm", "-f", "foo/bar"])
        XCTAssertEqual(invocation.stdin, .none)
        XCTAssertEqual(invocation.timeout, .seconds(10))
    }

    // MARK: - move: argv

    func testMove_noForce_argvIsMvFromTo() async throws {
        let runner = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(), stderr: Data())
        )
        let cli = makeCLI(runner: runner)

        try await cli.move(from: "a/b", to: "c/d", force: false)

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["mv", "a/b", "c/d"])
        XCTAssertEqual(invocation.stdin, .none)
        XCTAssertEqual(invocation.timeout, .seconds(15))
    }

    func testMove_force_addsDashFBeforeFrom() async throws {
        let runner = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(), stderr: Data())
        )
        let cli = makeCLI(runner: runner)

        try await cli.move(from: "a/b", to: "c/d", force: true)

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["mv", "-f", "a/b", "c/d"])
    }

    // MARK: - Env propagation

    func testInsert_environmentIncludesAllConfiguredOverrides() async throws {
        let runner = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(), stderr: Data())
        )
        let storeDir = URL(fileURLWithPath: "/private/tmp/store")
        let gnupgHome = URL(fileURLWithPath: "/private/tmp/gnupg")
        let pathOverride = "/private/tmp/bin:/usr/bin"
        let homeOverride = "/private/tmp/home"

        let cli = makeCLI(
            runner: runner,
            passwordStoreDir: storeDir,
            gnupgHome: gnupgHome,
            pathOverride: pathOverride,
            homeOverride: homeOverride
        )

        try await cli.insert(path: "foo/bar", body: Data("x".utf8), force: false)

        let env = try XCTUnwrap(runner.lastInvocation).environment
        XCTAssertEqual(env["PATH"], pathOverride)
        XCTAssertEqual(env["PASSWORD_STORE_DIR"], storeDir.path)
        XCTAssertEqual(env["GNUPGHOME"], gnupgHome.path)
        XCTAssertEqual(env["HOME"], homeOverride)
    }

    func testGenerate_environmentDefaultsPATHWhenNoOverridesSupplied() async throws {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: Self.generateStdout.data(using: .utf8)!,
                stderr: Data()
            )
        )
        let cli = makeCLI(runner: runner)

        _ = try await cli.generate(path: "foo/bar", length: 24, noSymbols: false, force: false)

        let env = try XCTUnwrap(runner.lastInvocation).environment
        XCTAssertEqual(env["PATH"], PassCLI.defaultPATH)
        XCTAssertNil(env["PASSWORD_STORE_DIR"])
        XCTAssertNil(env["GNUPGHOME"])
    }

    func testRemove_environmentIncludesPasswordStoreDirOverride() async throws {
        let runner = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(), stderr: Data())
        )
        let storeDir = URL(fileURLWithPath: "/private/tmp/store")
        let cli = makeCLI(runner: runner, passwordStoreDir: storeDir)

        try await cli.remove(path: "foo/bar")

        let env = try XCTUnwrap(runner.lastInvocation).environment
        XCTAssertEqual(env["PASSWORD_STORE_DIR"], storeDir.path)
    }

    func testMove_environmentIncludesGnupgHomeOverride() async throws {
        let runner = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(), stderr: Data())
        )
        let gnupg = URL(fileURLWithPath: "/private/tmp/gnupg")
        let cli = makeCLI(runner: runner, gnupgHome: gnupg)

        try await cli.move(from: "a/b", to: "c/d", force: false)

        let env = try XCTUnwrap(runner.lastInvocation).environment
        XCTAssertEqual(env["GNUPGHOME"], gnupg.path)
    }

    // MARK: - Error mapping per command context

    func testInsert_alreadyExistsStderr_throwsEntryAlreadyExists() async {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 1,
                stdout: Data(),
                stderr: Data("Error: foo/bar already exists.\n".utf8)
            )
        )
        let cli = makeCLI(runner: runner)

        do {
            try await cli.insert(path: "foo/bar", body: Data("x".utf8), force: false)
            XCTFail("Expected entryAlreadyExists")
        } catch PassError.entryAlreadyExists(let path) {
            XCTAssertEqual(path, "foo/bar")
        } catch {
            XCTFail("Expected entryAlreadyExists, got \(error)")
        }
    }

    func testGenerate_invalidLengthStderr_throwsInvalidLength() async {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 1,
                stdout: Data(),
                stderr: Data("Error: pass-length \"abc\" must be a positive integer.\n".utf8)
            )
        )
        let cli = makeCLI(runner: runner)

        do {
            _ = try await cli.generate(path: "foo/bar", length: 0, noSymbols: false, force: false)
            XCTFail("Expected invalidLength")
        } catch PassError.invalidLength {
            // ok
        } catch {
            XCTFail("Expected invalidLength, got \(error)")
        }
    }

    func testRemove_missingEntryStderr_throwsSourceNotFound() async {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 1,
                stdout: Data(),
                stderr: Data("Error: foo/bar is not in the password store.\n".utf8)
            )
        )
        let cli = makeCLI(runner: runner)

        do {
            try await cli.remove(path: "foo/bar")
            XCTFail("Expected sourceNotFound")
        } catch PassError.sourceNotFound(let path) {
            XCTAssertEqual(path, "foo/bar")
        } catch {
            XCTFail("Expected sourceNotFound, got \(error)")
        }
    }

    func testMove_sourceMissingStderr_throwsSourceNotFound() async {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 1,
                stdout: Data(),
                stderr: Data("Error: a/b is not in the password store.\n".utf8)
            )
        )
        let cli = makeCLI(runner: runner)

        do {
            try await cli.move(from: "a/b", to: "c/d", force: false)
            XCTFail("Expected sourceNotFound")
        } catch PassError.sourceNotFound(let path) {
            XCTAssertEqual(path, "a/b")
        } catch {
            XCTFail("Expected sourceNotFound, got \(error)")
        }
    }

    func testMove_targetCollisionStderr_throwsEntryAlreadyExists() async {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 1,
                stdout: Data(),
                stderr: Data("mv: refusing to overwrite '/store/.password-store/c/d.gpg'\n".utf8)
            )
        )
        let cli = makeCLI(runner: runner)

        do {
            try await cli.move(from: "a/b", to: "c/d", force: false)
            XCTFail("Expected entryAlreadyExists")
        } catch PassError.entryAlreadyExists(let path) {
            XCTAssertEqual(path, "c/d")
        } catch {
            XCTFail("Expected entryAlreadyExists, got \(error)")
        }
    }

    func testInsert_recipientNotFoundStderr_throwsRecipientNotFound() async {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 2,
                stdout: Data(),
                stderr: Data("gpg: alice@example.com: skipped: No public key\n".utf8)
            )
        )
        let cli = makeCLI(runner: runner)

        do {
            try await cli.insert(path: "foo/bar", body: Data("x".utf8), force: false)
            XCTFail("Expected recipientNotFound")
        } catch PassError.recipientNotFound(let id) {
            XCTAssertEqual(id, "alice@example.com")
        } catch {
            XCTFail("Expected recipientNotFound, got \(error)")
        }
    }

    // MARK: - generate stdout parsing

    func testGenerate_happyPath_returnsParsedPassword() async throws {
        let stdout = """
        The generated password for foo/bar is:
        Gen3ratedP@ss
        """
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: stdout.data(using: .utf8)!,
                stderr: Data()
            )
        )
        let cli = makeCLI(runner: runner)

        let password = try await cli.generate(
            path: "foo/bar",
            length: 24,
            noSymbols: false,
            force: false
        )

        let expected = try PassGenerateParser.parse(stdout)
        XCTAssertEqual(password, expected)
        XCTAssertEqual(password, "Gen3ratedP@ss")
    }

    func testGenerateInPlace_happyPath_returnsParsedPassword() async throws {
        // `pass generate --in-place` shares the same stdout shape;
        // verify the parser is wired the same way.
        let stdout = """
        The generated password for foo/bar is:
        InPlace#Pass2026
        """
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: stdout.data(using: .utf8)!,
                stderr: Data()
            )
        )
        let cli = makeCLI(runner: runner)

        let password = try await cli.generateInPlace(
            path: "foo/bar",
            length: 16,
            noSymbols: false
        )

        XCTAssertEqual(password, "InPlace#Pass2026")
    }

    // MARK: - Cancellation

    func testInsert_cancellation_propagatesPassErrorCancelled() async throws {
        // Long-delay fake; cancel before it fires. The fake honours
        // Task cancellation by translating it into PassError.cancelled,
        // mirroring `ProcessShellRunner`.
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 0, stdout: Data(), stderr: Data(),
                delay: .seconds(5)
            )
        )
        let cli = makeCLI(runner: runner)

        let task = Task {
            try await cli.insert(path: "foo/bar", body: Data("x".utf8), force: false)
        }

        try await Task.sleep(for: .milliseconds(50))
        task.cancel()

        do {
            try await task.value
            XCTFail("Expected PassError.cancelled")
        } catch PassError.cancelled {
            // ok
        } catch is CancellationError {
            // Acceptable race outcome — see PassCLITests for context.
        } catch {
            XCTFail("Expected PassError.cancelled, got \(error)")
        }
    }
}
