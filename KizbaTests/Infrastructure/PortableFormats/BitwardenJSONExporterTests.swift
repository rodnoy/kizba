//
//  BitwardenJSONExporterTests.swift
//  KizbaTests
//

import XCTest
@testable import Kizba

final class BitwardenJSONExporterTests: XCTestCase {

    private let exporter = BitwardenJSONExporter()

    private func decode(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testExport_singleTopLevelRecord() throws {
        let records = [
            ExportRecord(path: "GitHub", password: "p", username: "u", url: "https://x")
        ]
        let json = try decode(exporter.export(records: records))
        XCTAssertEqual(json["encrypted"] as? Bool, false)
        let items = try XCTUnwrap(json["items"] as? [[String: Any]])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0]["name"] as? String, "GitHub")
        XCTAssertEqual(items[0]["type"] as? Int, 1)
        XCTAssertNil(items[0]["folderId"] as? String)

        let login = try XCTUnwrap(items[0]["login"] as? [String: Any])
        XCTAssertEqual(login["password"] as? String, "p")
        XCTAssertEqual(login["username"] as? String, "u")

        let folders = try XCTUnwrap(json["folders"] as? [[String: Any]])
        XCTAssertEqual(folders.count, 0)
    }

    func testExport_recordWithFolder_extractsFolderName() throws {
        let records = [
            ExportRecord(path: "Work/AWS", password: "p")
        ]
        let json = try decode(exporter.export(records: records))
        let folders = try XCTUnwrap(json["folders"] as? [[String: Any]])
        XCTAssertEqual(folders.count, 1)
        XCTAssertEqual(folders[0]["name"] as? String, "Work")

        let items = try XCTUnwrap(json["items"] as? [[String: Any]])
        XCTAssertEqual(items[0]["name"] as? String, "AWS")
        XCTAssertEqual(items[0]["folderId"] as? String, folders[0]["id"] as? String)
    }

    func testExport_multipleItemsInSameFolder_deduplicateFolder() throws {
        let records = [
            ExportRecord(path: "Work/AWS", password: "p"),
            ExportRecord(path: "Work/GCP", password: "p"),
        ]
        let json = try decode(exporter.export(records: records))
        let folders = try XCTUnwrap(json["folders"] as? [[String: Any]])
        XCTAssertEqual(folders.count, 1)
    }

    func testExport_recordWithTOTP_passesThrough() throws {
        let records = [
            ExportRecord(path: "X", password: "p", totp: "otpauth://totp/x?secret=ABC")
        ]
        let json = try decode(exporter.export(records: records))
        let items = try XCTUnwrap(json["items"] as? [[String: Any]])
        let login = try XCTUnwrap(items[0]["login"] as? [String: Any])
        XCTAssertEqual(login["totp"] as? String, "otpauth://totp/x?secret=ABC")
    }

    func testExport_recordWithURL_isWrappedInURIsArray() throws {
        let records = [
            ExportRecord(path: "X", password: "p", url: "https://example.com")
        ]
        let json = try decode(exporter.export(records: records))
        let items = try XCTUnwrap(json["items"] as? [[String: Any]])
        let login = try XCTUnwrap(items[0]["login"] as? [String: Any])
        let uris = try XCTUnwrap(login["uris"] as? [[String: Any]])
        XCTAssertEqual(uris.count, 1)
        XCTAssertEqual(uris[0]["uri"] as? String, "https://example.com")
    }
}
