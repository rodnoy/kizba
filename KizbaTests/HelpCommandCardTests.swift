//
//  HelpCommandCardTests.swift
//  KizbaTests
//
//  Pure-helper tests for ``HelpCommandCard`` and the static
//  ``HelpCommands.helpWindowID`` identifier exposed by
//  ``KizbaApp``. Mirrors the project's "test the helpers, not the
//  view" pattern (cf. `EntryRowViewTests`, `BannerViewTests`).
//

import XCTest
@testable import Kizba

final class HelpCommandCardTests: XCTestCase {

    // MARK: - Visible label

    func testCopyButtonLabel_idle_singleCommand_isCopy() {
        XCTAssertEqual(
            HelpCommandCard.copyButtonLabel(commandCount: 1, isCopied: false),
            "Copy"
        )
    }

    func testCopyButtonLabel_idle_multipleCommands_isCopyAll() {
        XCTAssertEqual(
            HelpCommandCard.copyButtonLabel(commandCount: 3, isCopied: false),
            "Copy all"
        )
    }

    func testCopyButtonLabel_copied_anyCount_isCopiedCheck() {
        for count in [0, 1, 5] {
            XCTAssertEqual(
                HelpCommandCard.copyButtonLabel(commandCount: count, isCopied: true),
                "Copied ✓",
                "isCopied=true must win for count=\(count)"
            )
        }
    }

    // MARK: - Accessibility label

    func testAccessibilityLabel_singleCommand_isCopyCommandColon() {
        XCTAssertEqual(
            HelpCommandCard.copyButtonAccessibilityLabel(commands: ["pass ls"]),
            "Copy command: pass ls"
        )
    }

    func testAccessibilityLabel_multipleCommands_isCopyCommandsCount() {
        XCTAssertEqual(
            HelpCommandCard.copyButtonAccessibilityLabel(commands: ["a", "b", "c"]),
            "Copy commands (3)"
        )
    }

    func testAccessibilityLabel_emptyArray_returnsSafeFallback() {
        XCTAssertEqual(
            HelpCommandCard.copyButtonAccessibilityLabel(commands: []),
            "Copy"
        )
    }

    // MARK: - Window id constant

    /// Pins the Help window identifier so the menu item, the
    /// `Window` scene, and any future deep-link share a single
    /// source of truth. Reflectively reads the `private struct`
    /// added to `KizbaApp.swift` via the same `@testable import
    /// Kizba` already used by the rest of the suite.
    func testHelpWindowID_isStableHelp() {
        // `HelpCommands` is a `private struct`, but `@testable
        // import Kizba` exposes internal symbols. The static is
        // `internal` (default) on the type so it is reachable via
        // the type name. If the type is renamed or made truly
        // private, this test will fail to compile — exactly the
        // signal we want.
        XCTAssertEqual(HelpCommands.helpWindowID, "help")
    }
}
