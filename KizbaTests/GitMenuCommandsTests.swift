import XCTest
@testable import Kizba

@MainActor
final class GitMenuCommandsTests: XCTestCase {

    func testMenuHiddenWhenNoModel() {
        let state = AppState()
        XCTAssertFalse(GitMenuCommands.isVisible(state: state))
    }

    func testMenuVisibleWhenModelPresent() {
        let (state, _) = makeStateWithModel()
        XCTAssertTrue(GitMenuCommands.isVisible(state: state))
    }

    func testCanPullDisabledWhenNoRemote() {
        let status = GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: false,
            lastFetchAt: nil
        )
        let (state, model) = makeStateWithModel(status: status)
        model.operationState = .idle

        XCTAssertFalse(GitMenuCommands.canPull(state: state))
    }

    func testCanPullDisabledWhenAnyWriteInFlight() {
        let status = GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        )
        let (state, model) = makeStateWithModel(status: status)
        model.operationState = .idle
        state.beginWrite(.insertNew)

        XCTAssertFalse(GitMenuCommands.canPull(state: state))
    }

    func testCanPushEnabledWhenAheadAndNoWriteInFlight() {
        let status = GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 2,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        )
        let (state, model) = makeStateWithModel(status: status)
        model.operationState = .idle

        XCTAssertTrue(GitMenuCommands.canPush(state: state))
    }

    func testCanRefreshReflectsModel() {
        let (state, model) = makeStateWithModel(status: .notARepository)

        model.loadState = .idle
        model.operationState = .idle
        XCTAssertTrue(GitMenuCommands.canRefresh(state: state))

        model.loadState = .loading
        model.operationState = .idle
        XCTAssertFalse(GitMenuCommands.canRefresh(state: state))

        model.loadState = .loaded
        model.operationState = .pulling
        XCTAssertFalse(GitMenuCommands.canRefresh(state: state))

        model.operationState = .pushing
        XCTAssertFalse(GitMenuCommands.canRefresh(state: state))
    }

    private func makeStateWithModel(
        status: GitStatus = .notARepository,
        loadState: GitStatusModel.LoadState = .idle,
        operationState: GitStatusModel.OperationState = .idle
    ) -> (AppState, GitStatusModel) {
        let state = AppState()
        let model = GitStatusModel(
            gitManager: FakePassGitManager(),
            passManager: MockPassManager(entries: [], secrets: [:]),
            appState: state,
            router: AppRouter(),
            toastCenter: state.toastCenter,
            settingsStore: AppEnvironment.InMemorySettingsStore()
        )
        model.status = status
        model.loadState = loadState
        model.operationState = operationState
        state.gitStatusModel = model
        return (state, model)
    }
}
