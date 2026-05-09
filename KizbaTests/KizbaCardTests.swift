//
//  KizbaCardTests.swift
//  KizbaTests
//
//  Phase B.5: locks the visual contract of `KizbaCard` in code via the
//  pure static helpers extracted in B.4 (`backgroundColor(in:)`,
//  `borderColor(in:)`, `cornerRadius(in:)`, `padding(in:)`). The runtime
//  `body` calls the same helpers, so these tests cover rendering by
//  proxy — no SwiftUI snapshot tests are used (per `.ai/decisions.md`).
//

import SwiftUI
import XCTest
@testable import Kizba

final class KizbaCardTests: XCTestCase {

    // MARK: - Token resolution

    func testBackgroundColor_isSurfaceElevatedInEveryTheme() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaCard<EmptyView>.backgroundColor(in: theme),
                theme.colors.surfaceElevated,
                "card bg in \(theme.id)"
            )
        }
    }

    func testBorderColor_isDividerInEveryTheme() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaCard<EmptyView>.borderColor(in: theme),
                theme.colors.divider,
                "card border in \(theme.id)"
            )
        }
    }

    func testCornerRadius_isRadiusLgInEveryTheme() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaCard<EmptyView>.cornerRadius(in: theme),
                theme.radius.lg,
                "card radius in \(theme.id)"
            )
        }
    }

    func testPadding_isSpacingLgInEveryTheme() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaCard<EmptyView>.padding(in: theme),
                theme.spacing.lg,
                "card padding in \(theme.id)"
            )
        }
    }

    // MARK: - Contrast policy

    func testContrast_onSurfaceVsCardBackground_meetsAAInEveryTheme() {
        // Cards host body text (via consumers like SecretRevealField,
        // FormSection). The card's own background must satisfy AA
        // against `onSurface` so any text placed on it is legible.
        for theme in Self.allThemes {
            let bg = KizbaCard<EmptyView>.backgroundColor(in: theme)
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.onSurface,
                background: bg
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "onSurface/cardBg below AA in \(theme.id): \(ratio)"
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
