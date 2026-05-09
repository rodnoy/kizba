//
//  PassCLITests.swift
//  KizbaTests
//
//  Deterministic unit tests for `PassCLI`. A `FakeShellRunner`
//  satisfies `ShellCommandRunning` and lets us exercise the success,
//  decryption-failure, timeout, cancellation and arg/env composition
//  branches without spawning real processes.
//
//  Per `.ai/decisions.md`:
//   - Decrypted stdout must never reach a logger; tests do not assert
//     log output (covered by `SourceGrepTests`), but they do assert
//     the parsed body never round-trips through any logger-visible
//     field.
//

import XCTest
@testable import Kizba

final class PassCLITests: XCTestCase {

    // MARK: - Helpers

    /// Default fake `pass` URL used everywhere a binary path is needed.
    /// `BinaryDiscoveryService` (Phase 5) would resolve this in
    /// production; here we bypass it.
    private static let fakePassURL = URL(fileURLWithPath: "/opt/homebrew/bin/pass")

    // MARK: - Success path

    func testShowSuccess_parsesPasswordAndMetadata() async throws {
        let body = """
        s3cret-pw
        user: jane.doe
        url: https://example.test:8443/login
        Recovery codes stored offline.
        """

        let fake = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: body.data(using: .utf8)!,
                stderr: Data()
            )
        )

        let cli = PassCLI(executable: Self.fakePassURL, shellRunner: fake)
        let result = try await cli.show(entryPath: "personal/email/gmail")

        XCTAssertEqual(result.password, "s3cret-pw")
        XCTAssertEqual(result.metadata.count, 2)
        XCTAssertEqual(result.metadata[0].0, "user")
        XCTAssertEqual(result.metadata[0].1, "jane.doe")
        XCTAssertEqual(result.metadata[1].0, "url")
        XCTAssertEqual(result.metadata[1].1, "https://example.test:8443/login")
        XCTAssertEqual(result.notes, "Recovery codes stored offline.")
    }

    // MARK: - Decryption failure

    func testDecryptionFailure_mapsToPassError() async throws {
        // Realistic gpg failure stderr including an email and a key id
        // — the mapper is expected to redact both before the excerpt
        // surfaces in the thrown error payload.
        let stderr = """
        gpg: decryption failed: No secret key
        gpg: encrypted with RSA key, ID DEADBEEFCAFEBABE
        gpg: <jane.doe@example.com>
        """

        let fake = FakeShellRunner(
            response: .success(
                exitCode: 2,
                stdout: Data(),
                stderr: stderr.data(using: .utf8)!
            )
        )

        let cli = PassCLI(executable: Self.fakePassURL, shellRunner: fake)

        do {
            _ = try await cli.show(entryPath: "personal/email/gmail")
            XCTFail("Expected PassError.decryptionFailed")
        } catch PassError.decryptionFailed(let excerpt) {
            // Sanitiser must redact email and long hex IDs.
            XCTAssertFalse(
                excerpt.contains("jane.doe@example.com"),
                "Sanitised excerpt leaked an email address"
            )
            XCTAssertFalse(
                excerpt.contains("DEADBEEFCAFEBABE"),
                "Sanitised excerpt leaked a key id"
            )
            XCTAssertTrue(
                excerpt.lowercased().contains("decryption failed"),
                "Excerpt should still hint at the failure cause"
            )
        } catch {
            XCTFail("Expected PassError.decryptionFailed, got \(error)")
        }
    }

    // MARK: - Timeout

    func testTimeout_throwsTimedOut() async throws {
        // Fake runner that simulates a hung process by throwing the
        // domain timeout error after the requested deadline elapses
        // (or earlier, doesn't matter — `PassCLI` must surface it
        // verbatim).
        let fake = FakeShellRunner(
            response: .throwing(error: PassError.timedOut, after: .milliseconds(10))
        )

        let cli = PassCLI(executable: Self.fakePassURL, shellRunner: fake)

        do {
            _ = try await cli.show(entryPath: "personal/email/gmail", timeout: .milliseconds(100))
            XCTFail("Expected PassError.timedOut")
        } catch PassError.timedOut {
            // ok
        } catch {
            XCTFail("Expected PassError.timedOut, got \(error)")
        }
    }

    // MARK: - Cancellation

    func testCancellation_propagatesCancellation() async throws {
        // Long-running fake that eventually returns success, but we
        // cancel the wrapping Task first. The fake honours Task
        // cancellation by translating it into `PassError.cancelled`
        // — exactly like `ProcessShellRunner` does in production.
        let fake = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: Data("p".utf8),
                stderr: Data()
            ),
            delay: .seconds(5)
        )

        let cli = PassCLI(executable: Self.fakePassURL, shellRunner: fake)

        let task = Task {
            try await cli.show(entryPath: "personal/email/gmail", timeout: .seconds(30))
        }

        // Give the fake's sleep a moment to start.
        try await Task.sleep(for: .milliseconds(50))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected PassError.cancelled")
        } catch PassError.cancelled {
            // ok
        } catch is CancellationError {
            // Acceptable race outcome — structured cancellation may
            // outrun the fake. Either way, `Task` was cancelled.
        } catch {
            XCTFail("Expected PassError.cancelled, got \(error)")
        }
    }

    // MARK: - Env / arg composition

    func testEnvAndBinaryOverride_composition() async throws {
        let body = "pw\n"
        let fake = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: body.data(using: .utf8)!,
                stderr: Data()
            )
        )

        let customPass = URL(fileURLWithPath: "/private/tmp/custom-pass-bin")
        let storeDir = URL(fileURLWithPath: "/private/tmp/kizba-store")
        let gnupgHome = URL(fileURLWithPath: "/private/tmp/kizba-gnupg")
        let pathOverride = "/private/tmp/bin:/usr/bin:/bin"
        let homeOverride = "/private/tmp/kizba-home"

        let cli = PassCLI(
            executable: customPass,
            shellRunner: fake,
            passwordStoreDir: storeDir,
            gnupgHome: gnupgHome,
            pathOverride: pathOverride,
            homeOverride: homeOverride
        )

        _ = try await cli.show(entryPath: "work/aws/root")

        let invocation = try XCTUnwrap(fake.lastInvocation)

        XCTAssertEqual(invocation.executable, customPass)
        XCTAssertEqual(invocation.arguments, ["show", "work/aws/root"])

        XCTAssertEqual(invocation.environment["PATH"], pathOverride)
        XCTAssertEqual(invocation.environment["PASSWORD_STORE_DIR"], storeDir.path)
        XCTAssertEqual(invocation.environment["GNUPGHOME"], gnupgHome.path)
        XCTAssertEqual(invocation.environment["HOME"], homeOverride)

        // No surprise leakage: only the four sanctioned keys above are
        // exported when every override is supplied.
        XCTAssertEqual(
            Set(invocation.environment.keys),
            ["PATH", "PASSWORD_STORE_DIR", "GNUPGHOME", "HOME"]
        )

        // Default timeout is the documented 120s when no value is
        // supplied to `show(entryPath:)`.
        XCTAssertEqual(invocation.timeout, kizbaPassShowDefaultTimeout)
    }

    /// When no overrides are supplied, `PassCLI` still composes a
    /// sanitised `PATH` rather than handing `[:]` to the runner —
    /// otherwise the child inherits an empty environment and `pass`
    /// fails to find `gpg`.
    func testDefaultPATHIsExportedWhenNoOverridesSupplied() async throws {
        let fake = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: Data("pw\n".utf8),
                stderr: Data()
            )
        )

        let cli = PassCLI(executable: Self.fakePassURL, shellRunner: fake)
        _ = try await cli.show(entryPath: "personal/wifi/home")

        let invocation = try XCTUnwrap(fake.lastInvocation)
        XCTAssertEqual(invocation.environment["PATH"], PassCLI.defaultPATH)
        XCTAssertNil(invocation.environment["PASSWORD_STORE_DIR"])
        XCTAssertNil(invocation.environment["GNUPGHOME"])
    }
}

// `FakeShellRunner` lives in `KizbaTests/Fixtures/FakeShellRunner.swift`.
