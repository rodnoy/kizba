import Foundation
import XCTest
@testable import Kizba

final class LiveOTPGeneratorTests: XCTestCase {
    private let generator = LiveOTPGenerator()

    func testHOTP_rfc4226Counters0to9() {
        let secretBase32 = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
        let expected = [
            "755224", "287082", "359152", "969429", "338314",
            "254676", "287922", "162583", "399871", "520489"
        ]

        for (counter, code) in expected.enumerated() {
            let secret = OTPSecret(
                kind: .hotp(counter: UInt64(counter)),
                secretBase32: secretBase32,
                algorithm: .sha1,
                digits: 6,
                label: nil,
                issuer: nil
            )

            XCTAssertEqual(
                generator.generate(secret, at: Date(timeIntervalSince1970: 0)),
                code,
                "counter=\(counter)"
            )
        }
    }

    func testTOTP_SHA1_rfc6238Vectors() {
        let secret = OTPSecret(
            kind: .totp(period: 30),
            secretBase32: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
            algorithm: .sha1,
            digits: 8,
            label: nil,
            issuer: nil
        )

        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 59)), "94287082")
        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 1111111109)), "07081804")
        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 1234567890)), "89005924")
        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 2000000000)), "69279037")
    }

    func testTOTP_SHA256_rfc6238Vectors() {
        let secret = OTPSecret(
            kind: .totp(period: 30),
            secretBase32: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZA====",
            algorithm: .sha256,
            digits: 8,
            label: nil,
            issuer: nil
        )

        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 59)), "46119246")
        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 1111111109)), "68084774")
        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 1234567890)), "91819424")
        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 2000000000)), "90698825")
    }

    func testTOTP_SHA512_rfc6238Vectors() {
        let secret = OTPSecret(
            kind: .totp(period: 30),
            secretBase32: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNA=",
            algorithm: .sha512,
            digits: 8,
            label: nil,
            issuer: nil
        )

        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 59)), "90693936")
        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 1111111109)), "25091201")
        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 1234567890)), "93441116")
        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 2000000000)), "38618901")
    }

    func testInvalidBase32_returnsZeros() {
        let secret = OTPSecret(
            kind: .totp(period: 30),
            secretBase32: "!!!INVALID",
            algorithm: .sha1,
            digits: 6,
            label: nil,
            issuer: nil
        )

        XCTAssertEqual(generator.generate(secret, at: Date(timeIntervalSince1970: 59)), "000000")
    }
}
