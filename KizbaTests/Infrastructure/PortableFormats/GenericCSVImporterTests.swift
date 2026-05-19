//
//  GenericCSVImporterTests.swift
//  KizbaTests
//

import XCTest
@testable import Kizba

final class GenericCSVImporterTests: XCTestCase {

    private let importer = GenericCSVImporter()

    func testParse_standardHeader() throws {
        let csv = """
        name,url,username,password,notes
        GitHub,https://github.com,ksimagin,secret,n
        """
        let preview = try importer.parse(text: csv, existingPaths: [])
        XCTAssertEqual(preview.totalCount, 1)
        let record = preview.records[0]
        XCTAssertEqual(record.path, "GitHub")
        XCTAssertEqual(record.username, "ksimagin")
        XCTAssertEqual(record.url, "https://github.com")
        XCTAssertEqual(record.notes, "n")
    }

    func testParse_titleAndWebsiteAliases() throws {
        let csv = """
        title,website,username,password
        Bank,https://bank.example,me,p
        """
        let preview = try importer.parse(text: csv, existingPaths: [])
        XCTAssertEqual(preview.records.first?.path, "Bank")
        XCTAssertEqual(preview.records.first?.url, "https://bank.example")
    }

    func testParse_caseInsensitiveHeaders() throws {
        let csv = """
        NAME,PASSWORD
        X,p
        """
        let preview = try importer.parse(text: csv, existingPaths: [])
        XCTAssertEqual(preview.records.first?.password, "p")
    }

    func testParse_missingNameColumn_throws() {
        let csv = "url,password\nhttps://x,p"
        XCTAssertThrowsError(try importer.parse(text: csv, existingPaths: [])) { error in
            XCTAssertEqual(error as? GenericCSVImporter.ImportError, .missingNameColumn)
        }
    }

    func testParse_missingPasswordColumn_throws() {
        let csv = "name,url\nX,https://x"
        XCTAssertThrowsError(try importer.parse(text: csv, existingPaths: [])) { error in
            XCTAssertEqual(error as? GenericCSVImporter.ImportError, .missingPasswordColumn)
        }
    }

    func testParse_emptyInput_throws() {
        XCTAssertThrowsError(try importer.parse(text: "", existingPaths: [])) { error in
            XCTAssertEqual(error as? GenericCSVImporter.ImportError, .emptyFile)
        }
    }

    func testParse_rowWithEmptyPassword_isWarning() throws {
        let csv = """
        name,password
        X,
        """
        let preview = try importer.parse(text: csv, existingPaths: [])
        XCTAssertTrue(preview.records.isEmpty)
        XCTAssertEqual(preview.parseWarnings.count, 1)
    }

    func testParse_conflictsDetected() throws {
        let csv = """
        name,password
        dup,p
        fresh,p
        """
        let preview = try importer.parse(text: csv, existingPaths: ["dup"])
        XCTAssertEqual(preview.totalCount, 2)
        XCTAssertEqual(preview.conflictCount, 1)
        XCTAssertEqual(preview.newCount, 1)
    }

    func testParse_totpColumn_isPassedThrough() throws {
        let csv = """
        name,password,totp
        X,p,otpauth://totp/x
        """
        let preview = try importer.parse(text: csv, existingPaths: [])
        XCTAssertEqual(preview.records.first?.totp, "otpauth://totp/x")
    }

    func testParse_otpauthAlias_recognised() throws {
        let csv = """
        name,password,otpauth
        X,p,otpauth://totp/x
        """
        let preview = try importer.parse(text: csv, existingPaths: [])
        XCTAssertEqual(preview.records.first?.totp, "otpauth://totp/x")
    }
}
