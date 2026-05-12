import XCTest
@testable import Kizba

final class LivePassGitManagerTests: XCTestCase {

    private static let passURL = URL(fileURLWithPath: "/usr/bin/pass")
    private static let gitURL = URL(fileURLWithPath: "/usr/bin/git")

    func testStatus_happyPath_returnsParsedGitStatus() async throws {
        let stdout = try fixture(named: "clean-with-upstream", folder: "GitStatusFixtures")
        let fake = FakeShellRunner()
        // Two scripted responses: first for `git status`, second for
        // the follow-up `git remote` invocation (Fix 5). Both yield a
        // happy non-empty payload so `hasRemote` and `hasUpstream`
        // are both `true`.
        fake.script([
            .success(exitCode: 0, stdout: Data(stdout.utf8), stderr: Data()),
            .success(exitCode: 0, stdout: Data("origin\n".utf8), stderr: Data())
        ])
        let storeURL = URL(fileURLWithPath: "/tmp/kizba-live-git-status")
        let manager = makeManager(fake: fake, storeURL: storeURL)

        let status = try await manager.gitStatus()

        XCTAssertEqual(status.branch, "main")
        XCTAssertTrue(status.hasUpstream)
        XCTAssertTrue(status.hasRemote)
        XCTAssertEqual(status.aheadCount, 0)
        XCTAssertEqual(status.behindCount, 0)
    }

    // Fix 5 (MVP4 fix-pack v1) — upstream-less repo with a configured
    // remote: parser sees no `branch.upstream` line, so
    // `hasUpstream` is false, but `git remote` returns `origin`, so
    // `hasRemote` is true. Pull/Push UI gates should consult
    // `hasRemote`, NOT `hasUpstream`.
    func testStatus_remoteWithoutUpstream_hasRemoteTrue_hasUpstreamFalse() async throws {
        let stdout = try fixture(named: "clean-no-remote", folder: "GitStatusFixtures")
        let fake = FakeShellRunner()
        fake.script([
            .success(exitCode: 0, stdout: Data(stdout.utf8), stderr: Data()),
            .success(exitCode: 0, stdout: Data("origin\n".utf8), stderr: Data())
        ])
        let manager = makeManager(fake: fake)

        let status = try await manager.gitStatus()

        XCTAssertFalse(status.hasUpstream)
        XCTAssertTrue(status.hasRemote)
    }

    // Fix 5 (MVP4 fix-pack v1) — repo with neither upstream nor any
    // remote: both flags must be false.
    func testStatus_noRemote_hasRemoteFalse_hasUpstreamFalse() async throws {
        let stdout = try fixture(named: "clean-no-remote", folder: "GitStatusFixtures")
        let fake = FakeShellRunner()
        fake.script([
            .success(exitCode: 0, stdout: Data(stdout.utf8), stderr: Data()),
            .success(exitCode: 0, stdout: Data(), stderr: Data())
        ])
        let manager = makeManager(fake: fake)

        let status = try await manager.gitStatus()

        XCTAssertFalse(status.hasUpstream)
        XCTAssertFalse(status.hasRemote)
    }

    func testStatus_notARepo_returnsNotARepository() async throws {
        let stderr = "fatal: not a git repository (or any of the parent directories): .git"
        let fake = FakeShellRunner(response: .success(exitCode: 128, stdout: Data(), stderr: Data(stderr.utf8)))
        let manager = makeManager(fake: fake)

        let status = try await manager.gitStatus()

        XCTAssertEqual(status, .notARepository)
    }

    func testStatus_networkError_throwsMappedPassError() async {
        let stderr = "ssh: Could not resolve host github.com: Name or service not known"
        let fake = FakeShellRunner(response: .success(exitCode: 1, stdout: Data(), stderr: Data(stderr.utf8)))
        let manager = makeManager(fake: fake)

        do {
            _ = try await manager.gitStatus()
            XCTFail("Expected PassError.gitNetworkUnavailable")
        } catch let error as PassError {
            XCTAssertEqual(error, .gitNetworkUnavailable)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testStatus_arbitraryError_throwsMappedPassError() async {
        let stderr = "fatal: Authentication failed for 'https://example.com/repo.git'"
        let fake = FakeShellRunner(response: .success(exitCode: 1, stdout: Data(), stderr: Data(stderr.utf8)))
        let manager = makeManager(fake: fake)

        do {
            _ = try await manager.gitStatus()
            XCTFail("Expected PassError.gitAuthFailed")
        } catch let error as PassError {
            XCTAssertEqual(error, .gitAuthFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPull_happyPath_succeeds() async throws {
        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data(), stderr: Data()))
        let manager = makeManager(fake: fake)

        try await manager.gitPull(timeoutSeconds: 1)
    }

    func testPull_conflict_throwsGitConflict() async throws {
        let stderr = try fixture(named: "conflict-single", folder: "GitStderrFixtures")
        let fake = FakeShellRunner(response: .success(exitCode: 1, stdout: Data(), stderr: Data(stderr.utf8)))
        let manager = makeManager(fake: fake)

        do {
            try await manager.gitPull(timeoutSeconds: 1)
            XCTFail("Expected PassError.gitConflict")
        } catch let error as PassError {
            guard case let .gitConflict(paths) = error else {
                return XCTFail("Expected gitConflict, got \(error)")
            }
            XCTAssertEqual(paths, ["personal/email.gpg"])
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPull_networkUnavailable_throwsGitNetworkUnavailable() async {
        let stderr = "fatal: Could not resolve host github.com"
        let fake = FakeShellRunner(response: .success(exitCode: 1, stdout: Data(), stderr: Data(stderr.utf8)))
        let manager = makeManager(fake: fake)

        do {
            try await manager.gitPull(timeoutSeconds: 1)
            XCTFail("Expected PassError.gitNetworkUnavailable")
        } catch let error as PassError {
            XCTAssertEqual(error, .gitNetworkUnavailable)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPull_authFailed_throwsGitAuthFailed() async throws {
        let stderr = try fixture(named: "auth-failed-ssh", folder: "GitStderrFixtures")
        let fake = FakeShellRunner(response: .success(exitCode: 1, stdout: Data(), stderr: Data(stderr.utf8)))
        let manager = makeManager(fake: fake)

        do {
            try await manager.gitPull(timeoutSeconds: 1)
            XCTFail("Expected PassError.gitAuthFailed")
        } catch let error as PassError {
            XCTAssertEqual(error, .gitAuthFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPush_happyPath_returnsPushed() async throws {
        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data("To origin/main\n".utf8), stderr: Data()))
        let manager = makeManager(fake: fake)

        let outcome = try await manager.gitPush(timeoutSeconds: 1)

        XCTAssertEqual(outcome, .pushed)
    }

    func testPush_alreadyUpToDate_returnsAlreadyUpToDate() async throws {
        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data("Everything up-to-date\n".utf8), stderr: Data()))
        let manager = makeManager(fake: fake)

        let outcome = try await manager.gitPush(timeoutSeconds: 1)

        XCTAssertEqual(outcome, .alreadyUpToDate)
    }

    func testPush_rejected_throwsGitRejected() async throws {
        let stderr = try fixture(named: "push-rejected", folder: "GitStderrFixtures")
        let fake = FakeShellRunner(response: .success(exitCode: 1, stdout: Data(), stderr: Data(stderr.utf8)))
        let manager = makeManager(fake: fake)

        do {
            _ = try await manager.gitPush(timeoutSeconds: 1)
            XCTFail("Expected PassError.gitRejected")
        } catch let error as PassError {
            guard case let .gitRejected(reason) = error else {
                return XCTFail("Expected gitRejected, got \(error)")
            }
            XCTAssertFalse(reason.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPush_authFailed_throwsGitAuthFailed() async throws {
        let stderr = try fixture(named: "auth-failed-ssh", folder: "GitStderrFixtures")
        let fake = FakeShellRunner(response: .success(exitCode: 1, stdout: Data(), stderr: Data(stderr.utf8)))
        let manager = makeManager(fake: fake)

        do {
            _ = try await manager.gitPush(timeoutSeconds: 1)
            XCTFail("Expected PassError.gitAuthFailed")
        } catch let error as PassError {
            XCTAssertEqual(error, .gitAuthFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPull_cancellation_propagates() async {
        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data(), stderr: Data(), delay: .seconds(1)))
        let manager = makeManager(fake: fake)

        let task = Task {
            try await manager.gitPull(timeoutSeconds: 5)
        }
        task.cancel()

        do {
            try await task.value
            XCTFail("Expected cancellation")
        } catch let error as PassError {
            XCTAssertEqual(error, .cancelled)
        } catch is CancellationError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPush_cancellation_propagates() async {
        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data("To origin/main\n".utf8), stderr: Data(), delay: .seconds(1)))
        let manager = makeManager(fake: fake)

        let task = Task {
            try await manager.gitPush(timeoutSeconds: 5)
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch let error as PassError {
            XCTAssertEqual(error, .cancelled)
        } catch is CancellationError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeManager(fake: FakeShellRunner, storeURL: URL = URL(fileURLWithPath: "/tmp/kizba-store")) -> LivePassGitManager {
        let passCLI = PassCLI(
            executable: Self.passURL,
            shellRunner: fake
        )

        return LivePassGitManager(
            passCLI: passCLI,
            gitExecutable: Self.gitURL,
            storeLocationProvider: { storeURL }
        )
    }

    private func fixture(named name: String, folder: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let path = root
            .appendingPathComponent("Fixtures/\(folder)", isDirectory: true)
            .appendingPathComponent("\(name).txt")
        return try String(contentsOf: path, encoding: .utf8)
    }
}
