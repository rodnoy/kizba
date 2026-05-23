import SwiftUI
import XCTest
@testable import Kizba

final class KizbaNightContrastTests: XCTestCase {

    private static let futureDarkSurface = Color(hex: 0x111018)

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
}
