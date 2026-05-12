import XCTest
@testable import Kizba

@MainActor
final class GitConflictBannerTests: XCTestCase {

    func testOpenTerminalButton_callsActionAndDismisses() {
        let router = AppRouter()
        let model = makeModel(router: router)
        router.presentGitConflictBanner()
        XCTAssertTrue(router.isGitConflictBannerPresented)

        var didCallOpenTerminal = false
        let view = GitConflictBanner(
            model: model,
            storePath: "/tmp/store",
            openTerminalAction: { didCallOpenTerminal = true }
        )

        view.handleOpenTerminalTap()

        XCTAssertTrue(didCallOpenTerminal)
        XCTAssertFalse(router.isGitConflictBannerPresented)
    }

    func testDismissButton_dismissesBanner() {
        let router = AppRouter()
        let model = makeModel(router: router)
        router.presentGitConflictBanner()
        XCTAssertTrue(router.isGitConflictBannerPresented)

        let view = GitConflictBanner(model: model, storePath: "/tmp/store")
        view.handleDismissTap()

        XCTAssertFalse(router.isGitConflictBannerPresented)
    }

    func testStorePath_rendered_copyable() {
        let model = makeModel()
        let path = "/tmp/password-store"

        let view = GitConflictBanner(model: model, storePath: path)

        XCTAssertEqual(view.storePath, path)
    }

    func testBanner_accessibility_storePathAndButtons() {
        let router = AppRouter()
        let model = makeModel(router: router)
        let path = "/tmp/password-store"
        router.presentGitConflictBanner()

        var didCallOpenTerminal = false
        let view = GitConflictBanner(
            model: model,
            storePath: path,
            openTerminalAction: { didCallOpenTerminal = true }
        )

        XCTAssertEqual(view.storePath, path)
        view.handleOpenTerminalTap()

        XCTAssertTrue(didCallOpenTerminal)
        XCTAssertFalse(router.isGitConflictBannerPresented)
    }

    private func makeModel(router: AppRouter) -> GitStatusModel {
        let appState = AppState()
        return GitStatusModel(
            gitManager: FakePassGitManager(),
            passManager: MockPassManager(entries: [], secrets: [:]),
            appState: appState,
            router: router,
            toastCenter: appState.toastCenter,
            settingsStore: AppEnvironment.InMemorySettingsStore()
        )
    }

    private func makeModel() -> GitStatusModel {
        makeModel(router: AppRouter())
    }
}
