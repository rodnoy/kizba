import XCTest
@testable import Kizba

@MainActor
final class FakePassGitManagerTests: XCTestCase {

    private struct FixtureError: Error, Equatable {}

    func testStatusCallCount_incrementsOnEachCall() async throws {
        let manager = FakePassGitManager()

        _ = try await manager.gitStatus()
        _ = try await manager.gitStatus()

        let calls = await manager.statusCallCount
        XCTAssertEqual(calls, 2)
    }

    func testStatusReturnsConfiguredResult() async {
        let manager = FakePassGitManager()

        let expected = GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: true,
            hasConflicts: false,
            aheadCount: 1,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: Date(timeIntervalSince1970: 1)
        )
        await manager.setNextStatus(.success(expected))

        do {
            let received = try await manager.gitStatus()
            XCTAssertEqual(received, expected)
        } catch {
            XCTFail("Expected successful gitStatus, got error: \(error)")
        }

        await manager.setNextStatus(.failure(FixtureError()))

        do {
            _ = try await manager.gitStatus()
            XCTFail("Expected gitStatus to throw")
        } catch {
            XCTAssertTrue(error is FixtureError)
        }
    }

    func testPullConsumesScriptedResults() async {
        let manager = FakePassGitManager()
        await manager.setPullResults([
            .failure(FixtureError()),
            .success(())
        ])

        do {
            try await manager.gitPull(timeoutSeconds: 1)
            XCTFail("Expected first pull to throw")
        } catch {
            XCTAssertTrue(error is FixtureError)
        }

        do {
            try await manager.gitPull(timeoutSeconds: 1)
        } catch {
            XCTFail("Expected second pull to succeed, got: \(error)")
        }

        do {
            try await manager.gitPull(timeoutSeconds: 1)
        } catch {
            XCTFail("Expected default pull to succeed, got: \(error)")
        }

        let calls = await manager.pullCallCount
        XCTAssertEqual(calls, 3)
    }

    func testPushConsumesScriptedResults() async {
        let manager = FakePassGitManager()
        await manager.setPushResults([
            .success(.alreadyUpToDate),
            .failure(FixtureError())
        ])

        do {
            let outcome = try await manager.gitPush(timeoutSeconds: 1)
            XCTAssertEqual(outcome, .alreadyUpToDate)
        } catch {
            XCTFail("Expected first push to succeed, got: \(error)")
        }

        do {
            _ = try await manager.gitPush(timeoutSeconds: 1)
            XCTFail("Expected second push to throw")
        } catch {
            XCTAssertTrue(error is FixtureError)
        }

        let calls = await manager.pushCallCount
        XCTAssertEqual(calls, 2)
    }

    func testDefaultPushReturns_pushed() async throws {
        let manager = FakePassGitManager()
        let outcome = try await manager.gitPush(timeoutSeconds: 1)
        XCTAssertEqual(outcome, .pushed)
    }
}
