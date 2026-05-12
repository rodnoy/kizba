import XCTest
@testable import Kizba

@MainActor
final class GitActionsPopoverTests: XCTestCase {

    func testPullButtonDisabledWhenModelCannotPull() {
        let model = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 1,
            behindCount: 0,
            hasRemote: false,
            lastFetchAt: nil
        ))

        XCTAssertFalse(model.canPull)
    }

    func testPullButtonEnabledWhenModelCanPull() {
        let model = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        ))

        XCTAssertTrue(model.canPull)
    }

    func testPushButtonDisabledWhenModelCannotPush() {
        let model = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        ))

        XCTAssertFalse(model.canPush)
    }

    func testPushButtonEnabledWhenModelCanPush() {
        let model = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 2,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        ))

        XCTAssertTrue(model.canPush)
    }

    func testRefreshButtonDisabledWhenLoadOrOperationInProgress() {
        let model = makeModel(status: .notARepository)

        model.loadState = .loading
        XCTAssertFalse(model.canRefresh)

        model.loadState = .loaded
        model.operationState = .pulling
        XCTAssertFalse(model.canRefresh)
    }

    func testRefreshButtonEnabledWhenIdle() {
        let model = makeModel(status: .notARepository)

        model.loadState = .loaded
        model.operationState = .idle

        XCTAssertTrue(model.canRefresh)
    }

    func testSpinnerAndCancelVisibleWhenPullingOrPushing() {
        XCTAssertTrue(GitActionsPopover.showsInFlightUI(for: .pulling))
        XCTAssertTrue(GitActionsPopover.showsInFlightUI(for: .pushing))
    }

    func testSpinnerAndCancelHiddenWhenIdle() {
        XCTAssertFalse(GitActionsPopover.showsInFlightUI(for: .idle))
    }

    func testInFlightAccessibility_progressLabelAndCancelHint() {
        let model = makeModel(status: .notARepository)
        model.operationState = .pulling

        XCTAssertTrue(GitActionsPopover.showsInFlightUI(for: model.operationState))
        XCTAssertEqual(GitActionsPopover.progressAccessibilityValue(for: model.operationState), "Pulling")
    }

    private func makeModel(status: GitStatus) -> GitStatusModel {
        let gitManager = FakePassGitManager()
        let appState = AppState()
        let model = GitStatusModel(
            gitManager: gitManager,
            passManager: MockPassManager(entries: [], secrets: [:]),
            appState: appState,
            router: AppRouter(),
            toastCenter: appState.toastCenter,
            settingsStore: AppEnvironment.InMemorySettingsStore()
        )
        model.status = status
        model.loadState = .loaded
        return model
    }
}
