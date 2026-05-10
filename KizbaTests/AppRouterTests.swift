import XCTest
@testable import Kizba

@MainActor
final class AppRouterTests: XCTestCase {

    func testDismissAllClearsPresentationFlags() {
        let router = AppRouter()
        router.presentNewEntry()
        router.presentEditEntry()
        router.presentMove()
        router.presentRegenerate()
        router.presentDeleteConfirmation()

        // Sanity: ensure flags set
        XCTAssertTrue(router.isNewEntrySheetPresented)
        XCTAssertTrue(router.isEditEntrySheetPresented)
        XCTAssertTrue(router.isMoveEntrySheetPresented)
        XCTAssertTrue(router.isRegenerateInPlaceSheetPresented)
        XCTAssertTrue(router.isDeleteConfirmationPresented)

        router.dismissAll()

        XCTAssertFalse(router.isNewEntrySheetPresented)
        XCTAssertFalse(router.isEditEntrySheetPresented)
        XCTAssertFalse(router.isMoveEntrySheetPresented)
        XCTAssertFalse(router.isRegenerateInPlaceSheetPresented)
        XCTAssertFalse(router.isDeleteConfirmationPresented)
    }

    func testPresentMethodsSetFlags() {
        let router = AppRouter()

        router.presentNewEntry()
        XCTAssertTrue(router.isNewEntrySheetPresented)
        router.dismissAll()

        router.presentEditEntry()
        XCTAssertTrue(router.isEditEntrySheetPresented)
        router.dismissAll()

        router.presentMove()
        XCTAssertTrue(router.isMoveEntrySheetPresented)
        router.dismissAll()

        router.presentRegenerate()
        XCTAssertTrue(router.isRegenerateInPlaceSheetPresented)
        router.dismissAll()

        router.presentDeleteConfirmation()
        XCTAssertTrue(router.isDeleteConfirmationPresented)
    }

    func testSelectFolderAndEntry() {
        let router = AppRouter()

        XCTAssertNil(router.selectedFolder)
        XCTAssertNil(router.selectedEntryID)

        router.selectFolder("work")
        XCTAssertEqual(router.selectedFolder, "work")

        router.selectEntry("work/email")
        XCTAssertEqual(router.selectedEntryID, "work/email")

        // Clearing
        router.selectFolder(nil)
        router.selectEntry(nil)
        XCTAssertNil(router.selectedFolder)
        XCTAssertNil(router.selectedEntryID)
    }
}
