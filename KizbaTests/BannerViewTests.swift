//
//  BannerViewTests.swift
//  KizbaTests
//
//  Phase C.2: locks the per-severity visual contract of `BannerView` in
//  code via the pure helpers `iconName(for:)`, `iconColor(for:in:)`,
//  `backgroundColor(for:in:)`. These same helpers back `ToastView`, so
//  any regression caught here also protects toasts.
//
//  Coverage:
//  - Exact icon-name mapping per severity (color-blind safety contract).
//  - Token resolution for icon foreground and muted background per theme.
//  - Uniqueness within a theme: all four severities have distinct icon
//    names AND distinct icon colors AND distinct background colors —
//    guards against accidental copy-paste in a future palette refresh.
//  - AA contrast smoke test: icon foreground vs muted background ≥ 4.5:1
//    in every theme. Pastel `*Muted` backgrounds against deepened state
//    colors are exactly the kind of pair that can drift; this is where
//    we catch it.
//

import SwiftUI
import XCTest
@testable import Kizba

final class BannerViewTests: XCTestCase {

    // MARK: - Icon name contract

    func testBannerView_iconName_isCorrectPerSeverity() {
        XCTAssertEqual(BannerView.iconName(for: .info), "info.circle.fill")
        XCTAssertEqual(BannerView.iconName(for: .success), "checkmark.circle.fill")
        XCTAssertEqual(BannerView.iconName(for: .warning), "exclamationmark.triangle.fill")
        XCTAssertEqual(BannerView.iconName(for: .danger), "xmark.octagon.fill")
    }

    func testBannerView_iconName_isNonEmptyForEverySeverity() {
        for severity in BannerView.Severity.allCases {
            let name = BannerView.iconName(for: severity)
            XCTAssertFalse(name.isEmpty, "icon name empty for \(severity)")
        }
    }

    func testBannerView_iconName_isUniquePerSeverity() {
        // Distinct silhouettes per severity is the whole point — color is
        // never the sole channel of meaning. Any future copy-paste in
        // `iconName(for:)` would collapse a severity into another.
        let names = BannerView.Severity.allCases.map { BannerView.iconName(for: $0) }
        XCTAssertEqual(Set(names).count, BannerView.Severity.allCases.count)
    }

    // MARK: - Icon color token resolution

    func testBannerView_iconColor_resolvesExpectedTokenPerSeverity() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                BannerView.iconColor(for: .info, in: theme),
                theme.colors.accent,
                "info icon color in \(theme.id)"
            )
            XCTAssertEqual(
                BannerView.iconColor(for: .success, in: theme),
                theme.colors.success,
                "success icon color in \(theme.id)"
            )
            XCTAssertEqual(
                BannerView.iconColor(for: .warning, in: theme),
                theme.colors.warning,
                "warning icon color in \(theme.id)"
            )
            XCTAssertEqual(
                BannerView.iconColor(for: .danger, in: theme),
                theme.colors.danger,
                "danger icon color in \(theme.id)"
            )
        }
    }

    func testBannerView_iconColor_isUniqueAcrossSeveritiesInEveryTheme() {
        for theme in Self.allThemes {
            let colors = BannerView.Severity.allCases.map {
                BannerView.iconColor(for: $0, in: theme)
            }
            XCTAssertEqual(
                Set(colors).count,
                BannerView.Severity.allCases.count,
                "icon colors collide in \(theme.id)"
            )
        }
    }

    // MARK: - Background color token resolution

    func testBannerView_backgroundColor_resolvesExpectedTokenPerSeverity() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                BannerView.backgroundColor(for: .info, in: theme),
                theme.colors.surfaceElevated,
                "info bg in \(theme.id)"
            )
            XCTAssertEqual(
                BannerView.backgroundColor(for: .success, in: theme),
                theme.colors.successMuted,
                "success bg in \(theme.id)"
            )
            XCTAssertEqual(
                BannerView.backgroundColor(for: .warning, in: theme),
                theme.colors.warningMuted,
                "warning bg in \(theme.id)"
            )
            XCTAssertEqual(
                BannerView.backgroundColor(for: .danger, in: theme),
                theme.colors.dangerMuted,
                "danger bg in \(theme.id)"
            )
        }
    }

    func testBannerView_backgroundColor_isUniqueAcrossSeveritiesInEveryTheme() {
        for theme in Self.allThemes {
            let backgrounds = BannerView.Severity.allCases.map {
                BannerView.backgroundColor(for: $0, in: theme)
            }
            XCTAssertEqual(
                Set(backgrounds).count,
                BannerView.Severity.allCases.count,
                "background colors collide in \(theme.id)"
            )
        }
    }

    // MARK: - Severity enumeration

    func testBannerView_severity_allCasesContainsExactlyFour() {
        XCTAssertEqual(BannerView.Severity.allCases.count, 4)
        XCTAssertEqual(
            Set(BannerView.Severity.allCases),
            Set([.info, .success, .warning, .danger])
        )
    }

    // MARK: - Contrast smoke (WCAG)
    //
    // The banner's icon is a graphical object (WCAG SC 1.4.11 Non-text
    // Contrast, AA, ≥ 3:1) and the body label is informational text
    // (WCAG SC 1.4.3 Contrast Minimum, AA, ≥ 4.5:1). Both must clear
    // their thresholds against the *composited* muted background — the
    // raw `*Muted` token carries `opacity < 1`, so it is alpha-composited
    // over `surface` first (matching real rendering) before measurement.
    //
    // The `info` severity uses `surfaceElevated` (already opaque) as its
    // background; compositing it over `surface` is a no-op and the
    // helper happily handles that path too.

    func testBannerView_iconMeetsWCAGNonTextContrast_inAllThemes() {
        for theme in Self.allThemes {
            for severity in BannerView.Severity.allCases {
                let icon = BannerView.iconColor(for: severity, in: theme)
                let bgRaw = BannerView.backgroundColor(for: severity, in: theme)
                let bg = ContrastChecker.compositeOver(bgRaw, theme.colors.surface)
                let ratio = ContrastChecker.contrastRatio(foreground: icon, background: bg)
                XCTAssertGreaterThanOrEqual(
                    ratio, 3.0,
                    "[\(theme.id.rawValue) \(severity)] icon ratio \(ratio) < 3.0 (WCAG SC 1.4.11)"
                )
            }
        }
    }

    func testBannerView_bodyTextMeetsWCAGContrast_inAllThemes() {
        for theme in Self.allThemes {
            for severity in BannerView.Severity.allCases {
                let bgRaw = BannerView.backgroundColor(for: severity, in: theme)
                let bg = ContrastChecker.compositeOver(bgRaw, theme.colors.surface)
                let ratio = ContrastChecker.contrastRatio(
                    foreground: theme.colors.onSurface,
                    background: bg
                )
                XCTAssertGreaterThanOrEqual(
                    ratio, 4.5,
                    "[\(theme.id.rawValue) \(severity)] body text ratio \(ratio) < 4.5 (WCAG SC 1.4.3)"
                )
            }
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
