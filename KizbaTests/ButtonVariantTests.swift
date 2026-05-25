import SwiftUI
import XCTest
@testable import Kizba

final class ButtonVariantTests: XCTestCase {

    private static let allThemeIDs: [Theme.ID] = [
        .light,
        .lightHighContrast,
        .dark,
        .darkHighContrast
    ]

    func testButtonSecondaryFill_aliasContract() {
        for id in Self.allThemeIDs {
            let theme = Self.theme(for: id)
            XCTAssertEqual(theme.colors.buttonSecondaryFill, theme.colors.surfaceElevated)
        }
    }

    func testButtonGhostPressedFill_aliasContract() {
        for id in Self.allThemeIDs {
            let theme = Self.theme(for: id)
            switch id {
            case .light, .lightHighContrast:
                XCTAssertEqual(theme.colors.buttonGhostPressedFill, theme.colors.surfaceElevated)
            case .dark, .darkHighContrast:
                XCTAssertEqual(theme.colors.buttonGhostPressedFill, theme.colors.surfaceSunken)
            }
        }
    }

    func testContrast_accent_overButtonSecondaryFill_meetsAA() {
        for id in Self.allThemeIDs {
            let theme = Self.theme(for: id)
            let resolvedBackground = ContrastChecker.compositeOver(
                theme.colors.buttonSecondaryFill,
                theme.colors.surface
            )
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.accent,
                background: resolvedBackground
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "accent/buttonSecondaryFill(over surface) for \(id) below AA: \(ratio)"
            )
        }
    }

    func testContrast_accent_overButtonGhostPressedFill_meetsAA() {
        for id in Self.allThemeIDs {
            let theme = Self.theme(for: id)
            let resolvedBackground = ContrastChecker.compositeOver(
                theme.colors.buttonGhostPressedFill,
                theme.colors.surface
            )
            let ratio = ContrastChecker.contrastRatio(
                foreground: theme.colors.accent,
                background: resolvedBackground
            )
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "accent/buttonGhostPressedFill(over surface) for \(id) below AA: \(ratio)"
            )
        }
    }

    private static func theme(for id: Theme.ID) -> Theme {
        switch id {
        case .light:
            return .light
        case .lightHighContrast:
            return .lightHighContrast
        case .dark:
            return .dark
        case .darkHighContrast:
            return .darkHighContrast
        }
    }
}
