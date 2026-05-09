//
//  KizbaFocusRingTests.swift
//  KizbaTests
//
//  Phase B.5 (bonus): locks the geometry + token resolution of the
//  `KizbaFocusRing` modifier via its pure static helpers.
//  `ThemeTokenTests` already covers the contrast policy of the
//  `focusRingOuter` / `focusRingInner` tokens themselves (≥3:1 vs
//  surface, vs each other, vs accent); this file complements that by
//  asserting the modifier wires up to those exact tokens, plus the
//  inner-radius math.
//

import SwiftUI
import XCTest
@testable import Kizba

final class KizbaFocusRingTests: XCTestCase {

    // MARK: - Token resolution

    func testOuterColor_isFocusRingOuterInEveryTheme() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaFocusRing.outerColor(in: theme),
                theme.colors.focusRingOuter,
                "outer color in \(theme.id)"
            )
        }
    }

    func testInnerColor_isFocusRingInnerInEveryTheme() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaFocusRing.innerColor(in: theme),
                theme.colors.focusRingInner,
                "inner color in \(theme.id)"
            )
        }
    }

    // MARK: - Inner-radius math

    func testInnerCornerRadius_normalGeometry_subtractsOuterWidth() {
        XCTAssertEqual(
            KizbaFocusRing.innerCornerRadius(outerCornerRadius: 10, outerWidth: 2),
            8
        )
        XCTAssertEqual(
            KizbaFocusRing.innerCornerRadius(outerCornerRadius: 14, outerWidth: 2),
            12
        )
    }

    func testInnerCornerRadius_clampsAtZero_whenOuterRadiusIsTooSmall() {
        // Outer radius 1pt with a 2pt outer width would compute -1;
        // the helper clamps at 0 so SwiftUI never sees a negative.
        XCTAssertEqual(
            KizbaFocusRing.innerCornerRadius(outerCornerRadius: 1, outerWidth: 2),
            0
        )
        XCTAssertEqual(
            KizbaFocusRing.innerCornerRadius(outerCornerRadius: 0, outerWidth: 2),
            0
        )
    }

    func testInnerCornerRadius_zeroOuterWidth_returnsOuterRadius() {
        XCTAssertEqual(
            KizbaFocusRing.innerCornerRadius(outerCornerRadius: 10, outerWidth: 0),
            10
        )
    }

    // MARK: - Helpers

    private static let allThemes: [Theme] = [
        .light,
        .dark,
        .lightHighContrast,
        .darkHighContrast
    ]
}
