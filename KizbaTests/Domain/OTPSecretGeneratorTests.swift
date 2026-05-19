import Foundation
import XCTest
@testable import Kizba

/// MVP9.2 — pins down the `OTPSecretGenerator` factory's three
/// constructors:
///   - `random(...)` produces 160-bit Base32 secrets and is
///     non-repeating across calls.
///   - `fromPassphrase(...)` is deterministic per passphrase and
///     differs across distinct passphrases.
///   - `fromBase32(...)` validates the RFC 4648 alphabet and
///     normalises case + whitespace + padding.
final class OTPSecretGeneratorTests: XCTestCase {

    // MARK: - random

    func testRandom_producesValidBase32() {
        let secret = OTPSecretGenerator.random(label: "alice", issuer: "Acme")
        XCTAssertNotNil(Base32.decode(secret.secretBase32),
                        "random() must emit valid Base32")
    }

    func testRandom_secretIs160Bits() throws {
        let secret = OTPSecretGenerator.random()
        let bytes = try XCTUnwrap(Base32.decode(secret.secretBase32))
        XCTAssertEqual(bytes.count, 20, "expected 160-bit (20-byte) secret")
    }

    func testRandom_defaultsToTOTP_sha1_6digits_30s() {
        let secret = OTPSecretGenerator.random()
        XCTAssertEqual(secret.algorithm, .sha1)
        XCTAssertEqual(secret.digits, 6)
        if case .totp(let period) = secret.kind {
            XCTAssertEqual(period, 30)
        } else {
            XCTFail("expected .totp kind")
        }
    }

    func testRandom_isDifferentEachCall() {
        // Two consecutive calls have a vanishingly small (~2^-160)
        // chance of colliding; equality here would indicate the CSPRNG
        // is not being consulted at all.
        let a = OTPSecretGenerator.random()
        let b = OTPSecretGenerator.random()
        XCTAssertNotEqual(a.secretBase32, b.secretBase32)
    }

    func testRandom_propagatesLabelAndIssuer() {
        let secret = OTPSecretGenerator.random(label: "alice", issuer: "Acme")
        XCTAssertEqual(secret.label, "alice")
        XCTAssertEqual(secret.issuer, "Acme")
    }

    // MARK: - fromPassphrase

    func testFromPassphrase_isDeterministic() {
        let first = OTPSecretGenerator.fromPassphrase("correct horse battery staple")
        let second = OTPSecretGenerator.fromPassphrase("correct horse battery staple")
        XCTAssertEqual(first.secretBase32, second.secretBase32)
    }

    func testFromPassphrase_differentInputs_differentSecrets() {
        let a = OTPSecretGenerator.fromPassphrase("alpha")
        let b = OTPSecretGenerator.fromPassphrase("beta")
        XCTAssertNotEqual(a.secretBase32, b.secretBase32)
    }

    func testFromPassphrase_isAlso160Bits() throws {
        let secret = OTPSecretGenerator.fromPassphrase("anything")
        let bytes = try XCTUnwrap(Base32.decode(secret.secretBase32))
        XCTAssertEqual(bytes.count, 20)
    }

    func testFromPassphrase_emptyPassphrase_stillProducesSecret() {
        // The generator does not reject empty input — the UI layer is
        // responsible for guarding against it. SHA-256 of "" is a
        // well-defined hash, and we want this constructor to remain
        // total so callers can safely route arbitrary user input.
        let secret = OTPSecretGenerator.fromPassphrase("")
        XCTAssertFalse(secret.secretBase32.isEmpty)
    }

    // MARK: - fromBase32

    func testFromBase32_acceptsValidUppercase() {
        let secret = OTPSecretGenerator.fromBase32("JBSWY3DPEHPK3PXP")
        XCTAssertNotNil(secret)
        XCTAssertEqual(secret?.secretBase32, "JBSWY3DPEHPK3PXP")
    }

    func testFromBase32_normalisesLowercaseToUppercase() {
        let secret = OTPSecretGenerator.fromBase32("jbswy3dpehpk3pxp")
        XCTAssertEqual(secret?.secretBase32, "JBSWY3DPEHPK3PXP")
    }

    func testFromBase32_stripsInternalWhitespace() {
        let secret = OTPSecretGenerator.fromBase32("JBSW Y3DP EHPK 3PXP")
        XCTAssertEqual(secret?.secretBase32, "JBSWY3DPEHPK3PXP")
    }

    func testFromBase32_stripsPadding() {
        let secret = OTPSecretGenerator.fromBase32("JBSWY3DPEHPK3PXP====")
        XCTAssertEqual(secret?.secretBase32, "JBSWY3DPEHPK3PXP")
    }

    func testFromBase32_rejectsInvalidCharacters() {
        XCTAssertNil(OTPSecretGenerator.fromBase32("JBSW!Y3DP"),
                     "must reject non-RFC-4648 characters")
        XCTAssertNil(OTPSecretGenerator.fromBase32("JBSW1Y3DP"),
                     "must reject digits outside 2-7")
    }

    func testFromBase32_rejectsEmpty() {
        XCTAssertNil(OTPSecretGenerator.fromBase32(""))
        XCTAssertNil(OTPSecretGenerator.fromBase32("   "))
    }
}
