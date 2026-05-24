import SwiftUI
import XCTest
@testable import Kizba

final class KizbaNightContrastTests: XCTestCase {

    private static let futureDarkSurface = Color(hex: 0x111018)
    private static let allVariants: [Theme] = [.light, .dark, .lightHighContrast, .darkHighContrast]

    func testSmoke_referencesStep1Tokens() {
        let themes: [Theme] = [.light, .dark, .lightHighContrast, .darkHighContrast]

        for theme in themes {
            _ = theme.colors.surfaceCard
            _ = theme.colors.surfaceCardHover
            _ = theme.colors.accentSecondary
            _ = theme.colors.accentStrong
        }

        _ = Self.futureDarkSurface
    }

    func testKizbaNight_onSurface_and_onSurface_over_surface_and_surfaceCard_meet_contrast_requirements() {
        for theme in Self.allVariants {
            let ratioSurface = ContrastChecker.contrastRatio(
                foreground: theme.colors.onSurface,
                background: theme.colors.surface
            )
            XCTAssertGreaterThanOrEqual(ratioSurface, 7.0, "onSurface/surface for \(theme.id) below AAA: \(ratioSurface)")

            let ratioCard = ContrastChecker.contrastRatio(
                foreground: theme.colors.onSurface,
                background: theme.colors.surfaceCard
            )
            XCTAssertGreaterThanOrEqual(ratioCard, 7.0, "onSurface/surfaceCard for \(theme.id) below AAA: \(ratioCard)")
        }
    }

    func testKizbaNight_onSurfaceMuted_over_surface_and_surfaceCard_meet_AA() {
        for theme in Self.allVariants {
            let ratioSurface = ContrastChecker.contrastRatio(
                foreground: theme.colors.onSurfaceMuted,
                background: theme.colors.surface
            )
            XCTAssertGreaterThanOrEqual(ratioSurface, 4.5, "onSurfaceMuted/surface for \(theme.id) below AA: \(ratioSurface)")

            let ratioCard = ContrastChecker.contrastRatio(
                foreground: theme.colors.onSurfaceMuted,
                background: theme.colors.surfaceCard
            )
            XCTAssertGreaterThanOrEqual(ratioCard, 4.5, "onSurfaceMuted/surfaceCard for \(theme.id) below AA: \(ratioCard)")
        }
    }

    func testKizbaNight_onAccent_against_accent_and_accentSecondary_meet_AA() {
        for theme in Self.allVariants {
            let ratioAccent = ContrastChecker.contrastRatio(
                foreground: theme.colors.onAccent,
                background: theme.colors.accent
            )
            XCTAssertGreaterThanOrEqual(
                ratioAccent,
                4.5,
                "onAccent/accent for \(theme.id) below AA: \(ratioAccent)"
            )

            let ratioAccentSecondary = ContrastChecker.contrastRatio(
                foreground: theme.colors.onAccent,
                background: theme.colors.accentSecondary
            )
            XCTAssertGreaterThanOrEqual(
                ratioAccentSecondary,
                4.5,
                "onAccent/accentSecondary for \(theme.id) below AA: \(ratioAccentSecondary)"
            )
        }
    }

    func testKizbaNight_onSurface_against_accentMuted_composited_meet_AA() {
        for theme in Self.allVariants {
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.onSurface,
                background: theme.colors.accentMuted,
                alphaCompositedOver: theme.colors.surface
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "onSurface/accentMuted(over surface) for \(theme.id) below AA: \(ratio)"
            )
        }
    }

    func testKizbaNight_passwordReveal_secretMask_meets_AAA() {
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
}
