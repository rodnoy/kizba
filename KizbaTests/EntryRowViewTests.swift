//
//  EntryRowViewTests.swift
//  KizbaTests
//
//  Phase C.2 (bonus): locks the row background-resolution contract via
//  the pure helper `EntryRowView.backgroundColor(in:isSelected:isHovered:)`.
//
//  Selection always wins over hover; hover only tints non-selected rows;
//  idle rows are transparent so the host list's surface shows through.
//  These rules are deliberately simple but easy to invert by accident in
//  a future refactor — the suite catches that.
//

import SwiftUI
import XCTest
@testable import Kizba

final class EntryRowViewTests: XCTestCase {

    // MARK: - Token resolution per state

    func testEntryRowView_backgroundColor_selectedAndHoveredIsSurfaceSelected() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                EntryRowView.backgroundColor(
                    in: theme,
                    isSelected: true,
                    isHovered: true
                ),
                theme.colors.surfaceSelected,
                "selected+hovered bg in \(theme.id)"
            )
        }
    }

    func testEntryRowView_backgroundColor_selectedNotHoveredIsSurfaceSelected() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                EntryRowView.backgroundColor(
                    in: theme,
                    isSelected: true,
                    isHovered: false
                ),
                theme.colors.surfaceSelected,
                "selected bg in \(theme.id)"
            )
        }
    }

    func testEntryRowView_backgroundColor_hoveredNotSelectedIsSurfaceHover() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                EntryRowView.backgroundColor(
                    in: theme,
                    isSelected: false,
                    isHovered: true
                ),
                theme.colors.surfaceHover,
                "hover bg in \(theme.id)"
            )
        }
    }

    func testEntryRowView_backgroundColor_idleIsClear() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                EntryRowView.backgroundColor(
                    in: theme,
                    isSelected: false,
                    isHovered: false
                ),
                Color.clear,
                "idle bg in \(theme.id)"
            )
        }
    }

    // MARK: - Selection precedence

    func testEntryRowView_backgroundColor_selectionWinsOverHover() {
        // Both flags true → must equal the selected token, not the hover
        // token. Implementation order in `backgroundColor` should reflect
        // this; flipping branches would silently regress the contract.
        for theme in Self.allThemes {
            let both = EntryRowView.backgroundColor(
                in: theme,
                isSelected: true,
                isHovered: true
            )
            XCTAssertEqual(both, theme.colors.surfaceSelected)
            XCTAssertNotEqual(both, theme.colors.surfaceHover)
        }
    }

    // MARK: - Uniqueness

    func testEntryRowView_backgroundColor_threeNonClearStatesAreDistinctPerTheme() {
        // selected, hover, and clear must all be distinct so the user can
        // tell which row is selected vs merely hovered.
        for theme in Self.allThemes {
            let selected = theme.colors.surfaceSelected
            let hover = theme.colors.surfaceHover
            XCTAssertNotEqual(selected, hover, "selected==hover in \(theme.id)")
            XCTAssertNotEqual(selected, Color.clear, "selected==clear in \(theme.id)")
            XCTAssertNotEqual(hover, Color.clear, "hover==clear in \(theme.id)")
        }
    }

    // MARK: - Leading icon (Phase C.6)

    func testEntryRowView_initWithLeadingIconName_compilesAndConstructs() {
        // Surface check: the new `leadingIconName` parameter on
        // `EntryRowView.init` is reachable and has a sensible default
        // (nil → no leading icon, original behaviour). Both shapes must
        // produce a value of the expected type so the call site in
        // `SidebarView` and the legacy call site in `EntryListView`
        // continue to compile.
        let withIcon = EntryRowView(
            leadingIconName: "folder",
            title: "personal",
            isSelected: false
        )
        let withoutIcon = EntryRowView(
            title: "personal",
            isSelected: false
        )
        // Use `_ =` to silence "unused" while still forcing
        // construction; equality on `View` is intentionally not checked
        // (SwiftUI views are not Equatable by default).
        _ = withIcon
        _ = withoutIcon
    }

    func testEntryRowView_backgroundColor_isUnaffectedByLeadingIcon() {
        // The pure helper takes no icon argument by design; this test
        // re-asserts the full state matrix to lock in that the icon
        // parameter is purely visual and cannot leak into selection
        // resolution in a future refactor.
        for theme in Self.allThemes {
            XCTAssertEqual(
                EntryRowView.backgroundColor(in: theme, isSelected: true, isHovered: true),
                theme.colors.surfaceSelected
            )
            XCTAssertEqual(
                EntryRowView.backgroundColor(in: theme, isSelected: true, isHovered: false),
                theme.colors.surfaceSelected
            )
            XCTAssertEqual(
                EntryRowView.backgroundColor(in: theme, isSelected: false, isHovered: true),
                theme.colors.surfaceHover
            )
            XCTAssertEqual(
                EntryRowView.backgroundColor(in: theme, isSelected: false, isHovered: false),
                Color.clear
            )
        }
    }

    // MARK: - Helpers

    private static let allThemes: [Theme] = [
        .light,
        .dark,
        .lightHighContrast,
        .darkHighContrast
    ]
}
