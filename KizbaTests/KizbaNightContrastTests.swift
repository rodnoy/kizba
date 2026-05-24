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

    func testKizbaNight_highContrast_doesNotRegressAnyBodyContrast() {
        let pairs: [(standard: Theme, hc: Theme)] = [(.light, .lightHighContrast), (.dark, .darkHighContrast)]

        for (standard, hc) in pairs {
            // onSurface / surface
            let standard_onSurface = ContrastChecker.contrastRatio(
                foreground: standard.colors.onSurface,
                background: standard.colors.surface
            )
            let hc_onSurface = ContrastChecker.contrastRatio(
                foreground: hc.colors.onSurface,
                background: hc.colors.surface
            )
            XCTAssertGreaterThanOrEqual(
                hc_onSurface,
                standard_onSurface - 1e-9,
                "HC \(hc.id) regressed onSurface/surface: standard=\(standard_onSurface), hc=\(hc_onSurface)"
            )

            // onSurfaceMuted / surface
            let standard_onSurfaceMuted = ContrastChecker.contrastRatio(
                foreground: standard.colors.onSurfaceMuted,
                background: standard.colors.surface
            )
            let hc_onSurfaceMuted = ContrastChecker.contrastRatio(
                foreground: hc.colors.onSurfaceMuted,
                background: hc.colors.surface
            )
            XCTAssertGreaterThanOrEqual(
                hc_onSurfaceMuted,
                standard_onSurfaceMuted - 1e-9,
                "HC \(hc.id) regressed onSurfaceMuted/surface: standard=\(standard_onSurfaceMuted), hc=\(hc_onSurfaceMuted)"
            )

            // onAccent / accent
            let standard_onAccent = ContrastChecker.contrastRatio(
                foreground: standard.colors.onAccent,
                background: standard.colors.accent
            )
            let hc_onAccent = ContrastChecker.contrastRatio(
                foreground: hc.colors.onAccent,
                background: hc.colors.accent
            )
            XCTAssertGreaterThanOrEqual(
                hc_onAccent,
                standard_onAccent - 1e-9,
                "HC \(hc.id) regressed onAccent/accent: standard=\(standard_onAccent), hc=\(hc_onAccent)"
            )

            // password reveal (onSurface over secretMask composited over surface)
            let standard_passwordReveal = ContrastChecker.contrastRatio(
                foreground: standard.colors.onSurface,
                background: standard.colors.secretMask,
                alphaCompositedOver: standard.colors.surface
            )
            let hc_passwordReveal = ContrastChecker.contrastRatio(
                foreground: hc.colors.onSurface,
                background: hc.colors.secretMask,
                alphaCompositedOver: hc.colors.surface
            )
            XCTAssertGreaterThanOrEqual(
                hc_passwordReveal,
                standard_passwordReveal - 1e-9,
                "HC \(hc.id) regressed passwordReveal: standard=\(standard_passwordReveal), hc=\(hc_passwordReveal)"
            )
        }
    }
}
