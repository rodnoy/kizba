import Foundation
import XCTest
@testable import Kizba

/// MVP9.2 — encoder coverage. The decoder is exercised by
/// `Base32Tests`; this file pins down the encoder vectors and the
/// round-trip with the decoder for arbitrary binary input.
final class Base32EncoderTests: XCTestCase {

    func testEncode_empty_returnsEmptyString() {
        XCTAssertEqual(Base32.encode(Data()), "")
    }

    /// "f" → "MY" (RFC 4648 §10 test vector, padding stripped).
    func testEncode_singleByteFoo_f() {
        XCTAssertEqual(Base32.encode(Data("f".utf8)), "MY")
    }

    /// "fo" → "MZXQ" (RFC 4648 §10 test vector, padding stripped).
    func testEncode_twoBytes_fo() {
        XCTAssertEqual(Base32.encode(Data("fo".utf8)), "MZXQ")
    }

    /// "foo" → "MZXW6" (RFC 4648 §10 test vector, padding stripped).
    func testEncode_threeBytes_foo() {
        XCTAssertEqual(Base32.encode(Data("foo".utf8)), "MZXW6")
    }

    /// "foob" → "MZXW6YQ" (RFC 4648 §10 test vector, padding stripped).
    func testEncode_fourBytes_foob() {
        XCTAssertEqual(Base32.encode(Data("foob".utf8)), "MZXW6YQ")
    }

    /// "fooba" → "MZXW6YTB" (RFC 4648 §10 test vector, padding stripped).
    func testEncode_fiveBytes_fooba() {
        XCTAssertEqual(Base32.encode(Data("fooba".utf8)), "MZXW6YTB")
    }

    /// "foobar" → "MZXW6YTBOI" (RFC 4648 §10 test vector, padding stripped).
    func testEncode_sixBytes_foobar() {
        XCTAssertEqual(Base32.encode(Data("foobar".utf8)), "MZXW6YTBOI")
    }

    func testEncode_emitsNoPadding() {
        // 1 byte → 2 base32 chars (no `=`); 2 → 4; 3 → 5; 4 → 7; 5 → 8.
        XCTAssertEqual(Base32.encode(Data([0x00])).count, 2)
        XCTAssertEqual(Base32.encode(Data([0x00, 0x00])).count, 4)
        XCTAssertEqual(Base32.encode(Data([0x00, 0x00, 0x00])).count, 5)
        XCTAssertEqual(Base32.encode(Data([0x00, 0x00, 0x00, 0x00])).count, 7)
        XCTAssertEqual(Base32.encode(Data([0x00, 0x00, 0x00, 0x00, 0x00])).count, 8)

        for byte in 0..<8 {
            let encoded = Base32.encode(Data((0..<byte).map { _ in UInt8(0xFF) }))
            XCTAssertFalse(encoded.contains("="), "encode must never emit padding (input length \(byte))")
        }
    }

    func testRoundtrip_zeroToOneFiftyByteInputs() {
        // Walk a few lengths so we exercise every (bits mod 5) tail
        // case in the encoder. The result must round-trip through the
        // decoder bit-for-bit.
        var generator = SystemRandomNumberGenerator()
        for length in 0...50 {
            var bytes = Data(count: length)
            for index in 0..<length {
                bytes[index] = UInt8.random(in: 0...255, using: &generator)
            }
            let encoded = Base32.encode(bytes)
            let decoded = Base32.decode(encoded)
            XCTAssertEqual(decoded, bytes, "round-trip failed at length \(length)")
        }
    }

    func testRoundtrip_fixedAllOnes_thirtyBytes() {
        // Deterministic boundary case: 30 bytes of 0xFF (multiple of
        // 5, no tail), should encode/decode losslessly.
        let bytes = Data(repeating: 0xFF, count: 30)
        let encoded = Base32.encode(bytes)
        XCTAssertEqual(encoded.count, 48)
        XCTAssertEqual(Base32.decode(encoded), bytes)
    }
}
