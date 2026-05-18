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

    // MARK: - MVP7.F.bugfix: scheme-recovery + custom-key scanning

    /// Simulates `PassShowParser` output for a body containing a bare
    /// `otpauth://totp/...` line. The parser splits on the first ':' and
    /// produces a field `key="otpauth", value="//totp/..."` (scheme lost).
    /// `OTPDiscovery` must recover the scheme and parse the URI.
    func testOtpSecret_bareUriInMetadataValue_schemeRecovered() throws {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(fields: [
                .init(
                    key: "otpauth",
                    value: "//totp/GitHub:ksimagin?secret=ZV42HPXAWPAVMCFB&issuer=GitHub"
                ),
            ])
        )

        let otp = try XCTUnwrap(secret.otpSecret)

        XCTAssertEqual(otp.label, "ksimagin")
        XCTAssertEqual(otp.issuer, "GitHub")
        XCTAssertEqual(otp.secretBase32, "ZV42HPXAWPAVMCFB")
    }

    /// Regression: when the user manually stored the full URI under the
    /// `otpauth` key, the existing happy-path still works (no double scheme).
    func testOtpSecret_fullSchemeInMetadataValue_stillWorks() throws {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(fields: [
                .init(
                    key: "otpauth",
                    value: "otpauth://totp/Acme:bob?secret=JBSWY3DPEHPK3PXP&issuer=Acme"
                ),
            ])
        )

        XCTAssertNotNil(secret.otpSecret)
    }

    /// Forward-looking: user might store the full URI under any key
    /// (e.g. `totp`, `2fa`). The second discovery pass scans non-`otpauth`
    /// fields for values starting with `otpauth://`.
    func testOtpSecret_fullUriUnderCustomMetadataKey_isDiscovered() throws {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(fields: [
                .init(key: "totp", value: "otpauth://totp/X:y?secret=JBSWY3DPEHPK3PXP"),
            ])
        )

        XCTAssertNotNil(secret.otpSecret)
    }
}
