import Foundation
import XCTest
@testable import Kizba

final class Base32Tests: XCTestCase {
    func testEmpty() {
        let decoded = Base32.decode("")
        XCTAssertEqual(decoded, Data())
    }

    func testSingleByte_MY_equals() {
        let decoded = Base32.decode("MY======")
        XCTAssertEqual(decoded, Data([0x66]))
    }

    func testLowercaseAccepted() {
        let decoded = Base32.decode("mzxw6===")
        XCTAssertEqual(decoded, Data("foo".utf8))
    }

    func testWhitespaceStripped() {
        let decoded = Base32.decode("MZ XW\n6===")
        XCTAssertEqual(decoded, Data("foo".utf8))
    }

    func testInvalidChar() {
        let decoded = Base32.decode("MZ1W6===")
        XCTAssertNil(decoded)
    }

    func testNoPaddingAccepted() {
        let decoded = Base32.decode("MZXW6")
        XCTAssertEqual(decoded, Data("foo".utf8))
    }
}
