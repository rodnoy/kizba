//
//  OnePasswordCSVImporterTests.swift
//  KizbaTests
//

import XCTest
@testable import Kizba

final class OnePasswordCSVImporterTests: XCTestCase {

    private let importer = OnePasswordCSVImporter()

    func testParse_commonFieldsExport() throws {
        let csv = """
        Title,Website,Username,Password,Notes
        GitHub,https://github.com,ksimagin,secret,Test note
        """
        let preview = try importer.parse(text: csv, existingPaths: [])
        XCTAssertEqual(preview.totalCount, 1)
        let record = preview.records[0]
        XCTAssertEqual(record.path, "GitHub")
        XCTAssertEqual(record.password, "secret")
        XCTAssertEqual(record.username, "ksimagin")
        XCTAssertEqual(record.url, "https://github.com")
        XCTAssertEqual(record.notes, "Test note")
        XCTAssertNil(record.totp)
    }

    func testParse_missingTitle_throws() {
        let csv = "Website,Password\nhttps://x,p"
        XCTAssertThrowsError(try importer.parse(text: csv, existingPaths: [])) { error in
            XCTAssertEqual(error as? GenericCSVImporter.ImportError, .missingNameColumn)
        }
    }

    func testParse_emptyTitle_isWarning() throws {
        let csv = """
        Title,Password
        ,p
        """
        let preview = try importer.parse(text: csv, existingPaths: [])
        XCTAssertTrue(preview.records.isEmpty)
        XCTAssertEqual(preview.parseWarnings.count, 1)
    }

    func testParse_quotedNotesWithComma() throws {
        let csv = """
        Title,Username,Password,Notes
        X,u,p,"line1, line2"
        """
        let preview = try importer.parse(text: csv, existingPaths: [])
        XCTAssertEqual(preview.records.first?.notes, "line1, line2")
    }

    func testParse_conflictsDetected() throws {
        let csv = """
        Title,Password
        existing,p
        new,p
        """
        let preview = try importer.parse(text: csv, existingPaths: ["existing"])
        XCTAssertEqual(preview.conflictCount, 1)
        XCTAssertEqual(preview.newCount, 1)
    }
}
