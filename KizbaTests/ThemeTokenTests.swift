//
//  ThemeTokenTests.swift
//  KizbaTests
//
//  Phase B.3: locks the design system's contrast policy and token
//  integrity in code. Every `XCTAssert*` here exists to catch a
//  specific class of regression:
//
//  - `ContrastChecker` math correctness (sanity vs known black/white).
//  - Token identity: variants are distinct, no accidental copy-paste
//    duplication of role colors within a variant.
//  - WCAG ratios: AA (4.5:1) for body / on-fill text, AAA (7:1) for
//    `onSurface` body and password-reveal mono on `secretMask`,
//    3:1 for the focus-ring against both `surface` and `accent`.
//  - HighContrast non-regression: every contrast metric for the
//    high-contrast variant is `>=` its standard counterpart.
//  - Spacing / radius / motion shape: numeric values match the spec
//    in `.ai/plan.md`; reduce-motion suppresses animation.
//
//  When tightening the policy, prefer adding a new metric over editing
//  the threshold of an existing one — failures are signal.
//

import SwiftUI
import XCTest
@testable import Kizba

final class ThemeTokenTests: XCTestCase {

    // MARK: - ContrastChecker self-test

    func testContrastChecker_blackOnWhiteIsApproximately21() {
        let ratio = ContrastChecker.contrastRatio(
            foreground: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1),
            background: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        )
        XCTAssertEqual(ratio, 21.0, accuracy: 0.01)
    }

    func testContrastChecker_whiteOnWhiteIsExactly1() {
        let white = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        let ratio = ContrastChecker.contrastRatio(foreground: white, background: white)
        XCTAssertEqual(ratio, 1.0, accuracy: 0.0001)
    }

    func testContrastChecker_isSymmetric() {
        let a = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.6, opacity: 1)
        let b = Color(.sRGB, red: 0.9, green: 0.85, blue: 0.7, opacity: 1)
        let ab = ContrastChecker.contrastRatio(foreground: a, background: b)
        let ba = ContrastChecker.contrastRatio(foreground: b, background: a)
        XCTAssertEqual(ab, ba, accuracy: 0.0001)
    }

    func testContrastChecker_compositingFullyOpaqueOverIsIdentity() {
        // A fully opaque foreground composited over anything should
        // produce a color whose contrast against `surface` matches the
        // raw foreground's contrast against `surface`.
        let opaque = Color(hex: 0x1F1B2E)
        let surface = Color(hex: 0xFBF7FB)
        let raw = ContrastChecker.contrastRatio(foreground: opaque, background: surface)
        let composited = ContrastChecker.contrastRatio(
            foreground: opaque,
            background: surface,
            alphaCompositedOver: surface
        )
        XCTAssertEqual(raw, composited, accuracy: 0.01)
    }

    // MARK: - Theme.ID + variant integrity

    func testTheme_ID_hasExactlyFourCases() {
        XCTAssertEqual(Theme.ID.allCases.count, 4)
        XCTAssertEqual(
            Set(Theme.ID.allCases),
            Set([.light, .dark, .lightHighContrast, .darkHighContrast])
        )
    }

    func testTheme_allVariants_haveCorrectIDWiring() {
        XCTAssertEqual(Theme.light.id, .light)
        XCTAssertEqual(Theme.dark.id, .dark)
        XCTAssertEqual(Theme.lightHighContrast.id, .lightHighContrast)
        XCTAssertEqual(Theme.darkHighContrast.id, .darkHighContrast)
    }

    func testTheme_equality_sameVariantIsEqual_differentVariantsAreNot() {
        XCTAssertEqual(Theme.light, Theme.light)
        XCTAssertEqual(Theme.dark, Theme.dark)

        XCTAssertNotEqual(Theme.light, Theme.dark)
        XCTAssertNotEqual(Theme.light, Theme.lightHighContrast)
        XCTAssertNotEqual(Theme.dark, Theme.darkHighContrast)
        XCTAssertNotEqual(Theme.lightHighContrast, Theme.darkHighContrast)
    }

    func testTheme_equality_freshlyConstructedMatchesStaticConstant() {
        let rebuilt = Theme(
            id: .light,
            colors: .light,
            spacing: .default,
            radius: .default,
            typography: .default,
            motion: .default
        )
        XCTAssertEqual(rebuilt, Theme.light)
    }

    // MARK: - Color identity (anti-copy-paste guards)

    func testTheme_light_roleColorsAreDistinct() {
        let c = Theme.light.colors
        XCTAssertNotEqual(c.surface, c.onSurface)
        XCTAssertNotEqual(c.accent, c.danger)
        XCTAssertNotEqual(c.accent, c.success)
        XCTAssertNotEqual(c.accent, c.warning)
        XCTAssertNotEqual(c.danger, c.success)
        XCTAssertNotEqual(c.danger, c.warning)
        XCTAssertNotEqual(c.success, c.warning)
        XCTAssertNotEqual(c.surfaceHover, c.surfaceSelected)
    }

    func testTheme_dark_roleColorsAreDistinct() {
        let c = Theme.dark.colors
        XCTAssertNotEqual(c.surface, c.onSurface)
        XCTAssertNotEqual(c.accent, c.danger)
        XCTAssertNotEqual(c.accent, c.success)
        XCTAssertNotEqual(c.accent, c.warning)
        XCTAssertNotEqual(c.danger, c.success)
        XCTAssertNotEqual(c.danger, c.warning)
        XCTAssertNotEqual(c.success, c.warning)
        XCTAssertNotEqual(c.surfaceHover, c.surfaceSelected)
    }

    func testTheme_highContrast_mutedTextIsDeliberatelyEqualToOnSurface() {
        // In both high-contrast variants `onSurfaceMuted` is intentionally
        // promoted to `onSurface` so muted body copy reaches AAA. This is
        // *not* a copy-paste mistake; the test exists to lock the choice.
        XCTAssertEqual(
            Theme.lightHighContrast.colors.onSurfaceMuted,
            Theme.lightHighContrast.colors.onSurface
        )
        XCTAssertEqual(
            Theme.darkHighContrast.colors.onSurfaceMuted,
            Theme.darkHighContrast.colors.onSurface
        )
    }

    // MARK: - Body contrast (AAA on `onSurface`, AA on `onSurfaceMuted`)

    func testTheme_allVariants_onSurfaceMeetsAAA_7to1() {
        for theme in Self.allVariants {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.onSurface,
                background: theme.colors.surface
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                7.0,
                "onSurface/surface for \(theme.id) below AAA: \(ratio)"
            )
        }
    }

    func testTheme_allVariants_onSurfaceMutedMeetsAA_4_5to1() {
        for theme in Self.allVariants {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.onSurfaceMuted,
                background: theme.colors.surface
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "onSurfaceMuted/surface for \(theme.id) below AA: \(ratio)"
            )
        }
    }

    func testTheme_highContrast_onSurfaceMutedMeetsAAA_7to1() {
        // HC variants promote muted to full body; ratio must clear AAA.
        for theme in [Theme.lightHighContrast, Theme.darkHighContrast] {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.onSurfaceMuted,
                background: theme.colors.surface
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                7.0,
                "HC onSurfaceMuted/surface for \(theme.id) below AAA: \(ratio)"
            )
        }
    }

    // MARK: - Action-fill contrast (AA: text on accent / danger / success / warning)

    func testTheme_allVariants_onAccentMeetsAA() {
        for theme in Self.allVariants {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.onAccent,
                background: theme.colors.accent
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "onAccent/accent for \(theme.id) below AA: \(ratio)"
            )
        }
    }

    func testTheme_allVariants_onDangerMeetsAA() {
        for theme in Self.allVariants {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.onDanger,
                background: theme.colors.danger
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "onDanger/danger for \(theme.id) below AA: \(ratio)"
            )
        }
    }

    func testTheme_allVariants_onSuccessMeetsAA() {
        for theme in Self.allVariants {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.onSuccess,
                background: theme.colors.success
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "onSuccess/success for \(theme.id) below AA: \(ratio)"
            )
        }
    }

    func testTheme_allVariants_onWarningMeetsAA() {
        for theme in Self.allVariants {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.onWarning,
                background: theme.colors.warning
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "onWarning/warning for \(theme.id) below AA: \(ratio)"
            )
        }
    }

    // MARK: - Password reveal (AAA: mono on `secretMask` over `surface`)

    func testTheme_allVariants_passwordRevealMeetsAAA_7to1() {
        for theme in Self.allVariants {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.onSurface,
                background: theme.colors.secretMask,
                alphaCompositedOver: theme.colors.surface
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                7.0,
                "onSurface/secretMask(over surface) for \(theme.id) below AAA: \(ratio)"
            )
        }
    }

    // MARK: - Focus ring (two-tone: 3:1 outer-vs-surface, 3:1 inner-vs-outer,
    //                                3:1 inner-vs-accent)

    func testTheme_allVariants_focusRingOuterIsVisibleOnSurface() {
        // The outer band must read against adjacent chrome.
        for theme in Self.allVariants {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.focusRingOuter,
                background: theme.colors.surface
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                3.0,
                "focusRingOuter/surface for \(theme.id) below 3:1: \(ratio)"
            )
        }
    }

    func testTheme_allVariants_focusRingInnerIsVisibleOnRing() {
        // The inner core must structurally split the ring itself, so the
        // two-tone shape stays legible regardless of background.
        for theme in Self.allVariants {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.focusRingInner,
                background: theme.colors.focusRingOuter
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                3.0,
                "focusRingInner/focusRingOuter for \(theme.id) below 3:1: \(ratio)"
            )
        }
    }

    func testTheme_allVariants_focusRingInnerIsVisibleOnAccent() {
        // When the ring overlays a primary action fill, the inner core
        // is the stripe that anchors visibility; it must clear 3:1
        // against the accent.
        for theme in Self.allVariants {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.focusRingInner,
                background: theme.colors.accent
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                3.0,
                "focusRingInner/accent for \(theme.id) below 3:1: \(ratio)"
            )
        }
    }

    // MARK: - HighContrast non-regression

    func testTheme_highContrast_doesNotRegressAnyBodyContrast() {
        // Every metric we lock for the standard variants must hold or
        // improve in the matching HC variant. A regression here means
        // the HC palette was edited without re-checking the policy.
        let pairs: [(standard: Theme, hc: Theme)] = [
            (.light, .lightHighContrast),
            (.dark, .darkHighContrast)
        ]

        for (standard, hc) in pairs {
            assertNoRegression(
                metric: "onSurface/surface",
                standard: ContrastChecker.contrastRatio(
                    foreground: standard.colors.onSurface,
                    background: standard.colors.surface
                ),
                hc: ContrastChecker.contrastRatio(
                    foreground: hc.colors.onSurface,
                    background: hc.colors.surface
                ),
                hcID: hc.id
            )

            assertNoRegression(
                metric: "onSurfaceMuted/surface",
                standard: ContrastChecker.contrastRatio(
                    foreground: standard.colors.onSurfaceMuted,
                    background: standard.colors.surface
                ),
                hc: ContrastChecker.contrastRatio(
                    foreground: hc.colors.onSurfaceMuted,
                    background: hc.colors.surface
                ),
                hcID: hc.id
            )

            assertNoRegression(
                metric: "onAccent/accent",
                standard: ContrastChecker.contrastRatio(
                    foreground: standard.colors.onAccent,
                    background: standard.colors.accent
                ),
                hc: ContrastChecker.contrastRatio(
                    foreground: hc.colors.onAccent,
                    background: hc.colors.accent
                ),
                hcID: hc.id
            )

            assertNoRegression(
                metric: "passwordReveal",
                standard: ContrastChecker.contrastRatio(
                    foreground: standard.colors.onSurface,
                    background: standard.colors.secretMask,
                    alphaCompositedOver: standard.colors.surface
                ),
                hc: ContrastChecker.contrastRatio(
                    foreground: hc.colors.onSurface,
                    background: hc.colors.secretMask,
                    alphaCompositedOver: hc.colors.surface
                ),
                hcID: hc.id
            )

            // Focus-ring tokens are intentionally not compared
            // numerically across standard vs HC: HC swaps the ring's
            // hue family (e.g. azure ↔ sky-blue) so per-pair ratios
            // can shift in either direction. HC instead must
            // independently satisfy the three ring assertions
            // (outer/surface, inner/outer, inner/accent), which the
            // dedicated focus-ring tests above already enforce.
        }
    }

    // MARK: - Spacing / radius / motion sanity

    func testTheme_spacing_matchesPlanValues() {
        let s = Theme.light.spacing
        XCTAssertEqual(s.xs, 4)
        XCTAssertEqual(s.sm, 8)
        XCTAssertEqual(s.md, 12)
        XCTAssertEqual(s.lg, 16)
        XCTAssertEqual(s.xl, 24)
        XCTAssertEqual(s.xxl, 32)
    }

    func testTheme_radius_matchesPlanValues() {
        let r = Theme.light.radius
        XCTAssertEqual(r.sm, 6)
        XCTAssertEqual(r.md, 10)
        XCTAssertEqual(r.lg, 14)
        XCTAssertEqual(r.pill, 999)
    }

    func testTheme_motion_instantOrReduceMotionSuppressesAnimation() {
        let m = Theme.light.motion
        // `.instant` always yields nil regardless of reduce-motion.
        XCTAssertNil(m.animation(.instant, reduceMotion: false))
        XCTAssertNil(m.animation(.instant, reduceMotion: true))
        // Reduce-motion suppresses every other token too.
        for token in MotionToken.allCases {
            XCTAssertNil(
                m.animation(token, reduceMotion: true),
                "reduceMotion did not suppress \(token)"
            )
        }
    }

    func testTheme_motion_nonInstantTokensProduceAnimationWhenReduceMotionOff() {
        let m = Theme.light.motion
        XCTAssertNotNil(m.animation(.quick, reduceMotion: false))
        XCTAssertNotNil(m.animation(.standard, reduceMotion: false))
        XCTAssertNotNil(m.animation(.emphasized, reduceMotion: false))
    }

    // MARK: - Helpers

    private static let allVariants: [Theme] = [
        .light,
        .dark,
        .lightHighContrast,
        .darkHighContrast
    ]

    private func assertNoRegression(
        metric: String,
        standard: Double,
        hc: Double,
        hcID: Theme.ID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Allow a tiny epsilon so that floating-point noise in the
        // luminance pipeline doesn't trip the comparison when the HC
        // variant intentionally reuses the same hex (e.g. on-fill text
        // that already maxes at white).
        XCTAssertGreaterThanOrEqual(
            hc,
            standard - 1e-9,
            "HC \(hcID) regressed \(metric): standard=\(standard), hc=\(hc)",
            file: file,
            line: line
        )
    }
}
