//
//  DomainModelsTests.swift
//  KizbaTests
//
//  Minimal initialization, equality, derivation and security-shape tests
//  for the Phase 1.1 domain value types.
//

import XCTest
@testable import Kizba

final class PassEntryTests: XCTestCase {

    func testNameAndFolderForNestedPath() {
        let entry = PassEntry(path: "work/aws/root")
        XCTAssertEqual(entry.name, "root")
        XCTAssertEqual(entry.folder, "work/aws")
        XCTAssertEqual(entry.id, "work/aws/root")
    }

    func testNameAndFolderForTopLevelPath() {
        let entry = PassEntry(path: "github")
        XCTAssertEqual(entry.name, "github")
        XCTAssertEqual(entry.folder, "")
    }

    func testEquality() {
        XCTAssertEqual(PassEntry(path: "a/b"), PassEntry(path: "a/b"))
        XCTAssertNotEqual(PassEntry(path: "a/b"), PassEntry(path: "a/c"))
    }

    func testCodableRoundTrip() throws {
        let original = PassEntry(path: "work/aws/root")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PassEntry.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}

final class PassMetadataTests: XCTestCase {

    func testFirstValueRespectsOrderAndDuplicates() {
        let meta = PassMetadata(fields: [
            .init(key: "url", value: "https://a.test"),
            .init(key: "url", value: "https://b.test"),
            .init(key: "user", value: "alice"),
        ])
        XCTAssertEqual(meta.firstValue(for: "url"), "https://a.test")
        XCTAssertEqual(meta.firstValue(for: "user"), "alice")
        XCTAssertNil(meta.firstValue(for: "missing"))
    }

    func testCodableRoundTripPreservesFieldOrder() throws {
        let original = PassMetadata(
            fields: [
                .init(key: "url", value: "https://x.test:8443/path"),
                .init(key: "user", value: "alice"),
            ],
            notes: "line1\nline2"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PassMetadata.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.fields.map(\.key), ["url", "user"])
    }

    func testEmptyDefaults() {
        let meta = PassMetadata()
        XCTAssertTrue(meta.fields.isEmpty)
        XCTAssertNil(meta.notes)
    }
}

final class PassSecretSecurityTests: XCTestCase {

    func testInitAndEquality() {
        let secret = PassSecret(
            password: "hunter2",
            metadata: PassMetadata(fields: [.init(key: "user", value: "a")])
        )
        XCTAssertEqual(secret.password, "hunter2")
        XCTAssertEqual(secret.metadata.firstValue(for: "user"), "a")
        XCTAssertEqual(secret, PassSecret(
            password: "hunter2",
            metadata: PassMetadata(fields: [.init(key: "user", value: "a")])
        ))
    }

    /// `PassSecret` must not be `Codable` — confirms by checking the
    /// runtime type does not satisfy `Encodable`/`Decodable`. Compile-time
    /// enforcement via `as?` cast on metatypes.
    func testIsNotCodable() {
        XCTAssertFalse((PassSecret.self as Any) is Encodable.Type)
        XCTAssertFalse((PassSecret.self as Any) is Decodable.Type)
    }

    /// `PassSecret` must not be `CustomStringConvertible` — prevents
    /// accidental `"\(secret)"` leakage of the password.
    func testIsNotCustomStringConvertible() {
        XCTAssertFalse((PassSecret.self as Any) is CustomStringConvertible.Type)
        XCTAssertFalse((PassSecret.self as Any) is CustomDebugStringConvertible.Type)
    }
}

final class PassErrorTests: XCTestCase {

    func testEqualityAcrossCases() {
        XCTAssertEqual(PassError.binaryNotFound("pass"), .binaryNotFound("pass"))
        XCTAssertNotEqual(PassError.binaryNotFound("pass"), .binaryNotFound("gpg"))
        XCTAssertEqual(PassError.timedOut, .timedOut)
        XCTAssertEqual(PassError.cancelled, .cancelled)
        XCTAssertNotEqual(PassError.timedOut, .cancelled)
        XCTAssertEqual(
            PassError.shellFailure(exitCode: 1, stderrExcerpt: "x"),
            PassError.shellFailure(exitCode: 1, stderrExcerpt: "x")
        )
        XCTAssertNotEqual(
            PassError.shellFailure(exitCode: 1, stderrExcerpt: "x"),
            PassError.shellFailure(exitCode: 2, stderrExcerpt: "x")
        )
    }

    func testIsErrorType() {
        let err: Error = PassError.cancelled
        XCTAssertTrue(err is PassError)
    }
}
