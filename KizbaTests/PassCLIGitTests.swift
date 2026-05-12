import XCTest
@testable import Kizba

final class PassCLIGitTests: XCTestCase {

    private static let passURL = URL(fileURLWithPath: "/opt/homebrew/bin/pass")
    private static let gitURL = URL(fileURLWithPath: "/usr/bin/git")

    func testGitStatus_invocationShape() async throws {
        // Fix 5 (MVP4 fix-pack v1) — gitStatus() now issues TWO
        // shell calls: `git status --porcelain=v2 --branch` then
        // `git remote`. Assert on the first invocation explicitly
        // (the second is covered by `testGitStatus_listsRemotes`).
        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data(), stderr: Data([0x78, 0x79])))
        let cli = PassCLI(
            executable: Self.passURL,
            shellRunner: fake,
            passwordStoreDir: URL(fileURLWithPath: "/tmp/store"),
            homeOverride: "/tmp/home"
        )
        let storePath = "/tmp/store"

        _ = try await cli.gitStatus(storePath: storePath, gitExecutable: Self.gitURL)

        let invocation = try XCTUnwrap(fake.allInvocations.first)
        XCTAssertEqual(invocation.executable, Self.gitURL)
        XCTAssertEqual(invocation.arguments, ["-C", storePath, "status", "--porcelain=v2", "--branch"])
        XCTAssertEqual(invocation.timeout, .seconds(5))
        XCTAssertEqual(invocation.stdin, .none)
        // Fix 3 (MVP4 fix-pack v1) — git PATH appends `/sbin` and
        // `/usr/sbin` for `darwin.sh` RAM-disk helpers.
        XCTAssertEqual(invocation.environment["PATH"], PassCLI.defaultPATH + ":/sbin:/usr/sbin")
        XCTAssertEqual(invocation.environment["GIT_TERMINAL_PROMPT"], "0")
        XCTAssertEqual(invocation.environment["SSH_ASKPASS"], "/usr/bin/false")
        XCTAssertEqual(invocation.environment["PASSWORD_STORE_DIR"], storePath)
        XCTAssertEqual(invocation.environment["HOME"], "/tmp/home")
    }

    // Fix 5 (MVP4 fix-pack v1) — `gitStatus` now follows up with a
    // `git remote` call so the manager can populate
    // `GitStatus.hasRemote` independently of the parser's
    // upstream-only signal.
    func testGitStatus_followsUpWithGitRemoteCall() async throws {
        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data(), stderr: Data()))
        let cli = PassCLI(executable: Self.passURL, shellRunner: fake)

        _ = try await cli.gitStatus(storePath: "/tmp/store", gitExecutable: Self.gitURL)

        let invocations = fake.allInvocations
        XCTAssertGreaterThanOrEqual(invocations.count, 2)
        let remoteCall = invocations[1]
        XCTAssertEqual(remoteCall.executable, Self.gitURL)
        XCTAssertEqual(remoteCall.arguments, ["-C", "/tmp/store", "remote"])
    }

    func testGitStatus_parsesStdout() async throws {
        let stdout = try fixture(named: "ahead-behind")
        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data(stdout.utf8), stderr: Data()))
        let cli = PassCLI(executable: Self.passURL, shellRunner: fake)

        let status = try await cli.gitStatus(storePath: "/tmp/store", gitExecutable: Self.gitURL)

        XCTAssertEqual(status.branch, "main")
        XCTAssertTrue(status.hasRemote)
        XCTAssertEqual(status.aheadCount, 1)
        XCTAssertEqual(status.behindCount, 4)
        XCTAssertTrue(status.isGitRepository)
    }

    func testGitStatus_mergesFetchHeadMtime() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let gitDir = tempDir.appendingPathComponent(".git", isDirectory: true)
        let fetchHead = gitDir.appendingPathComponent("FETCH_HEAD")

        try FileManager.default.createDirectory(at: gitDir, withIntermediateDirectories: true)
        try Data("fetch".utf8).write(to: fetchHead)

        let expectedDate = Date(timeIntervalSince1970: 1_700_000_000)
        try FileManager.default.setAttributes([.modificationDate: expectedDate], ofItemAtPath: fetchHead.path)

        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data(), stderr: Data()))
        let cli = PassCLI(executable: Self.passURL, shellRunner: fake)

        let status = try await cli.gitStatus(storePath: tempDir.path, gitExecutable: Self.gitURL)

        XCTAssertEqual(status.lastFetchAt, expectedDate)
    }

    func testGitStatus_noFetchHead_lastFetchAtNil() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data(), stderr: Data()))
        let cli = PassCLI(executable: Self.passURL, shellRunner: fake)

        let status = try await cli.gitStatus(storePath: tempDir.path, gitExecutable: Self.gitURL)

        XCTAssertNil(status.lastFetchAt)
    }

    func testGitPull_invocationShape() async throws {
        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data(), stderr: Data()))
        let cli = PassCLI(executable: Self.passURL, shellRunner: fake)

        try await cli.gitPull(storePath: "/tmp/custom-store", timeoutSeconds: 42)

        let invocation = try XCTUnwrap(fake.lastInvocation)
        XCTAssertEqual(invocation.executable, Self.passURL)
        XCTAssertEqual(invocation.arguments, ["git", "pull"])
        XCTAssertEqual(invocation.timeout, .seconds(42))
        XCTAssertEqual(invocation.stdin, .none)
        XCTAssertEqual(invocation.environment["PASSWORD_STORE_DIR"], "/tmp/custom-store")
        XCTAssertEqual(invocation.environment["GIT_TERMINAL_PROMPT"], "0")
        XCTAssertEqual(invocation.environment["SSH_ASKPASS"], "/usr/bin/false")
        // Fix 3 (MVP4 fix-pack v1) — PATH for git ops carries `/sbin`
        // and `/usr/sbin` so `darwin.sh` can locate `umount` and
        // `diskutil`.
        XCTAssertTrue((invocation.environment["PATH"] ?? "").split(separator: ":").contains("/sbin"))
        XCTAssertTrue((invocation.environment["PATH"] ?? "").split(separator: ":").contains("/usr/sbin"))
    }

    func testGitPush_invocationShape() async throws {
        let fake = FakeShellRunner(response: .success(exitCode: 0, stdout: Data("push ok".utf8), stderr: Data()))
        let cli = PassCLI(executable: Self.passURL, shellRunner: fake)

        _ = try await cli.gitPush(storePath: "/tmp/custom-store", timeoutSeconds: 60)

        let invocation = try XCTUnwrap(fake.lastInvocation)
        XCTAssertEqual(invocation.executable, Self.passURL)
        XCTAssertEqual(invocation.arguments, ["git", "push"])
        XCTAssertEqual(invocation.timeout, .seconds(60))
        XCTAssertEqual(invocation.stdin, .none)
        XCTAssertEqual(invocation.environment["PASSWORD_STORE_DIR"], "/tmp/custom-store")
        XCTAssertEqual(invocation.environment["GIT_TERMINAL_PROMPT"], "0")
        XCTAssertEqual(invocation.environment["SSH_ASKPASS"], "/usr/bin/false")
        // Fix 3 (MVP4 fix-pack v1) — see `testGitPull_invocationShape`.
        XCTAssertTrue((invocation.environment["PATH"] ?? "").split(separator: ":").contains("/sbin"))
        XCTAssertTrue((invocation.environment["PATH"] ?? "").split(separator: ":").contains("/usr/sbin"))
    }

    func testGitPush_upToDate_returnsAlreadyUpToDate() async throws {
        let fake = FakeShellRunner(response: .success(
            exitCode: 0,
            stdout: Data("Everything up-to-date\n".utf8),
            stderr: Data()
        ))
        let cli = PassCLI(executable: Self.passURL, shellRunner: fake)

        let outcome = try await cli.gitPush(storePath: "/tmp/store", timeoutSeconds: 60)

        XCTAssertEqual(outcome, .alreadyUpToDate)
    }

    func testGitPush_pushed_returnsPushed() async throws {
        let fake = FakeShellRunner(response: .success(
            exitCode: 0,
            stdout: Data("To origin/main\n".utf8),
            stderr: Data()
        ))
        let cli = PassCLI(executable: Self.passURL, shellRunner: fake)

        let outcome = try await cli.gitPush(storePath: "/tmp/store", timeoutSeconds: 60)

        XCTAssertEqual(outcome, .pushed)
    }

    private func fixture(named name: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let path = root
            .appendingPathComponent("Fixtures/GitStatusFixtures", isDirectory: true)
            .appendingPathComponent("\(name).txt")
        return try String(contentsOf: path, encoding: .utf8)
    }
}
