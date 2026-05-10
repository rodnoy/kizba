import XCTest
@testable import Kizba

final class SecretRevealFieldAccessibilityTests: XCTestCase {

    func testSecretRevealField_accessibilityValue_reflectsRevealState() {
        XCTAssertEqual(SecretRevealField.accessibilityValueText(isRevealed: true), "Revealed")
        XCTAssertEqual(SecretRevealField.accessibilityValueText(isRevealed: false), "Hidden")
    }
}
