import XCTest
@testable import Kizba

@MainActor
final class PassGitIntegrationTests: XCTestCase {

    private var helper: PassGitE2EHelper?

    override func setUp() async throws {
        try await super.setUp()

        let runE2E = ProcessInfo.processInfo.environment["KIZBA_E2E"] == "1"
            && ProcessInfo.processInfo.environment["KIZBA_GIT_E2E"] == "1"
        try XCTSkipUnless(runE2E, "E2E tests require KIZBA_E2E=1 and KIZBA_GIT_E2E=1")

        do {
            helper = try PassGitE2EHelper()
        } catch PassGitE2EHelper.HelperError.missingBinary(let binary) {
            throw XCTSkip("Missing required binary for E2E: \(binary)")
        }
    }

    override func tearDown() async throws {
        if let helper {
            try? await helper.tearDown()
        }
        helper = nil
        try await super.tearDown()
    }

    func testStatus_clean() async throws {
        let helper = try unwrapHelper()
        let bare = try await helper.makeBareRepo()
        let clone = try await helper.cloneRepo(from: bare, name: "store-clean")
        try await helper.passInit(in: clone, gpgKeyID: "e2e@kizba.local")
        try await helper.commitAndPush(
            in: clone,
            path: "sample.gpg",
            content: "ciphertext-sample",
            message: "Add sample entry"
        )

        let manager = try makeManager(store: clone)
        let status = try await manager.gitStatus()

        XCTAssertTrue(status.isGitRepository)
        XCTAssertFalse(status.hasLocalChanges)
        XCTAssertEqual(status.aheadCount, 0)
        XCTAssertEqual(status.behindCount, 0)
        XCTAssertTrue(status.hasRemote)
    }

    func testStatus_dirty() async throws {
        let helper = try unwrapHelper()
        let bare = try await helper.makeBareRepo()
        let clone = try await helper.cloneRepo(from: bare, name: "store-dirty")
        try await helper.passInit(in: clone, gpgKeyID: "e2e@kizba.local")
        try await helper.commitAndPush(
            in: clone,
            path: "dirty.gpg",
            content: "v1",
            message: "Add entry"
        )

        let dirtyFile = clone.appendingPathComponent("dirty.gpg")
        try Data("v2".utf8).write(to: dirtyFile)

        let manager = try makeManager(store: clone)
        let status = try await manager.gitStatus()
        XCTAssertTrue(status.hasLocalChanges)
    }

    func testPull_happy() async throws {
        let helper = try unwrapHelper()
        let bare = try await helper.makeBareRepo()
        let cloneA = try await helper.cloneRepo(from: bare, name: "store-pull-a")
        let cloneB = try await helper.cloneRepo(from: bare, name: "store-pull-b")

        try await helper.passInit(in: cloneA, gpgKeyID: "e2e@kizba.local")
        _ = try helper.shell(["git", "-C", cloneB.path, "pull", "--ff-only"])

        try await helper.commitAndPush(
            in: cloneB,
            path: "remote-only.gpg",
            content: "remote-data",
            message: "Add remote change"
        )

        let manager = try makeManager(store: cloneA)
        try await manager.gitPull(timeoutSeconds: 30)
        let status = try await manager.gitStatus()

        XCTAssertEqual(status.behindCount, 0)
        XCTAssertFalse(status.hasLocalChanges)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cloneA.appendingPathComponent("remote-only.gpg").path))
    }

    func testPull_conflict() async throws {
        let helper = try unwrapHelper()
        let bare = try await helper.makeBareRepo()
        let cloneA = try await helper.cloneRepo(from: bare, name: "store-conflict-a")
        let cloneB = try await helper.cloneRepo(from: bare, name: "store-conflict-b")

        try await helper.passInit(in: cloneA, gpgKeyID: "e2e@kizba.local")
        _ = try helper.shell(["git", "-C", cloneB.path, "pull", "--ff-only"])
        try await helper.createConflict(between: cloneA, cloneB: cloneB, path: "conflict.gpg")

        let manager = try makeManager(store: cloneA)

        do {
            try await manager.gitPull(timeoutSeconds: 30)
            let status = try await manager.gitStatus()
            XCTAssertTrue(status.hasConflicts)
        } catch let error as PassError {
            guard case let .gitConflict(paths) = error else {
                return XCTFail("Expected PassError.gitConflict, got \(error)")
            }
            XCTAssertFalse((paths ?? []).isEmpty)
        }
    }

    func testPush_happy() async throws {
        let helper = try unwrapHelper()
        let bare = try await helper.makeBareRepo()
        let clone = try await helper.cloneRepo(from: bare, name: "store-push")
        try await helper.passInit(in: clone, gpgKeyID: "e2e@kizba.local")

        let newFile = clone.appendingPathComponent("push-new.gpg")
        try Data("push-content".utf8).write(to: newFile)
        _ = try helper.shell(["git", "-C", clone.path, "add", "push-new.gpg"])
        _ = try helper.shell(["git", "-C", clone.path, "commit", "-m", "Add local commit"])

        let manager = try makeManager(store: clone)
        let outcome = try await manager.gitPush(timeoutSeconds: 30)
        XCTAssertEqual(outcome, .pushed)

        let verify = try helper.shell(["git", "-C", bare.path, "show", "HEAD:push-new.gpg"])
        XCTAssertFalse(verify.stdout.isEmpty)
    }

    func testPush_alreadyUpToDate() async throws {
        let helper = try unwrapHelper()
        let bare = try await helper.makeBareRepo()
        let clone = try await helper.cloneRepo(from: bare, name: "store-push-uptodate")
        try await helper.passInit(in: clone, gpgKeyID: "e2e@kizba.local")

        let manager = try makeManager(store: clone)
        let outcome = try await manager.gitPush(timeoutSeconds: 30)

        XCTAssertEqual(outcome, .alreadyUpToDate)
    }

    func testStatus_noRemote() async throws {
        let helper = try unwrapHelper()
        let root = helper.workDir
        let localRepo = root.appendingPathComponent("local-no-remote", isDirectory: true)
        try FileManager.default.createDirectory(at: localRepo, withIntermediateDirectories: true)

        _ = try helper.shell(["git", "init", localRepo.path])
        _ = try helper.shell(["git", "-C", localRepo.path, "config", "user.email", "e2e@kizba.local"])
        _ = try helper.shell(["git", "-C", localRepo.path, "config", "user.name", "Kizba E2E"])
        try await helper.passInit(in: localRepo, gpgKeyID: "e2e@kizba.local")
        _ = try helper.shell(["git", "-C", localRepo.path, "add", ".gpg-id"])
        _ = try helper.shell(["git", "-C", localRepo.path, "commit", "-m", "Initial local pass setup"])

        let manager = try makeManager(store: localRepo)
        let status = try await manager.gitStatus()

        XCTAssertTrue(status.isGitRepository)
        XCTAssertFalse(status.hasRemote)
        XCTAssertEqual(status.aheadCount, 0)
        XCTAssertEqual(status.behindCount, 0)
    }

    private func makeManager(store: URL) throws -> LivePassGitManager {
        let passPath = try resolveRequiredBinary(named: "pass")
        let gitPath = try resolveRequiredBinary(named: "git")

        let passCLI = PassCLI(
            executable: passPath,
            shellRunner: ProcessShellRunner(),
            passwordStoreDir: store,
            pathOverride: "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        )

        return LivePassGitManager(
            passCLI: passCLI,
            gitExecutable: gitPath,
            storeLocationProvider: { store }
        )
    }

    private func unwrapHelper() throws -> PassGitE2EHelper {
        guard let helper else {
            throw XCTSkip("E2E helper is unavailable")
        }
        return helper
    }

    private func resolveRequiredBinary(named name: String) throws -> URL {
        let candidates = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
            "/bin/\(name)",
        ]

        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        throw XCTSkip("Missing required binary for E2E: \(name)")
    }
}
