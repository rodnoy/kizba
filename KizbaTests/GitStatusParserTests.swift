import XCTest
@testable import Kizba

final class GitStatusParserTests: XCTestCase {

    func testEmptyInput_returnsGitRepoWithDefaults() {
        let status = GitStatusParser.parse("")

        XCTAssertTrue(status.isGitRepository)
        XCTAssertNil(status.branch)
        XCTAssertFalse(status.hasLocalChanges)
        XCTAssertFalse(status.hasConflicts)
        XCTAssertEqual(status.aheadCount, 0)
        XCTAssertEqual(status.behindCount, 0)
        // Fix 5 (MVP4 fix-pack v1) — parser populates hasUpstream
        // only; hasRemote is set later by ``LivePassGitManager``.
        XCTAssertFalse(status.hasUpstream)
        XCTAssertFalse(status.hasRemote)
        XCTAssertNil(status.lastFetchAt)
    }

    func testCleanRepoWithUpstream_parsesAllHeaders() throws {
        let status = GitStatusParser.parse(try fixture(named: "clean-with-upstream"))

        XCTAssertTrue(status.isGitRepository)
        XCTAssertEqual(status.branch, "main")
        XCTAssertTrue(status.hasUpstream)
        XCTAssertEqual(status.aheadCount, 0)
        XCTAssertEqual(status.behindCount, 0)
        XCTAssertFalse(status.hasLocalChanges)
        XCTAssertFalse(status.hasConflicts)
    }

    func testCleanRepoNoRemote_hasUpstreamFalse() throws {
        let status = GitStatusParser.parse(try fixture(named: "clean-no-remote"))

        XCTAssertEqual(status.branch, "main")
        XCTAssertFalse(status.hasUpstream)
        XCTAssertEqual(status.aheadCount, 0)
        XCTAssertEqual(status.behindCount, 0)
    }

    func testAheadOnly_parsesAheadCount() throws {
        let status = GitStatusParser.parse(try fixture(named: "ahead-only"))

        XCTAssertEqual(status.aheadCount, 3)
        XCTAssertEqual(status.behindCount, 0)
    }

    func testBehindOnly_parsesBehindCount() throws {
        let status = GitStatusParser.parse(try fixture(named: "behind-only"))

        XCTAssertEqual(status.aheadCount, 0)
        XCTAssertEqual(status.behindCount, 2)
    }

    func testAheadAndBehind_parsesBothCounts() throws {
        let status = GitStatusParser.parse(try fixture(named: "ahead-behind"))

        XCTAssertEqual(status.aheadCount, 1)
        XCTAssertEqual(status.behindCount, 4)
    }

    func testModifiedFile_hasLocalChangesTrue() throws {
        let status = GitStatusParser.parse(try fixture(named: "modified"))

        XCTAssertTrue(status.hasLocalChanges)
        XCTAssertFalse(status.hasConflicts)
    }

    func testStagedFile_hasLocalChangesTrue() throws {
        let status = GitStatusParser.parse(try fixture(named: "staged"))

        XCTAssertTrue(status.hasLocalChanges)
        XCTAssertFalse(status.hasConflicts)
    }

    func testRenamedFile_hasLocalChangesTrue() throws {
        let status = GitStatusParser.parse(try fixture(named: "renamed"))

        XCTAssertTrue(status.hasLocalChanges)
        XCTAssertFalse(status.hasConflicts)
    }

    func testUntrackedFile_hasLocalChangesTrue() throws {
        let status = GitStatusParser.parse(try fixture(named: "untracked"))

        XCTAssertTrue(status.hasLocalChanges)
        XCTAssertFalse(status.hasConflicts)
    }

    func testConflictLine_hasConflictsTrue() throws {
        let status = GitStatusParser.parse(try fixture(named: "conflict"))

        XCTAssertTrue(status.hasConflicts)
        XCTAssertTrue(status.hasLocalChanges)
    }

    func testDetachedHead_branchIsNil() throws {
        let status = GitStatusParser.parse(try fixture(named: "detached-head"))

        XCTAssertNil(status.branch)
        XCTAssertFalse(status.hasUpstream)
    }

    func testMultiSection_allFieldsCombined() throws {
        let status = GitStatusParser.parse(try fixture(named: "multi-section"))

        XCTAssertEqual(status.branch, "release/1.2")
        XCTAssertTrue(status.hasUpstream)
        XCTAssertEqual(status.aheadCount, 2)
        XCTAssertEqual(status.behindCount, 5)
        XCTAssertTrue(status.hasLocalChanges)
        XCTAssertTrue(status.hasConflicts)
    }

    func testUnknownLines_silentlyIgnored() throws {
        let status = GitStatusParser.parse(try fixture(named: "unknown-lines"))

        XCTAssertEqual(status.branch, "main")
        XCTAssertTrue(status.hasUpstream)
        XCTAssertEqual(status.aheadCount, 4)
        XCTAssertEqual(status.behindCount, 1)
        XCTAssertFalse(status.hasLocalChanges)
        XCTAssertFalse(status.hasConflicts)
    }

    func testLastFetchAt_alwaysNil() throws {
        let status = GitStatusParser.parse(try fixture(named: "multi-section"))
        XCTAssertNil(status.lastFetchAt)
    }

    func testIsGitRepository_alwaysTrue() throws {
        let status = GitStatusParser.parse(try fixture(named: "clean-no-remote"))
        XCTAssertTrue(status.isGitRepository)
    }

    func testWhitespaceOnlyInput_returnsDefaults() {
        let status = GitStatusParser.parse("   \n\t\n  ")

        XCTAssertTrue(status.isGitRepository)
        XCTAssertNil(status.branch)
        XCTAssertFalse(status.hasUpstream)
        XCTAssertEqual(status.aheadCount, 0)
        XCTAssertEqual(status.behindCount, 0)
        XCTAssertFalse(status.hasLocalChanges)
        XCTAssertFalse(status.hasConflicts)
    }

    func testBranchWithSlashes_parsedCorrectly() {
        let stdout = "# branch.head feature/foo/bar\n# branch.upstream origin/feature/foo/bar\n# branch.ab +7 -3\n"
        let status = GitStatusParser.parse(stdout)

        XCTAssertEqual(status.branch, "feature/foo/bar")
        XCTAssertTrue(status.hasUpstream)
        XCTAssertEqual(status.aheadCount, 7)
        XCTAssertEqual(status.behindCount, 3)
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
