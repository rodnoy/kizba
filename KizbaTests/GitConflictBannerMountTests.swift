import SwiftUI
import XCTest
@testable import Kizba

@MainActor
final class GitConflictBannerMountTests: XCTestCase {

    func testPresentGitConflictBanner_setsFlagTrue_whenModelExists() {
        let state = AppState()
        state.gitStatusModel = makeModel(state: state)

        XCTAssertFalse(state.router.isGitConflictBannerPresented)

        state.router.presentGitConflictBanner()

        XCTAssertTrue(state.router.isGitConflictBannerPresented)
    }

    func testGitConflictBannerSheetBinding_andContentBuilder_workWithModel() {
        let state = AppState()
        let model = makeModel(state: state)
        state.gitStatusModel = model
        let environment = AppEnvironment.preview()

        let isPresented = Binding(
            get: { state.router.isGitConflictBannerPresented },
            set: { state.router.isGitConflictBannerPresented = $0 }
        )

        isPresented.wrappedValue = true
        XCTAssertTrue(state.router.isGitConflictBannerPresented)

        var builtView: GitConflictBanner?
        if let gitModel = state.gitStatusModel {
            builtView = GitConflictBanner(
                model: gitModel,
                storePath: environment.storeURL.path,
                openTerminalAction: {}
            )
        }

        XCTAssertNotNil(builtView)

        isPresented.wrappedValue = false
        XCTAssertFalse(state.router.isGitConflictBannerPresented)
    }

    private func makeModel(state: AppState) -> GitStatusModel {
        GitStatusModel(
            gitManager: FakePassGitManager(),
            passManager: MockPassManager(entries: [], secrets: [:]),
            appState: state,
            router: state.router,
            toastCenter: state.toastCenter,
            settingsStore: AppEnvironment.InMemorySettingsStore()
        )
    }
}
