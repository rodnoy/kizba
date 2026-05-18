import XCTest
@testable import Kizba

final class OTPDiscoveryTests: XCTestCase {

    private let validURI = "otpauth://totp/ACME:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=ACME"

    func testOtpSecret_metadataKeyMatch_returnsParsedSecret() throws {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(fields: [
                .init(key: "otpauth", value: validURI),
            ])
        )

        let otp = try XCTUnwrap(secret.otpSecret)

        XCTAssertEqual(otp, try OTPAuthURIParser.parse(validURI))
    }

    func testOtpSecret_extraLineMatch_returnsParsedSecret() throws {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "url", value: "https://example.com")],
                notes: "line 1\n  \(validURI)\nline 3"
            )
        )

        let otp = try XCTUnwrap(secret.otpSecret)

        XCTAssertEqual(otp, try OTPAuthURIParser.parse(validURI))
    }

    func testOtpSecret_metadataWinsWhenBothPresent() throws {
        let metadataURI = "otpauth://totp/Meta:alice?secret=JBSWY3DPEHPK3PXP&issuer=Meta"
        let notesURI = "otpauth://totp/Notes:bob?secret=JBSWY3DPEHPK3PXP&issuer=Notes"
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "otpauth", value: metadataURI)],
                notes: notesURI
            )
        )

        let otp = try XCTUnwrap(secret.otpSecret)

        XCTAssertEqual(otp, try OTPAuthURIParser.parse(metadataURI))
    }

    func testOtpSecret_invalidURIInMetadata_returnsNilSilently() {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(fields: [
                .init(key: "otpauth", value: "otpauth://totp/user?secret=INVALID9"),
            ])
        )

        XCTAssertNil(secret.otpSecret)
    }

    func testOtpSecret_noOTP_returnsNil() {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "alice")],
                notes: "just plain notes"
            )
        )

        XCTAssertNil(secret.otpSecret)
    }

    func testOtpSecret_mixedCaseKey_matchesCaseInsensitively() throws {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(fields: [
                .init(key: "OTPAuth", value: validURI),
            ])
        )

        let otp = try XCTUnwrap(secret.otpSecret)

        XCTAssertEqual(otp, try OTPAuthURIParser.parse(validURI))
    }
}
