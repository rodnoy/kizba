//
//  RoundTripTests.swift
//  KizbaTests
//
//  End-to-end round-trip checks: export records → bytes → import →
//  records compare equal. Catches format drift between matched
//  importer/exporter pairs (Bitwarden JSON, Generic CSV).
//

import XCTest
@testable import Kizba

final class RoundTripTests: XCTestCase {

    private let sample: [ExportRecord] = [
        ExportRecord(
            path: "GitHub",
            password: "secret-1",
            username: "alice",
            url: "https://github.com",
            notes: "Personal",
            totp: "otpauth://totp/x?secret=ABC"
        ),
        ExportRecord(
            path: "Work/AWS",
            password: "secret-2",
            username: "alice@corp",
            url: "https://console.aws.amazon.com",
            notes: nil,
            totp: nil
        ),
        ExportRecord(
            path: "Work/GCP",
            password: "secret-3",
            username: nil,
            url: nil,
            notes: "Multi-line\nnote with comma, here",
            totp: nil
        ),
    ]

    func testBitwardenJSON_roundTrip_preservesAllRecords() throws {
        let exported = try BitwardenJSONExporter().export(records: sample)
        let reimported = try BitwardenJSONImporter().parse(data: exported, existingPaths: [])

        XCTAssertEqual(reimported.totalCount, sample.count)
        for original in sample {
            guard let match = reimported.records.first(where: { $0.path == original.path }) else {
                return XCTFail("Path \(original.path) missing in re-imported records")
            }
            XCTAssertEqual(match.password, original.password, "password for \(original.path)")
            XCTAssertEqual(match.username, original.username, "username for \(original.path)")
            XCTAssertEqual(match.url, original.url, "url for \(original.path)")
            XCTAssertEqual(match.notes, original.notes, "notes for \(original.path)")
            XCTAssertEqual(match.totp, original.totp, "totp for \(original.path)")
        }
    }

    func testGenericCSV_roundTrip_preservesAllRecords() throws {
        let exported = GenericCSVExporter().export(records: sample)
        let reimported = try GenericCSVImporter().parse(text: exported, existingPaths: [])

        XCTAssertEqual(reimported.totalCount, sample.count)
        for original in sample {
            guard let match = reimported.records.first(where: { $0.path == original.path }) else {
                return XCTFail("Path \(original.path) missing in re-imported records")
            }
            XCTAssertEqual(match.password, original.password, "password for \(original.path)")
            XCTAssertEqual(match.username, original.username, "username for \(original.path)")
            XCTAssertEqual(match.url, original.url, "url for \(original.path)")
            XCTAssertEqual(match.notes, original.notes, "notes for \(original.path)")
            XCTAssertEqual(match.totp, original.totp, "totp for \(original.path)")
        }
    }

    // MARK: - PassSecretExporter bridge

    func testPassSecretExporter_mapsStandardMetadata() {
        let metadata = PassMetadata(fields: [
            .init(key: "user", value: "alice"),
            .init(key: "url", value: "https://x"),
            .init(key: "otpauth", value: "otpauth://totp/x"),
            .init(key: "comment", value: "extra-1"),
        ], notes: "free-form notes")
        let secret = PassSecret(password: "p", metadata: metadata)
        let entry = PassEntry(path: "work/x")

        let record = PassSecretExporter.toExportRecord(entry: entry, secret: secret)
        XCTAssertEqual(record.path, "work/x")
        XCTAssertEqual(record.password, "p")
        XCTAssertEqual(record.username, "alice")
        XCTAssertEqual(record.url, "https://x")
        XCTAssertEqual(record.totp, "otpauth://totp/x")
        XCTAssertEqual(record.notes, "free-form notes")
        XCTAssertEqual(record.extraFields["comment"], "extra-1")
    }

    func testPassSecretExporter_username_aliasFallback() {
        let metadata = PassMetadata(fields: [
            .init(key: "username", value: "from-username"),
        ])
        let secret = PassSecret(password: "p", metadata: metadata)
        let record = PassSecretExporter.toExportRecord(entry: PassEntry(path: "x"), secret: secret)
        XCTAssertEqual(record.username, "from-username")
    }

    func testPassSecretExporter_caseInsensitiveAliasResolution() {
        let metadata = PassMetadata(fields: [
            .init(key: "USER", value: "loud"),
            .init(key: "Website", value: "https://x"),
        ])
        let secret = PassSecret(password: "p", metadata: metadata)
        let record = PassSecretExporter.toExportRecord(entry: PassEntry(path: "x"), secret: secret)
        XCTAssertEqual(record.username, "loud")
        XCTAssertEqual(record.url, "https://x")
    }
}
