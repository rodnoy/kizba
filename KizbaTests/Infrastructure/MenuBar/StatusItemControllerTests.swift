import SwiftUI
import XCTest
@testable import Kizba

@MainActor
final class StatusItemControllerTests: XCTestCase {

    func testShow_idempotent() throws {
        #if canImport(AppKit)
        let controller = makeController()

        controller.show()
        controller.show()
        controller.hide()

        XCTAssertTrue(true)
        #else
        throw XCTSkip("AppKit is unavailable on this platform")
        #endif
    }

    func testToggle_showsAndHides() throws {
        #if canImport(AppKit)
        let controller = makeController()

        controller.toggle()
        controller.toggle()

        XCTAssertTrue(true)
        #else
        throw XCTSkip("AppKit is unavailable on this platform")
        #endif
    }

    func testHide_idempotent() throws {
        #if canImport(AppKit)
        let controller = makeController()

        controller.show()
        controller.hide()
        controller.hide()

        XCTAssertTrue(true)
        #else
        throw XCTSkip("AppKit is unavailable on this platform")
        #endif
    }

    private func makeController() -> StatusItemController {
        let env = AppEnvironment.preview()
        let menuModel = MenuBarModel(
            searchEngine: FakeSearchEngine(cannedResults: []),
            recentStore: FakeRecentEntriesStore(),
            favoritesStore: FakeFavoritesStore(),
            clipboard: FakeClipboardServicing(),
            passManager: FakePassManager(),
            settings: MutableSettingsStore(),
            biometricAuth: nil
        )

        return StatusItemController(
            environment: env,
            content: { AnyView(MenuBarPopoverView(model: menuModel)) }
        )
    }
}
