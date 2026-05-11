import XCTest
@testable import Kizba

final class PassGitErrorMapperTests: XCTestCase {

    func testNotAGitRepository_mapsToGitNotInitialized() throws {
        let stderr = try fixture(named: "not-a-repo")
        let result = map(stderr)

        XCTAssertEqual(result.error, .gitNotInitialized)
    }

    func testNoConfiguredPushDestination_mapsToGitNoRemote() throws {
        let stderr = try fixture(named: "no-remote")
        let result = map(stderr)

        XCTAssertEqual(result.error, .gitNoRemote)
    }

    func testDoesNotAppearToBeGitRepo_mapsToGitNoRemote() {
        let stderr = "fatal: 'origin' does not appear to be a git repository"
        let result = map(stderr)

        XCTAssertEqual(result.error, .gitNoRemote)
    }

    func testAuthenticationFailed_mapsToGitAuthFailed() throws {
        let stderr = try fixture(named: "auth-failed-https")
        let result = map(stderr)

        XCTAssertEqual(result.error, .gitAuthFailed)
    }

    func testPermissionDenied_mapsToGitAuthFailed() throws {
        let stderr = try fixture(named: "auth-failed-ssh")
        let result = map(stderr)

        XCTAssertEqual(result.error, .gitAuthFailed)
    }

    func testCouldNotReadUsername_mapsToGitAuthFailed() {
        let stderr = "fatal: could not read Username for 'https://github.com': terminal prompts disabled"
        let result = map(stderr)

        XCTAssertEqual(result.error, .gitAuthFailed)
    }

    func testConflictSingle_mapsToGitConflictWithPath() throws {
        let stderr = try fixture(named: "conflict-single")
        let result = map(stderr)

        guard case let .gitConflict(paths) = result.error else {
            return XCTFail("Expected gitConflict")
        }
        XCTAssertEqual(paths, ["personal/email.gpg"])
    }

    func testConflictMulti_mapsToGitConflictWithMultiplePaths() throws {
        let stderr = try fixture(named: "conflict-multi")
        let result = map(stderr)

        guard case let .gitConflict(paths) = result.error else {
            return XCTFail("Expected gitConflict")
        }
        XCTAssertEqual(paths?.count, 3)
        XCTAssertEqual(paths?.first, "team/ops root.gpg")
        XCTAssertEqual(paths?.last, "infra/prod/k8s token.gpg")
    }

    func testAutomaticMergeFailed_mapsToGitConflict() throws {
        let stderr = try fixture(named: "automatic-merge-failed")
        let result = map(stderr)

        guard case let .gitConflict(paths) = result.error else {
            return XCTFail("Expected gitConflict")
        }
        XCTAssertNil(paths)
    }

    func testCouldNotResolveHost_mapsToGitNetworkUnavailable() throws {
        let stderr = try fixture(named: "network-unreachable")
        let result = map(stderr)

        XCTAssertEqual(result.error, .gitNetworkUnavailable)
    }

    func testNetworkIsUnreachable_mapsToGitNetworkUnavailable() {
        let stderr = "ssh: connect to host github.com port 22: Network is unreachable"
        let result = map(stderr)

        XCTAssertEqual(result.error, .gitNetworkUnavailable)
    }

    func testOperationTimedOut_mapsToGitNetworkUnavailable() {
        let stderr = "fatal: Operation timed out while connecting to remote host"
        let result = map(stderr)

        XCTAssertEqual(result.error, .gitNetworkUnavailable)
    }

    func testUpdatesWereRejected_mapsToGitRejected() throws {
        let stderr = try fixture(named: "push-rejected")
        let result = map(stderr, operation: .push)

        guard case let .gitRejected(reason) = result.error else {
            return XCTFail("Expected gitRejected")
        }
        XCTAssertTrue(reason.lowercased().contains("fetch first") || reason.lowercased().contains("updates were rejected"))
    }

    func testNonFastForward_mapsToGitRejected() throws {
        let stderr = try fixture(named: "push-non-fast-forward")
        let result = map(stderr, operation: .push)

        guard case let .gitRejected(reason) = result.error else {
            return XCTFail("Expected gitRejected")
        }
        XCTAssertTrue(reason.lowercased().contains("non-fast-forward"))
    }

    func testFetchFirst_mapsToGitRejected() {
        let stderr = "! [rejected] main -> main (fetch first)"
        let result = map(stderr, operation: .push)

        guard case let .gitRejected(reason) = result.error else {
            return XCTFail("Expected gitRejected")
        }
        XCTAssertTrue(reason.lowercased().contains("fetch first"))
    }

    func testUnknownStderr_fallsBackToWriteFailed() throws {
        let stderr = try fixture(named: "unknown-stderr")
        let result = map(stderr)

        guard case let .writeFailed(reason) = result.error else {
            return XCTFail("Expected writeFailed")
        }
        XCTAssertEqual(reason, result.excerpt)
    }

    func testExcerptIsSanitised() {
        let stderr = "fatal: 0123456789ABCDEF contact alice@example.com for details"
        let result = map(stderr)

        XCTAssertEqual(result.excerpt, PassErrorMapper.sanitize(stderr))
        XCTAssertFalse(result.excerpt.contains("alice@example.com"))
        XCTAssertFalse(result.excerpt.contains("0123456789ABCDEF"))
    }

    func testSanitisationIsIdempotent() {
        let raw = "fatal: decryption failed for alice@example.com key ABCDEF1234567890"
        let once = PassErrorMapper.sanitize(raw)
        let twice = PassErrorMapper.sanitize(once)

        XCTAssertEqual(once, twice)
    }

    func testConflictPathExtraction_capsAt20() {
        let lines: [String] = (1...25).map { index in
            "CONFLICT (content): Merge conflict in folder/file \(index).gpg"
        }
        let stderr = (["Automatic merge failed"] + lines).joined(separator: "\n")
        let result = map(stderr)

        guard case let .gitConflict(paths) = result.error else {
            return XCTFail("Expected gitConflict")
        }
        XCTAssertEqual(paths?.count, 20)
        XCTAssertEqual(paths?.first, "folder/file 1.gpg")
        XCTAssertEqual(paths?.last, "folder/file 20.gpg")
    }

    private func map(
        _ stderr: String,
        exitCode: Int32 = 1,
        operation: PassGitErrorMapper.GitOperation = .pull
    ) -> (error: PassError, excerpt: String) {
        PassGitErrorMapper.map(stderr: stderr, exitCode: exitCode, operation: operation)
    }

    private func fixture(named name: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let path = root
            .appendingPathComponent("Fixtures/GitStderrFixtures", isDirectory: true)
            .appendingPathComponent("\(name).txt")
        return try String(contentsOf: path, encoding: .utf8)
    }
}
