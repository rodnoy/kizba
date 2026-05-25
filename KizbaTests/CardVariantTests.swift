import SwiftUI
import XCTest
@testable import Kizba

final class CardVariantTests: XCTestCase {

    private static let allVariants: [Theme] = [.light, .dark, .lightHighContrast, .darkHighContrast]

    func testCardTokenAliases_areAliasedToExpectedTokens() {
        for theme in Self.allVariants {
            XCTAssertEqual(theme.colors.surfaceCard, theme.colors.surfaceElevated)
            XCTAssertEqual(theme.colors.surfaceCardHover, theme.colors.surfaceHover)
            XCTAssertEqual(theme.colors.surfaceCardFlat, theme.colors.surfaceCard)
            XCTAssertEqual(theme.colors.surfaceCardFlatHover, theme.colors.surfaceCardHover)
            XCTAssertEqual(theme.colors.surfaceCardInteractive, theme.colors.surfaceCard)
            XCTAssertEqual(theme.colors.surfaceCardInteractiveHover, theme.colors.surfaceCardHover)
        }
    }

    func testCardTokens_onSurface_meet_AAA() {
        for theme in Self.allVariants {
            let r1 = ContrastChecker.contrastRatio(foreground: theme.colors.onSurface, background: theme.colors.surfaceCard)
            XCTAssertGreaterThanOrEqual(r1, 7.0, "onSurface/surfaceCard for \(theme.id) below AAA: \(r1)")

            let r2 = ContrastChecker.contrastRatio(foreground: theme.colors.onSurface, background: theme.colors.surfaceCardFlat)
            XCTAssertGreaterThanOrEqual(r2, 7.0, "onSurface/surfaceCardFlat for \(theme.id) below AAA: \(r2)")

            let r3 = ContrastChecker.contrastRatio(foreground: theme.colors.onSurface, background: theme.colors.surfaceCardInteractive)
            XCTAssertGreaterThanOrEqual(r3, 7.0, "onSurface/surfaceCardInteractive for \(theme.id) below AAA: \(r3)")
        }
    }

    func testCardTokens_onSurfaceMuted_meet_AA() {
        for theme in Self.allVariants {
            let r1 = ContrastChecker.contrastRatio(foreground: theme.colors.onSurfaceMuted, background: theme.colors.surfaceCard)
            XCTAssertGreaterThanOrEqual(r1, 4.5, "onSurfaceMuted/surfaceCard for \(theme.id) below AA: \(r1)")

            let r2 = ContrastChecker.contrastRatio(foreground: theme.colors.onSurfaceMuted, background: theme.colors.surfaceCardFlat)
            XCTAssertGreaterThanOrEqual(r2, 4.5, "onSurfaceMuted/surfaceCardFlat for \(theme.id) below AA: \(r2)")

            let r3 = ContrastChecker.contrastRatio(foreground: theme.colors.onSurfaceMuted, background: theme.colors.surfaceCardInteractive)
            XCTAssertGreaterThanOrEqual(r3, 4.5, "onSurfaceMuted/surfaceCardInteractive for \(theme.id) below AA: \(r3)")
        }
    }
}
