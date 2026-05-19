//
//  CSVRowTests.swift
//  KizbaTests
//
//  RFC 4180 conformance tests for ``CSVRow``.
//

import XCTest
@testable import Kizba

final class CSVRowTests: XCTestCase {

    // MARK: - parse (single line)

    func testParse_plainFields() {
        XCTAssertEqual(CSVRow.parse("a,b,c"), ["a", "b", "c"])
    }

    func testParse_quotedFieldWithComma() {
        XCTAssertEqual(CSVRow.parse("\"a,b\",c"), ["a,b", "c"])
    }

    func testParse_quotedFieldWithEscapedQuote() {
        // `"a""b"` → `a"b`
        XCTAssertEqual(CSVRow.parse("\"a\"\"b\",c"), ["a\"b", "c"])
    }

    func testParse_emptyFields() {
        XCTAssertEqual(CSVRow.parse(",,"), ["", "", ""])
    }

    func testParse_trailingEmptyField() {
        XCTAssertEqual(CSVRow.parse("a,"), ["a", ""])
    }

    // MARK: - parseAll (full text)

    func testParseAll_simpleTwoRows() {
        let rows = CSVRow.parseAll("a,b\nc,d\n")
        XCTAssertEqual(rows, [["a", "b"], ["c", "d"]])
    }

    func testParseAll_crlfLineEndings() {
        let rows = CSVRow.parseAll("a,b\r\nc,d\r\n")
        XCTAssertEqual(rows, [["a", "b"], ["c", "d"]])
    }

    func testParseAll_multilineQuotedValue() {
        // A newline inside a quoted block stays in the field.
        let rows = CSVRow.parseAll("a,\"line1\nline2\"\nc,d")
        XCTAssertEqual(rows, [["a", "line1\nline2"], ["c", "d"]])
    }

    func testParseAll_noTrailingNewline() {
        XCTAssertEqual(CSVRow.parseAll("a,b\nc,d"), [["a", "b"], ["c", "d"]])
    }

    func testParseAll_emptyInput_returnsEmpty() {
        XCTAssertTrue(CSVRow.parseAll("").isEmpty)
    }

    func testParseAll_handlesEscapedQuoteAcrossRows() {
        let rows = CSVRow.parseAll("\"a\"\"b\",c\nd,\"e\"\"f\"")
        XCTAssertEqual(rows, [["a\"b", "c"], ["d", "e\"f"]])
    }

    // MARK: - serialize

    func testSerialize_plain() {
        XCTAssertEqual(CSVRow.serialize(["a", "b", "c"]), "a,b,c")
    }

    func testSerialize_fieldWithComma_isQuoted() {
        XCTAssertEqual(CSVRow.serialize(["a,b", "c"]), "\"a,b\",c")
    }

    func testSerialize_fieldWithQuote_isEscapedAndQuoted() {
        XCTAssertEqual(CSVRow.serialize(["a\"b", "c"]), "\"a\"\"b\",c")
    }

    func testSerialize_fieldWithNewline_isQuoted() {
        XCTAssertEqual(CSVRow.serialize(["a\nb", "c"]), "\"a\nb\",c")
    }

    // MARK: - Round trip

    func testRoundTrip_preservesAllSpecialChars() {
        let input = ["plain", "with,comma", "with\"quote", "with\nnewline", ""]
        let serialized = CSVRow.serialize(input)
        let parsed = CSVRow.parseAll(serialized + "\n")
        XCTAssertEqual(parsed.first, input)
    }
}
