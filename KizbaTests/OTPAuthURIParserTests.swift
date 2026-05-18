import XCTest
@testable import Kizba

final class OTPAuthURIParserTests: XCTestCase {

    func testParse_rfcSample_totp() throws {
        let uri = "otpauth://totp/ACME:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=ACME"

        let parsed = try OTPAuthURIParser.parse(uri)

        XCTAssertEqual(parsed.kind, .totp(period: 30))
        XCTAssertEqual(parsed.algorithm, .sha1)
        XCTAssertEqual(parsed.digits, 6)
        XCTAssertEqual(parsed.secretBase32, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(parsed.issuer, "ACME")
        XCTAssertEqual(parsed.label, "alice@google.com")
    }

    func testParse_hotp_withCounter() throws {
        let uri = "otpauth://hotp/Example:user?secret=JBSWY3DPEHPK3PXP&counter=7"

        let parsed = try OTPAuthURIParser.parse(uri)

        XCTAssertEqual(parsed.kind, .hotp(counter: 7))
        XCTAssertEqual(parsed.algorithm, .sha1)
        XCTAssertEqual(parsed.digits, 6)
        XCTAssertEqual(parsed.issuer, "Example")
        XCTAssertEqual(parsed.label, "user")
    }

    func testParse_missingSecret_throws() {
        let uri = "otpauth://totp/ACME:alice@google.com?issuer=ACME"
        XCTAssertThrowsError(try OTPAuthURIParser.parse(uri)) { error in
            XCTAssertEqual(error as? OTPAuthURIParserError, .missingSecret)
        }
    }

    func testParse_invalidScheme_throws() {
        let uri = "https://totp/ACME:alice@google.com?secret=JBSWY3DPEHPK3PXP"
        XCTAssertThrowsError(try OTPAuthURIParser.parse(uri)) { error in
            XCTAssertEqual(error as? OTPAuthURIParserError, .invalidScheme)
        }
    }

    func testParse_unsupportedHost_throws() {
        let uri = "otpauth://steam/ACME:alice@google.com?secret=JBSWY3DPEHPK3PXP"
        XCTAssertThrowsError(try OTPAuthURIParser.parse(uri)) { error in
            XCTAssertEqual(error as? OTPAuthURIParserError, .unsupportedKind("steam"))
        }
    }

    func testParse_customPeriod60_sha512_digits8() throws {
        let uri = "otpauth://totp/user?secret=JBSWY3DPEHPK3PXP&period=60&algorithm=SHA512&digits=8"

        let parsed = try OTPAuthURIParser.parse(uri)

        XCTAssertEqual(parsed.kind, .totp(period: 60))
        XCTAssertEqual(parsed.algorithm, .sha512)
        XCTAssertEqual(parsed.digits, 8)
    }

    func testParse_digits5_throws() {
        let uri = "otpauth://totp/user?secret=JBSWY3DPEHPK3PXP&digits=5"
        XCTAssertThrowsError(try OTPAuthURIParser.parse(uri)) { error in
            XCTAssertEqual(error as? OTPAuthURIParserError, .invalidDigits)
        }
    }

    func testParse_issuerQueryOverridesLabelPrefix() throws {
        let uri = "otpauth://totp/OldIssuer:alice?secret=JBSWY3DPEHPK3PXP&issuer=NewIssuer"

        let parsed = try OTPAuthURIParser.parse(uri)

        XCTAssertEqual(parsed.label, "alice")
        XCTAssertEqual(parsed.issuer, "NewIssuer")
    }

    func testParse_invalidBase32_throws() {
        let uri = "otpauth://totp/user?secret=JBSWY3DP9HPK3PXP"
        XCTAssertThrowsError(try OTPAuthURIParser.parse(uri)) { error in
            XCTAssertEqual(error as? OTPAuthURIParserError, .invalidBase32)
        }
    }

    func testParse_lowercaseBase32_accepted() throws {
        let uri = "otpauth://totp/user?secret=jbswy3dpehpk3pxp"

        let parsed = try OTPAuthURIParser.parse(uri)

        XCTAssertEqual(parsed.secretBase32, "JBSWY3DPEHPK3PXP")
    }

    func testParse_urlEncodedLabel_parsed() throws {
        let uri = "otpauth://totp/My%20App:alice%40example.com?secret=JBSWY3DPEHPK3PXP"

        let parsed = try OTPAuthURIParser.parse(uri)

        XCTAssertEqual(parsed.issuer, "My App")
        XCTAssertEqual(parsed.label, "alice@example.com")
    }

    func testParse_hotp_missingCounter_throws() {
        let uri = "otpauth://hotp/user?secret=JBSWY3DPEHPK3PXP"
        XCTAssertThrowsError(try OTPAuthURIParser.parse(uri)) { error in
            XCTAssertEqual(error as? OTPAuthURIParserError, .invalidCounter)
        }
    }

    func testParse_invalidPeriod_throws() {
        let uri = "otpauth://totp/user?secret=JBSWY3DPEHPK3PXP&period=0"
        XCTAssertThrowsError(try OTPAuthURIParser.parse(uri)) { error in
            XCTAssertEqual(error as? OTPAuthURIParserError, .invalidPeriod)
        }
    }

    func testParse_malformedURI_throws() {
        let uri = "otpauth://"
        XCTAssertThrowsError(try OTPAuthURIParser.parse(uri)) { error in
            XCTAssertEqual(error as? OTPAuthURIParserError, .malformedURI)
        }
    }

    func testParse_paddedBase32_acceptedAndStripped() throws {
        let uri = "otpauth://totp/user?secret=JBSWY3DPEHPK3PXP======"

        let parsed = try OTPAuthURIParser.parse(uri)

        XCTAssertEqual(parsed.secretBase32, "JBSWY3DPEHPK3PXP")
    }

    func testParse_algorithmCaseInsensitive() throws {
        let uri = "otpauth://totp/user?secret=JBSWY3DPEHPK3PXP&algorithm=sha256"

        let parsed = try OTPAuthURIParser.parse(uri)

        XCTAssertEqual(parsed.algorithm, .sha256)
    }
}
