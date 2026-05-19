//
//  GenericCSVExporterTests.swift
//  KizbaTests
//

import XCTest
@testable import Kizba

final class GenericCSVExporterTests: XCTestCase {

    private let exporter = GenericCSVExporter()

    func testExport_headerRowFirst() {
        let csv = exporter.export(records: [])
        XCTAssertTrue(csv.hasPrefix("name,url,username,password,notes,totp"))
    }

    func testExport_singleRecord() {
        let records = [
            ExportRecord(
                path: "GitHub",
                password: "p",
                username: "u",
                url: "https://github.com",
                notes: "n",
                totp: "otpauth://totp/x"
            )
        ]
        let csv = exporter.export(records: records)
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: true)
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(String(lines[1]), "GitHub,https://github.com,u,p,n,otpauth://totp/x")
    }

    func testExport_fieldWithComma_isQuoted() {
        let records = [
            ExportRecord(path: "X", password: "p", notes: "line1, line2")
        ]
        let csv = exporter.export(records: records)
        XCTAssertTrue(csv.contains("\"line1, line2\""))
    }

    func testExport_fieldWithQuote_isEscaped() {
        let records = [
            ExportRecord(path: "X", password: "with\"quote")
        ]
        let csv = exporter.export(records: records)
        XCTAssertTrue(csv.contains("\"with\"\"quote\""))
    }

    func testExport_nilFields_areEmpty() {
        let records = [
            ExportRecord(path: "X", password: "p")
        ]
        let csv = exporter.export(records: records)
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: true)
        XCTAssertEqual(String(lines[1]), "X,,,p,,")
    }

    func testExport_endsWithTrailingNewline() {
        let csv = exporter.export(records: [])
        XCTAssertTrue(csv.hasSuffix("\n"))
    }
}
