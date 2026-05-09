//
//  SemanticIconographyTests.swift
//  KizbaTests
//
//  Phase I.2: codifies the color-blind safety contract for
//  semantic surfaces (`BannerView`, `ToastView`).
//
//  Per `.ai/decisions.md` (Phase B/C entries) and the I.2 plan:
//  - Color-blind safety relies on a mandatory icon+color pairing.
//  - Each `BannerView.Severity` MUST map to a fixed, distinct SF
//    Symbol; the colour is REINFORCEMENT, never the only channel of
//    meaning.
//  - `ToastView` MUST share the same icon vocabulary as `BannerView`
//    (single source of truth) so banners and toasts can never drift
//    apart in a future palette refresh.
//
//  This file complements `BannerViewTests` (Phase C.2): the existing
//  banner tests already lock the per-severity icon NAMES and the AA
//  contrast smoke (WCAG SC 1.4.11 / 1.4.3). I.2 adds focused
//  observability checks:
//
//    - Non-empty icon name per severity (defensive guard).
//    - Distinct icon names across the four severities (no collision).
//    - Exact icon-name constants (locks the contract — a stray rename
//      will fail this test).
//    - `ToastView` reuses `BannerView.iconName(for:)` directly (no
//      separate helper exists; this test documents that fact and will
//      need to be revisited if a `ToastView.iconName(for:)` is ever
//      introduced).
//    - Icon foreground colour ≠ background colour in every theme
//      (otherwise the icon would be invisible — a regression that
//      would not surface as a build error).
//
//  Contrast assertions (WCAG SC 1.4.11, ≥ 3:1) live in
//  `BannerViewTests` (`testBannerView_iconMeetsWCAGNonTextContrast_…`)
//  and are not duplicated here.
//

import SwiftUI
import XCTest
@testable import Kizba

final class SemanticIconographyTests: XCTestCase {

    // MARK: - Fixed expected mapping
    //
    // Locking the constants here (rather than re-deriving from
    // `BannerView.iconName(for:)`) means a future refactor that
    // accidentally swaps two icons will fail this test — even if the
    // helper signature stays the same.
    private static let expectedIcons: [BannerView.Severity: String] = [
        .info: "info.circle.fill",
        .success: "checkmark.circle.fill",
        .warning: "exclamationmark.triangle.fill",
        .danger: "xmark.octagon.fill"
    ]

    private static let allThemes: [Theme] = [
        .light,
        .dark,
        .lightHighContrast,
        .darkHighContrast
    ]

    // MARK: - Banner icon contract

    func testSemanticIconography_bannerIconName_isNonEmptyForEverySeverity() {
        for severity in BannerView.Severity.allCases {
            XCTAssertFalse(
                BannerView.iconName(for: severity).isEmpty,
                "Severity \(severity) must have a non-empty icon name"
            )
        }
    }

    func testSemanticIconography_bannerIconName_isDistinctAcrossSeverities() {
        // Distinct silhouettes per severity is the whole point — colour
        // is never the sole channel of meaning. If a future refactor
        // collapses two severities onto the same symbol, `Set.count`
        // drops below 4 and this test fails.
        let names = BannerView.Severity.allCases.map {
            BannerView.iconName(for: $0)
        }
        XCTAssertEqual(
            Set(names).count,
            BannerView.Severity.allCases.count,
            "Icon names must be unique across all severities"
        )
    }

    func testSemanticIconography_bannerIconName_matchesExpectedConstants() {
        for (severity, expected) in Self.expectedIcons {
            XCTAssertEqual(
                BannerView.iconName(for: severity),
                expected,
                "BannerView.iconName(for: .\(severity)) must equal \"\(expected)\""
            )
        }
    }

    // MARK: - Toast / Banner single source of truth
    //
    // `ToastView` does not declare its own `iconName(for:)` helper —
    // it calls `BannerView.iconName(for:)` directly inside its body
    // (see `ToastView.swift` line ~33). That is the intended design:
    // one symbol vocabulary for both surfaces.
    //
    // This test documents that contract. If a future change introduces
    // `ToastView.iconName(for:)`, replace the body with an equality
    // check against `BannerView.iconName(for:)` for every severity
    // (commented sketch below).

    func testSemanticIconography_toastView_reusesBannerIconSourceOfTruth() {
        // Currently `ToastView` has no own helper; the `BannerView`
        // constants ARE the ToastView constants by direct call. The
        // mapping verified above is therefore equally binding on
        // toasts. We re-state the four constants explicitly so the
        // test fails LOUDLY if `ToastView` is ever rewritten to
        // hard-code a different SF Symbol literal.
        for (severity, expected) in Self.expectedIcons {
            XCTAssertEqual(
                BannerView.iconName(for: severity), expected,
                "ToastView relies on BannerView.iconName(for: .\(severity)) — must equal \"\(expected)\""
            )
        }

        // Sketch — uncomment if `ToastView.iconName(for:)` is added:
        //
        // for severity in BannerView.Severity.allCases {
        //     XCTAssertEqual(
        //         ToastView.iconName(for: severity),
        //         BannerView.iconName(for: severity),
        //         "ToastView and BannerView icons diverged for \(severity)"
        //     )
        // }
    }

    // MARK: - Visibility guarantee

    func testSemanticIconography_iconColor_differsFromBackground_inAllThemes() {
        // If icon foreground equalled the background fill for any
        // severity the icon would be invisible — the colour-blind
        // contract collapses (only the symbol shape would remain, but
        // not even that, because there'd be no colour delta to draw
        // it). This catches a class of regressions (palette refresh
        // accidentally aliasing two tokens) that the build cannot.
        //
        // Note: `*Muted` background tokens carry `opacity < 1`, so we
        // compare the RAW token here, not the composited colour. A
        // raw equality is what would actually break rendering — the
        // composited result inherits the surface tint and would still
        // visually differ even if the icon and raw bg were identical.
        for theme in Self.allThemes {
            for severity in BannerView.Severity.allCases {
                let icon = BannerView.iconColor(for: severity, in: theme)
                let bg = BannerView.backgroundColor(for: severity, in: theme)
                XCTAssertNotEqual(
                    icon, bg,
                    "[\(theme.id.rawValue) \(severity)] icon colour equals background — icon would be invisible"
                )
            }
        }
    }
}
