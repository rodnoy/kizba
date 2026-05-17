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

    /// MVP6 Phase G.2 — sanity guard for the two-binding sidebar
    /// routing fix. The sidebar now writes folder taps into
    /// `selectedFolder` and Recents/Favorites taps into
    /// `selectedEntryID` through independent bindings; this test
    /// pins the router contract those bindings rely on: the two
    /// slots are stored independently and mutating one does not
    /// disturb the other. Regression here would mean the bug
    /// G.2 fixed (entry-path written into the folder slot) could
    /// silently return if the router collapsed the two slots.
    func testSelectedEntryID_canBeSetIndependentlyOfSelectedFolder() {
        let router = AppRouter()

        router.selectedFolder = "work"
        router.selectedEntryID = "personal/email"

        XCTAssertEqual(router.selectedFolder, "work")
        XCTAssertEqual(router.selectedEntryID, "personal/email")

        // Clearing the entry must not clear the folder, and vice versa.
        router.selectedEntryID = nil
        XCTAssertEqual(router.selectedFolder, "work")
        XCTAssertNil(router.selectedEntryID)

        router.selectedEntryID = "work/wifi"
        router.selectedFolder = nil
        XCTAssertNil(router.selectedFolder)
        XCTAssertEqual(router.selectedEntryID, "work/wifi")
    }
}
