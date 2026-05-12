import XCTest
@testable import Kizba

@MainActor
final class GitStatusBadgeTests: XCTestCase {

    func testBadgeText_notARepository() {
        let model = makeModel(status: .notARepository)
        XCTAssertEqual(model.badgeText, "—")
    }

    func testBadgeText_clean() {
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
        XCTAssertEqual(model.badgeText, "✓")
    }

    func testBadgeText_localChanges() {
        let model = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: true,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        ))
        XCTAssertEqual(model.badgeText, "●")
    }

    func testBadgeText_aheadOnly() {
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
        XCTAssertEqual(model.badgeText, "↑2")
    }

    func testBadgeText_behindOnly() {
        let model = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 3,
            hasRemote: true,
            lastFetchAt: nil
        ))
        XCTAssertEqual(model.badgeText, "↓3")
    }

    func testBadgeText_aheadAndBehind() {
        let model = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 1,
            behindCount: 4,
            hasRemote: true,
            lastFetchAt: nil
        ))
        XCTAssertEqual(model.badgeText, "↑1 ↓4")
    }

    func testBadgeText_conflict() {
        let model = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: true,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        ))
        XCTAssertEqual(model.badgeText, "⚠")
    }

    func testAccessibilityLabel_notARepository() {
        let model = makeModel(status: .notARepository)
        XCTAssertEqual(model.badgeAccessibilityLabel, "Git: unavailable")
    }

    func testAccessibilityLabel_aheadAndBehind() {
        let model = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 2,
            behindCount: 1,
            hasRemote: true,
            lastFetchAt: nil
        ))
        XCTAssertEqual(model.badgeAccessibilityLabel, "Git: 2 ahead, 1 behind")
    }

    func testAccessibilityLabel_conflict() {
        let model = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: true,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        ))
        XCTAssertEqual(model.badgeAccessibilityLabel, "Git: merge conflict")
    }

    func testBadge_accessibilityValue_and_label() {
        let clean = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        ))
        XCTAssertEqual(clean.badgeAccessibilityLabel, "Git: clean")
        XCTAssertEqual(clean.badgeText, "✓")

        let conflict = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: true,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        ))
        XCTAssertEqual(conflict.badgeAccessibilityLabel, "Git: merge conflict")
        XCTAssertEqual(conflict.badgeText, "⚠")

        let aheadBehind = makeModel(status: GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 2,
            behindCount: 3,
            hasRemote: true,
            lastFetchAt: nil
        ))
        XCTAssertEqual(aheadBehind.badgeAccessibilityLabel, "Git: 2 ahead, 3 behind")
        XCTAssertEqual(aheadBehind.badgeText, "↑2 ↓3")
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
        return model
    }
}
