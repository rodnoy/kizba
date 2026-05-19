import Foundation
import XCTest
@testable import Kizba

/// MVP9.2 — `OTPAuthURIBuilder` is the inverse of
/// `OTPAuthURIParser`. The tests pin down:
///   - Defaults (sha1/6/30) are OMITTED from the query (matches the
///     Google Authenticator KeyUriFormat convention).
///   - Non-defaults are emitted in full.
///   - HOTP always emits `counter=...` (no default).
///   - The label encodes `Issuer:Account` when both are present.
///   - `parse(build(secret)) == secret` for the parameter combinations
///     the parser supports (digits=6/8, sha1/256/512).
final class OTPAuthURIBuilderTests: XCTestCase {

    // MARK: - Defaults are omitted

    func testBuild_minimalDefaults_omitsAlgorithmDigitsPeriod() throws {
        let secret = OTPSecret(
            kind: .totp(period: 30),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 6,
            label: "alice@example.com",
            issuer: "ExampleCo"
        )

        let uri = OTPAuthURIBuilder.build(secret)
        let components = try XCTUnwrap(URLComponents(string: uri))
        let names = (components.queryItems ?? []).map(\.name)

        XCTAssertTrue(uri.hasPrefix("otpauth://totp/"))
        XCTAssertTrue(uri.contains("ExampleCo:alice@example.com"),
                      "label must encode Issuer:Account; got \(uri)")
        XCTAssertTrue(names.contains("secret"))
        XCTAssertTrue(names.contains("issuer"))
        XCTAssertFalse(names.contains("algorithm"), "sha1 is default; must be omitted")
        XCTAssertFalse(names.contains("digits"), "digits=6 is default; must be omitted")
        XCTAssertFalse(names.contains("period"), "period=30 is default; must be omitted")
    }

    func testBuild_noIssuer_noAccount_usesPlaceholderLabel() throws {
        let secret = OTPSecret(
            kind: .totp(period: 30),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 6,
            label: nil,
            issuer: nil
        )

        let uri = OTPAuthURIBuilder.build(secret)
        // Path must NOT be empty (would emit a malformed URI).
        XCTAssertTrue(uri.contains("otpauth://totp/Secret?"), "expected placeholder label; got \(uri)")
    }

    // MARK: - Non-defaults are emitted

    func testBuild_includesNonDefaultAlgorithm() throws {
        let secret = OTPSecret(
            kind: .totp(period: 30),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha256,
            digits: 6,
            label: "a",
            issuer: nil
        )
        let components = try XCTUnwrap(URLComponents(string: OTPAuthURIBuilder.build(secret)))
        let algorithm = components.queryItems?.first(where: { $0.name == "algorithm" })?.value
        XCTAssertEqual(algorithm, "SHA256")
    }

    func testBuild_includesNonDefaultDigits() throws {
        let secret = OTPSecret(
            kind: .totp(period: 30),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 8,
            label: "a",
            issuer: nil
        )
        let components = try XCTUnwrap(URLComponents(string: OTPAuthURIBuilder.build(secret)))
        let digits = components.queryItems?.first(where: { $0.name == "digits" })?.value
        XCTAssertEqual(digits, "8")
    }

    func testBuild_includesNonDefaultPeriod() throws {
        let secret = OTPSecret(
            kind: .totp(period: 60),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 6,
            label: "a",
            issuer: nil
        )
        let components = try XCTUnwrap(URLComponents(string: OTPAuthURIBuilder.build(secret)))
        let period = components.queryItems?.first(where: { $0.name == "period" })?.value
        XCTAssertEqual(period, "60")
    }

    func testBuild_hotpAlwaysEmitsCounter_evenWhenZero() throws {
        let secret = OTPSecret(
            kind: .hotp(counter: 0),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 6,
            label: "a",
            issuer: nil
        )
        let uri = OTPAuthURIBuilder.build(secret)
        XCTAssertTrue(uri.hasPrefix("otpauth://hotp/"))
        let components = try XCTUnwrap(URLComponents(string: uri))
        let counter = components.queryItems?.first(where: { $0.name == "counter" })?.value
        XCTAssertEqual(counter, "0")
    }

    func testBuild_hotpHighCounter() throws {
        let secret = OTPSecret(
            kind: .hotp(counter: 42),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 6,
            label: "a",
            issuer: nil
        )
        let components = try XCTUnwrap(URLComponents(string: OTPAuthURIBuilder.build(secret)))
        let counter = components.queryItems?.first(where: { $0.name == "counter" })?.value
        XCTAssertEqual(counter, "42")
    }

    // MARK: - Round-trip with parser

    func testRoundtrip_minimalTOTP() throws {
        let original = OTPSecret(
            kind: .totp(period: 30),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 6,
            label: "alice",
            issuer: "ExampleCo"
        )
        let parsed = try OTPAuthURIParser.parse(OTPAuthURIBuilder.build(original))
        XCTAssertEqual(parsed, original)
    }

    func testRoundtrip_nonDefaultsTOTP() throws {
        let original = OTPSecret(
            kind: .totp(period: 60),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha256,
            digits: 8,
            label: "alice",
            issuer: "ExampleCo"
        )
        let parsed = try OTPAuthURIParser.parse(OTPAuthURIBuilder.build(original))
        XCTAssertEqual(parsed, original)
    }

    func testRoundtrip_sha512() throws {
        let original = OTPSecret(
            kind: .totp(period: 30),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha512,
            digits: 8,
            label: "alice",
            issuer: "ExampleCo"
        )
        let parsed = try OTPAuthURIParser.parse(OTPAuthURIBuilder.build(original))
        XCTAssertEqual(parsed, original)
    }

    func testRoundtrip_hotp() throws {
        let original = OTPSecret(
            kind: .hotp(counter: 7),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 6,
            label: "alice",
            issuer: "ExampleCo"
        )
        let parsed = try OTPAuthURIParser.parse(OTPAuthURIBuilder.build(original))
        XCTAssertEqual(parsed, original)
    }

    func testRoundtrip_accountOnly_noIssuer() throws {
        let original = OTPSecret(
            kind: .totp(period: 30),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 6,
            label: "alice",
            issuer: nil
        )
        let parsed = try OTPAuthURIParser.parse(OTPAuthURIBuilder.build(original))
        XCTAssertEqual(parsed, original)
    }
}
