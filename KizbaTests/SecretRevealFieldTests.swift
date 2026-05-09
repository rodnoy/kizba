//
//  SecretRevealFieldTests.swift
//  KizbaTests
//
//  Phase C.2: locks the `SecretRevealField` security and length contract
//  via the pure helpers `maskedLength(for:)` and `displayText(for:isRevealed:)`.
//
//  The most important assertion in this file is the security invariant:
//  when `isRevealed == false`, the rendered string must NOT contain any
//  character of `value`. A regression here (e.g. someone "helpfully"
//  showing the first letter) would silently leak secrets.
//

import XCTest
@testable import Kizba

final class SecretRevealFieldTests: XCTestCase {

    // MARK: - maskedLength: clamping to [8, 32]

    func testSecretRevealField_maskedLength_emptyValueIsClampedToFloorOf8() {
        XCTAssertEqual(SecretRevealField.maskedLength(for: ""), 8)
    }

    func testSecretRevealField_maskedLength_shortValueIsClampedToFloorOf8() {
        XCTAssertEqual(SecretRevealField.maskedLength(for: "abc"), 8)
        XCTAssertEqual(SecretRevealField.maskedLength(for: "1234567"), 8)
    }

    func testSecretRevealField_maskedLength_atFloorBoundaryIsExactly8() {
        XCTAssertEqual(SecretRevealField.maskedLength(for: "12345678"), 8)
    }

    func testSecretRevealField_maskedLength_inRangePassesThrough() {
        XCTAssertEqual(SecretRevealField.maskedLength(for: "p@ssword!"), 9)
        XCTAssertEqual(SecretRevealField.maskedLength(for: String(repeating: "x", count: 12)), 12)
        XCTAssertEqual(SecretRevealField.maskedLength(for: String(repeating: "x", count: 25)), 25)
    }

    func testSecretRevealField_maskedLength_atCeilingBoundaryIsExactly32() {
        XCTAssertEqual(SecretRevealField.maskedLength(for: String(repeating: "x", count: 32)), 32)
    }

    func testSecretRevealField_maskedLength_longValueIsClampedToCeilingOf32() {
        XCTAssertEqual(SecretRevealField.maskedLength(for: String(repeating: "x", count: 50)), 32)
        XCTAssertEqual(SecretRevealField.maskedLength(for: String(repeating: "x", count: 100)), 32)
    }

    // MARK: - displayText: revealed mode is verbatim

    func testSecretRevealField_displayText_whenRevealedReturnsValueExactly() {
        XCTAssertEqual(
            SecretRevealField.displayText(for: "p@ssword!", isRevealed: true),
            "p@ssword!"
        )
        XCTAssertEqual(
            SecretRevealField.displayText(for: "", isRevealed: true),
            ""
        )
        XCTAssertEqual(
            SecretRevealField.displayText(for: "  spaces  ", isRevealed: true),
            "  spaces  "
        )
    }

    // MARK: - displayText: hidden mode is bullet-only

    func testSecretRevealField_displayText_whenHiddenIsBulletOfMaskedLength() {
        let value = "p@ssword!"
        let masked = SecretRevealField.displayText(for: value, isRevealed: false)
        XCTAssertEqual(masked.count, 9)
        XCTAssertTrue(masked.allSatisfy { $0 == "•" })
    }

    func testSecretRevealField_displayText_whenHiddenForShortValueIs8Bullets() {
        let masked = SecretRevealField.displayText(for: "abc", isRevealed: false)
        XCTAssertEqual(masked, String(repeating: "•", count: 8))
    }

    func testSecretRevealField_displayText_whenHiddenForLongValueIs32Bullets() {
        let masked = SecretRevealField.displayText(
            for: String(repeating: "x", count: 100),
            isRevealed: false
        )
        XCTAssertEqual(masked, String(repeating: "•", count: 32))
    }

    func testSecretRevealField_displayText_whenHiddenForEmptyValueIs8Bullets() {
        let masked = SecretRevealField.displayText(for: "", isRevealed: false)
        XCTAssertEqual(masked, String(repeating: "•", count: 8))
    }

    // MARK: - Security invariant

    func testSecretRevealField_displayText_doesNotContainValueWhenHidden() {
        // Critical: the masked render must never expose any character of
        // the secret. We exercise a value with diverse characters so a
        // copy-paste regression that "kept the first letter" or similar
        // would be caught immediately.
        let values = [
            "p@ssword!",
            "correct horse battery staple",
            "1234",
            "🔐secret🔐",
            String(repeating: "Z", count: 40)
        ]
        for value in values {
            let masked = SecretRevealField.displayText(for: value, isRevealed: false)
            for character in value where character != "•" {
                XCTAssertFalse(
                    masked.contains(character),
                    "masked output contained character '\(character)' from value '\(value)'"
                )
            }
        }
    }

    func testSecretRevealField_displayText_maskedAndRevealedDifferForNonEmptyValue() {
        let value = "p@ssword!"
        XCTAssertNotEqual(
            SecretRevealField.displayText(for: value, isRevealed: true),
            SecretRevealField.displayText(for: value, isRevealed: false)
        )
    }
}
