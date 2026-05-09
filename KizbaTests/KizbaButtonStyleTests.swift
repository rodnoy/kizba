//
//  KizbaButtonStyleTests.swift
//  KizbaTests
//
//  Phase B.5: locks the per-variant visual contract of `KizbaButtonStyle`
//  in code. SwiftUI button bodies are opaque (no rendering, no snapshot
//  tests in MVP 2 per `.ai/decisions.md`), so coverage targets the pure
//  static helpers extracted in B.4 — `foregroundColor(for:in:)`,
//  `backgroundColor(for:in:isPressed:)`, `font(for:in:)`,
//  `verticalPadding/horizontalPadding/cornerRadius(for:in:)`, plus
//  `disabledOpacity` and `hasAccentBorder(for:)`. The runtime
//  `ButtonContent.body` calls the same helpers, so locking them here
//  locks rendering by extension.
//
//  Tests run for every `Theme.ID` variant so a single regression in any
//  palette is caught by the same suite.
//

import SwiftUI
import XCTest
@testable import Kizba

final class KizbaButtonStyleTests: XCTestCase {

    // MARK: - Variant / Size enumerations

    func testVariant_allCases_containsExactlyFourVariants() {
        XCTAssertEqual(KizbaButtonStyle.Variant.allCases.count, 4)
        XCTAssertEqual(
            Set(KizbaButtonStyle.Variant.allCases),
            Set([.primary, .secondary, .destructive, .ghost])
        )
    }

    func testSize_allCases_containsExactlyTwoSizes() {
        XCTAssertEqual(KizbaButtonStyle.Size.allCases.count, 2)
        XCTAssertEqual(
            Set(KizbaButtonStyle.Size.allCases),
            Set([.regular, .compact])
        )
    }

    // MARK: - Foreground color mapping

    func testForegroundColor_primary_isOnAccentInEveryTheme() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaButtonStyle.foregroundColor(for: .primary, in: theme),
                theme.colors.onAccent,
                "primary fg in \(theme.id)"
            )
        }
    }

    func testForegroundColor_destructive_isOnDangerInEveryTheme() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaButtonStyle.foregroundColor(for: .destructive, in: theme),
                theme.colors.onDanger,
                "destructive fg in \(theme.id)"
            )
        }
    }

    func testForegroundColor_secondary_isAccentInEveryTheme() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaButtonStyle.foregroundColor(for: .secondary, in: theme),
                theme.colors.accent,
                "secondary fg in \(theme.id)"
            )
        }
    }

    func testForegroundColor_ghost_isAccentInEveryTheme() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaButtonStyle.foregroundColor(for: .ghost, in: theme),
                theme.colors.accent,
                "ghost fg in \(theme.id)"
            )
        }
    }

    // MARK: - Background color mapping

    func testBackgroundColor_primary_isAccentInEveryThemeRegardlessOfPress() {
        for theme in Self.allThemes {
            for pressed in [false, true] {
                XCTAssertEqual(
                    KizbaButtonStyle.backgroundColor(
                        for: .primary,
                        in: theme,
                        isPressed: pressed
                    ),
                    theme.colors.accent,
                    "primary bg in \(theme.id), pressed=\(pressed)"
                )
            }
        }
    }

    func testBackgroundColor_destructive_isDangerInEveryThemeRegardlessOfPress() {
        for theme in Self.allThemes {
            for pressed in [false, true] {
                XCTAssertEqual(
                    KizbaButtonStyle.backgroundColor(
                        for: .destructive,
                        in: theme,
                        isPressed: pressed
                    ),
                    theme.colors.danger,
                    "destructive bg in \(theme.id), pressed=\(pressed)"
                )
            }
        }
    }

    func testBackgroundColor_secondary_isSurfaceElevatedInEveryThemeRegardlessOfPress() {
        for theme in Self.allThemes {
            for pressed in [false, true] {
                XCTAssertEqual(
                    KizbaButtonStyle.backgroundColor(
                        for: .secondary,
                        in: theme,
                        isPressed: pressed
                    ),
                    theme.colors.surfaceElevated,
                    "secondary bg in \(theme.id), pressed=\(pressed)"
                )
            }
        }
    }

    func testBackgroundColor_ghost_idleIsClearAndPressedIsLuminanceAwaySurface() {
        // Ghost pressed fill swaps to a luminance-away surface so the
        // accent foreground keeps AA contrast: light themes use
        // `surfaceElevated` (lighter than `surface`), dark themes use
        // `surfaceSunken` (darker than `surface`).
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaButtonStyle.backgroundColor(for: .ghost, in: theme, isPressed: false),
                Color.clear,
                "ghost idle bg in \(theme.id)"
            )
            let expectedPressed: Color
            switch theme.id {
            case .light, .lightHighContrast:
                expectedPressed = theme.colors.surfaceElevated
            case .dark, .darkHighContrast:
                expectedPressed = theme.colors.surfaceSunken
            }
            XCTAssertEqual(
                KizbaButtonStyle.backgroundColor(for: .ghost, in: theme, isPressed: true),
                expectedPressed,
                "ghost pressed bg in \(theme.id)"
            )
        }
    }

    func testBackgroundColor_ghost_pressStateChangesFill() {
        // Non-ghost variants ignore `isPressed` for fill (covered above).
        // Ghost is the only variant where pressed state must visually
        // change the fill — assert the change is real.
        for theme in Self.allThemes {
            let idle = KizbaButtonStyle.backgroundColor(for: .ghost, in: theme, isPressed: false)
            let pressed = KizbaButtonStyle.backgroundColor(for: .ghost, in: theme, isPressed: true)
            XCTAssertNotEqual(
                idle,
                pressed,
                "ghost pressed/idle bg must differ in \(theme.id)"
            )
        }
    }

    // MARK: - Border overlay

    func testHasAccentBorder_onlySecondaryDrawsBorder() {
        XCTAssertTrue(KizbaButtonStyle.hasAccentBorder(for: .secondary))
        XCTAssertFalse(KizbaButtonStyle.hasAccentBorder(for: .primary))
        XCTAssertFalse(KizbaButtonStyle.hasAccentBorder(for: .destructive))
        XCTAssertFalse(KizbaButtonStyle.hasAccentBorder(for: .ghost))
    }

    // MARK: - Font mapping

    func testFont_filledVariants_useBodyEmphasized() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaButtonStyle.font(for: .primary, in: theme),
                theme.typography.bodyEmphasized,
                "primary font in \(theme.id)"
            )
            XCTAssertEqual(
                KizbaButtonStyle.font(for: .destructive, in: theme),
                theme.typography.bodyEmphasized,
                "destructive font in \(theme.id)"
            )
        }
    }

    func testFont_lightVariants_useBody() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaButtonStyle.font(for: .secondary, in: theme),
                theme.typography.body,
                "secondary font in \(theme.id)"
            )
            XCTAssertEqual(
                KizbaButtonStyle.font(for: .ghost, in: theme),
                theme.typography.body,
                "ghost font in \(theme.id)"
            )
        }
    }

    // MARK: - Padding / radius mapping

    func testPadding_regular_mapsToSpacingSmAndLg() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaButtonStyle.verticalPadding(for: .regular, in: theme),
                theme.spacing.sm
            )
            XCTAssertEqual(
                KizbaButtonStyle.horizontalPadding(for: .regular, in: theme),
                theme.spacing.lg
            )
        }
    }

    func testPadding_compact_mapsToSpacingXsAndMd() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaButtonStyle.verticalPadding(for: .compact, in: theme),
                theme.spacing.xs
            )
            XCTAssertEqual(
                KizbaButtonStyle.horizontalPadding(for: .compact, in: theme),
                theme.spacing.md
            )
        }
    }

    func testCornerRadius_regular_isRadiusMd_compactIsRadiusSm() {
        for theme in Self.allThemes {
            XCTAssertEqual(
                KizbaButtonStyle.cornerRadius(for: .regular, in: theme),
                theme.radius.md
            )
            XCTAssertEqual(
                KizbaButtonStyle.cornerRadius(for: .compact, in: theme),
                theme.radius.sm
            )
        }
    }

    // MARK: - Disabled state

    func testDisabledOpacity_isAtMost60Percent() {
        // Phase B.4 picked 0.5; the ceiling is 0.6 per design contract.
        // If a future tweak crosses the ceiling, this test fires.
        XCTAssertLessThanOrEqual(KizbaButtonStyle.disabledOpacity, 0.6)
        XCTAssertGreaterThan(KizbaButtonStyle.disabledOpacity, 0.0)
    }

    // MARK: - Contrast policy (AA, 4.5:1)

    func testContrast_primary_meetsAAInEveryTheme() {
        for theme in Self.allThemes {
            let fg = KizbaButtonStyle.foregroundColor(for: .primary, in: theme)
            let bg = KizbaButtonStyle.backgroundColor(
                for: .primary,
                in: theme,
                isPressed: false
            )
            let ratio = ContrastChecker.contrastRatio(foreground: fg, background: bg)
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "primary fg/bg below AA in \(theme.id): \(ratio)"
            )
        }
    }

    func testContrast_destructive_meetsAAInEveryTheme() {
        for theme in Self.allThemes {
            let fg = KizbaButtonStyle.foregroundColor(for: .destructive, in: theme)
            let bg = KizbaButtonStyle.backgroundColor(
                for: .destructive,
                in: theme,
                isPressed: false
            )
            let ratio = ContrastChecker.contrastRatio(foreground: fg, background: bg)
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "destructive fg/bg below AA in \(theme.id): \(ratio)"
            )
        }
    }

    func testContrast_secondary_meetsAAOnSurfaceElevated() {
        // Secondary fill is the opaque `surfaceElevated`; measure directly.
        for theme in Self.allThemes {
            let fg = KizbaButtonStyle.foregroundColor(for: .secondary, in: theme)
            let bg = KizbaButtonStyle.backgroundColor(
                for: .secondary,
                in: theme,
                isPressed: false
            )
            let ratio = ContrastChecker.contrastRatio(foreground: fg, background: bg)
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "secondary fg/bg below AA in \(theme.id): \(ratio)"
            )
        }
    }

    func testContrast_ghost_idle_meetsAAAgainstSurface() {
        // Ghost idle has a clear fill; measure foreground against the
        // host `surface` which is what users actually see behind it.
        for theme in Self.allThemes {
            let fg = KizbaButtonStyle.foregroundColor(for: .ghost, in: theme)
            let surface = theme.colors.surface
            let ratio = ContrastChecker.contrastRatio(
                foreground: fg,
                background: surface
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "ghost(idle) fg vs surface below AA in \(theme.id): \(ratio)"
            )
        }
    }

    func testContrast_ghost_pressed_meetsAAAgainstLuminanceAwaySurface() {
        // Ghost pressed fill is an opaque, luminance-away surface token
        // (no compositing). Light themes use `surfaceElevated` (lighter
        // than the host `surface`), dark themes use `surfaceSunken`
        // (darker). Both directions push the background away from the
        // accent foreground luminance so AA (4.5:1) holds in every theme.
        for theme in Self.allThemes {
            let fg = KizbaButtonStyle.foregroundColor(for: .ghost, in: theme)
            let bg = KizbaButtonStyle.backgroundColor(
                for: .ghost,
                in: theme,
                isPressed: true
            )
            let ratio = ContrastChecker.contrastRatio(foreground: fg, background: bg)
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "ghost(pressed) fg vs luminance-away surface below AA in \(theme.id): \(ratio)"
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
