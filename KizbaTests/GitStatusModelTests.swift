import XCTest
@testable import Kizba

@MainActor
final class GitStatusModelTests: XCTestCase {

    func testLoadStatus_happyPath_updatesStatusAndLoadState() async {
        let manager = FakePassGitManager()
        let expected = GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 2,
            behindCount: 1,
            hasRemote: true,
            lastFetchAt: nil
        )
        await manager.setNextStatus(.success(expected))

        let model = makeModel(gitManager: manager)
        await model.loadStatus()

        XCTAssertEqual(model.loadState, .loaded)
        XCTAssertEqual(model.status, expected)
    }

    func testLoadStatus_failure_setsLastError_and_loadStateFailed_and_postsToastWhenAppropriate() async {
        let manager = FakePassGitManager()
        await manager.setNextStatus(.failure(PassError.gitAuthFailed))

        let appState = AppState()
        let model = makeModel(gitManager: manager, appState: appState)
        await model.loadStatus()

        XCTAssertEqual(model.loadState, .failed)
        XCTAssertEqual(model.lastError, .gitAuthFailed)
        XCTAssertEqual(appState.toastCenter.visible?.severity, .danger)
    }

    func testLoadStatus_staleResult_ignoredByGeneration() async {
        let manager = FakePassGitManager()
        let stale = GitStatus(
            isGitRepository: true,
            branch: "stale",
            hasLocalChanges: true,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        )
        let fresh = GitStatus(
            isGitRepository: true,
            branch: "fresh",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 1,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        )

        await manager.setNextStatus(.success(stale))
        await manager.setArtificialDelay(.milliseconds(120))

        let model = makeModel(gitManager: manager)
        let first = Task { await model.loadStatus() }

        try? await Task.sleep(for: .milliseconds(20))
        await manager.setArtificialDelay(nil)
        await manager.setNextStatus(.success(fresh))
        await model.loadStatus()

        await manager.setNextStatus(.success(stale))
        await first.value

        XCTAssertEqual(model.status.branch, "fresh")
        XCTAssertEqual(model.status, fresh)
        XCTAssertEqual(model.loadState, .loaded)
    }

    func testCancelLoad_cancelsTask_and_leavesLoadStateIdleOrFailedConsistent() async {
        let manager = FakePassGitManager()
        await manager.setNextStatus(.success(.notARepository))
        await manager.setArtificialDelay(.seconds(1))

        let model = makeModel(gitManager: manager)
        let task = Task { await model.loadStatus() }
        try? await Task.sleep(for: .milliseconds(30))

        model.cancelCurrentLoad()
        await task.value

        XCTAssertNotEqual(model.loadState, .loading)
    }

    func testCanPull_respectsAnyWriteInFlight() {
        let appState = AppState()
        let model = makeModel(appState: appState)
        model.status = GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        )

        XCTAssertTrue(model.canPull)
        appState.beginWrite(.insertNew)
        XCTAssertFalse(model.canPull)
    }

    func testCanPush_aheadCount_enablesPush() {
        let model = makeModel()
        model.status = GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        )
        XCTAssertFalse(model.canPush)

        model.status = GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 3,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        )
        XCTAssertTrue(model.canPush)
    }

    func testIsFullyClean_trueForCleanStatus() {
        let model = makeModel()
        model.status = GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 3,
            behindCount: 2,
            hasRemote: true,
            lastFetchAt: nil
        )

        XCTAssertTrue(model.isFullyClean)
    }

    func testBadgeText_variousStates() {
        let model = makeModel()

        model.status = GitStatus(isGitRepository: true, hasLocalChanges: false, hasConflicts: false, aheadCount: 0, behindCount: 0, hasRemote: true)
        XCTAssertEqual(model.badgeText, "✓")

        model.status = GitStatus(isGitRepository: true, hasLocalChanges: true, hasConflicts: false, aheadCount: 0, behindCount: 0, hasRemote: true)
        XCTAssertEqual(model.badgeText, "●")

        model.status = GitStatus(isGitRepository: true, hasLocalChanges: false, hasConflicts: false, aheadCount: 2, behindCount: 0, hasRemote: true)
        XCTAssertEqual(model.badgeText, "↑2")

        model.status = GitStatus(isGitRepository: true, hasLocalChanges: false, hasConflicts: false, aheadCount: 0, behindCount: 4, hasRemote: true)
        XCTAssertEqual(model.badgeText, "↓4")

        model.status = GitStatus(isGitRepository: true, hasLocalChanges: false, hasConflicts: true, aheadCount: 0, behindCount: 0, hasRemote: true)
        XCTAssertEqual(model.badgeText, "⚠")
    }

    func testBadgeAccessibilityLabel_nonEmpty() {
        let model = makeModel()
        model.status = GitStatus(isGitRepository: true, hasLocalChanges: false, hasConflicts: false, aheadCount: 1, behindCount: 2, hasRemote: true)
        XCTAssertFalse(model.badgeAccessibilityLabel.isEmpty)
    }

    func testLoadUsesSettingsTimeout() throws {
        throw XCTSkip("C.1 scaffold does not consume git timeout setting yet.")
    }

    func testLoad_sets_lastError_nil_onSuccess() async {
        let manager = FakePassGitManager()
        await manager.setNextStatus(.failure(PassError.gitNetworkUnavailable))
        let model = makeModel(gitManager: manager)

        await model.loadStatus()
        XCTAssertNotNil(model.lastError)

        await manager.setNextStatus(.success(.notARepository))
        await model.loadStatus()
        XCTAssertNil(model.lastError)
    }

    func testRefreshConflictAutoDismiss_callsRouterWhenConflictsCleared() async {
        let manager = FakePassGitManager()
        await manager.setNextStatus(.success(GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        )))

        let router = AppRouter()
        router.presentGitConflictBanner()
        XCTAssertTrue(router.isGitConflictBannerPresented)

        let model = makeModel(gitManager: manager, router: router)
        await model.loadStatus()

        XCTAssertFalse(router.isGitConflictBannerPresented)
    }

    func testOperationState_transitions_onPullPushCalls() {
        let model = makeModel()
        model.status = GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 2,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        )

        XCTAssertTrue(model.canPull)
        XCTAssertTrue(model.canPush)

        model.operationState = .pulling
        XCTAssertFalse(model.canPull)
        XCTAssertFalse(model.canPush)

        model.operationState = .pushing
        XCTAssertFalse(model.canPull)
        XCTAssertFalse(model.canPush)

        model.operationState = .idle
        XCTAssertTrue(model.canPull)
        XCTAssertTrue(model.canPush)
    }

    func testLoadStatus_failure_silentPresentation_doesNotPostToast() async {
        let manager = FakePassGitManager()
        await manager.setNextStatus(.failure(PassError.gitConflict(paths: ["x"])))
        let appState = AppState()
        let model = makeModel(gitManager: manager, appState: appState)

        await model.loadStatus()

        XCTAssertNil(appState.toastCenter.visible)
        XCTAssertEqual(model.loadState, .failed)
    }

    func testCanRefresh_falseWhileLoading_trueWhenIdle() async {
        let manager = FakePassGitManager()
        await manager.setArtificialDelay(.milliseconds(120))
        let model = makeModel(gitManager: manager)

        let task = Task { await model.loadStatus() }
        try? await Task.sleep(for: .milliseconds(20))
        XCTAssertFalse(model.canRefresh)

        await task.value
        XCTAssertTrue(model.canRefresh)
    }

    // MARK: - Helpers

    private func makeModel(
        gitManager: FakePassGitManager = FakePassGitManager(),
        passManager: any PassManaging = MockPassManager(entries: [], secrets: [:]),
        appState: AppState? = nil,
        router: AppRouter? = nil,
        settingsStore: any SettingsStoring = AppEnvironment.InMemorySettingsStore()
    ) -> GitStatusModel {
        let resolvedAppState = appState ?? AppState()
        let resolvedRouter = router ?? AppRouter()
        return GitStatusModel(
            gitManager: gitManager,
            passManager: passManager,
            appState: resolvedAppState,
            router: resolvedRouter,
            toastCenter: resolvedAppState.toastCenter,
            settingsStore: settingsStore
        )
    }
}
