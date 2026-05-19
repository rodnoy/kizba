//
//  BitwardenJSONImporterTests.swift
//  KizbaTests
//

import XCTest
@testable import Kizba

final class BitwardenJSONImporterTests: XCTestCase {

    private let importer = BitwardenJSONImporter()

    private func parse(_ json: String, existing: Set<String> = []) throws -> ImportPreview {
        let data = Data(json.utf8)
        return try importer.parse(data: data, existingPaths: existing)
    }

    func testParse_minimalLoginItem() throws {
        let json = """
        {
          "encrypted": false,
          "items": [
            {
              "name": "GitHub",
              "folderId": null,
              "type": 1,
              "login": {
                "username": "ksimagin",
                "password": "secret",
                "uris": [{"uri": "https://github.com"}]
              },
              "notes": null
            }
          ],
          "folders": []
        }
        """
        let preview = try parse(json)
        XCTAssertEqual(preview.totalCount, 1)
        let record = preview.records[0]
        XCTAssertEqual(record.path, "GitHub")
        XCTAssertEqual(record.password, "secret")
        XCTAssertEqual(record.username, "ksimagin")
        XCTAssertEqual(record.url, "https://github.com")
        XCTAssertNil(record.totp)
    }

    func testParse_itemWithFolder_buildsPath() throws {
        let json = """
        {
          "items": [
            {
              "name": "AWS",
              "folderId": "f1",
              "type": 1,
              "login": {"password": "p"}
            }
          ],
          "folders": [{"id": "f1", "name": "Work"}]
        }
        """
        let preview = try parse(json)
        XCTAssertEqual(preview.records.first?.path, "Work/AWS")
    }

    func testParse_itemWithTOTP_passesThrough() throws {
        let json = """
        {
          "items": [
            {
              "name": "Gmail",
              "folderId": null,
              "type": 1,
              "login": {
                "password": "p",
                "totp": "otpauth://totp/x?secret=ABC"
              }
            }
          ],
          "folders": []
        }
        """
        let preview = try parse(json)
        XCTAssertEqual(preview.records.first?.totp, "otpauth://totp/x?secret=ABC")
    }

    func testParse_itemWithoutPassword_isSkippedAsWarning() throws {
        let json = """
        {
          "items": [
            {"name": "Empty", "folderId": null, "type": 1, "login": {"username": "u"}}
          ],
          "folders": []
        }
        """
        let preview = try parse(json)
        XCTAssertEqual(preview.records.count, 0)
        XCTAssertEqual(preview.parseWarnings.count, 1)
        XCTAssertTrue(preview.parseWarnings[0].contains("Empty"))
    }

    func testParse_nonLoginItems_areIgnored() throws {
        // type=2 is secure note, type=3 is card, type=4 is identity.
        let json = """
        {
          "items": [
            {"name": "Note", "folderId": null, "type": 2},
            {"name": "Card", "folderId": null, "type": 3},
            {"name": "Login", "folderId": null, "type": 1, "login": {"password": "p"}}
          ],
          "folders": []
        }
        """
        let preview = try parse(json)
        XCTAssertEqual(preview.totalCount, 1)
        XCTAssertEqual(preview.records[0].path, "Login")
    }

    func testParse_conflictsDetected() throws {
        let json = """
        {
          "items": [
            {"name": "GitHub", "folderId": null, "type": 1, "login": {"password": "p"}}
          ],
          "folders": []
        }
        """
        let preview = try parse(json, existing: ["GitHub"])
        XCTAssertEqual(preview.conflictCount, 1)
        XCTAssertEqual(preview.newCount, 0)
    }

    func testParse_missingFoldersArray_doesNotThrow() throws {
        // Older Bitwarden exports omit the `folders` array entirely.
        let json = """
        {
          "items": [
            {"name": "X", "folderId": null, "type": 1, "login": {"password": "p"}}
          ]
        }
        """
        let preview = try parse(json)
        XCTAssertEqual(preview.totalCount, 1)
    }

    func testParse_sanitisesColonAndBackslashInName() throws {
        let json = """
        {
          "items": [
            {"name": "a:b\\\\c", "folderId": null, "type": 1, "login": {"password": "p"}}
          ],
          "folders": []
        }
        """
        let preview = try parse(json)
        XCTAssertEqual(preview.records.first?.path, "a-b-c")
    }
}
