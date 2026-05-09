//
//  SecretDraftTests.swift
//  KizbaTests
//
//  Phase D.1 — `SecretDraft` defaults, `from:` round-trip,
//  snapshot value-copy semantics, reference semantics, and security
//  non-conformance assertions.
//

import XCTest
@testable import Kizba

final class SecretDraftTests: XCTestCase {

    func testEmptyInitDefaults() {
        let draft = SecretDraft()
        XCTAssertEqual(draft.password, "")
        XCTAssertTrue(draft.metadata.isEmpty)
        XCTAssertEqual(draft.notes, "")
    }

    func testInitFromSecretCopiesAllFields() {
        let secret = PassSecret(
            password: "hunter2",
            metadata: PassMetadata(
                fields: [
                    .init(key: "user", value: "alice"),
                    .init(key: "url", value: "https://example.test"),
                ],
                notes: "first line\nsecond line"
            )
        )
        let draft = SecretDraft(from: secret)
        XCTAssertEqual(draft.password, "hunter2")
        XCTAssertEqual(draft.metadata.count, 2)
        XCTAssertEqual(draft.metadata.map(\.key), ["user", "url"])
        XCTAssertEqual(draft.metadata.map(\.value), ["alice", "https://example.test"])
        XCTAssertEqual(draft.notes, "first line\nsecond line")
    }

    func testInitFromSecretMapsNilNotesToEmptyString() {
        let secret = PassSecret(
            password: "p",
            metadata: PassMetadata(fields: [], notes: nil)
        )
        let draft = SecretDraft(from: secret)
        XCTAssertEqual(draft.notes, "")
    }

    func testSnapshotRoundTripPreservesFields() {
        let secret = PassSecret(
            password: "hunter2",
            metadata: PassMetadata(
                fields: [
                    .init(key: "user", value: "alice"),
                    .init(key: "url", value: "https://example.test"),
                ],
                notes: "n"
            )
        )
        let draft = SecretDraft(from: secret)
        let snap = draft.snapshot()
        XCTAssertEqual(snap.password, secret.password)
        XCTAssertEqual(snap.metadata.fields, secret.metadata.fields)
        XCTAssertEqual(snap.metadata.notes, secret.metadata.notes)
        XCTAssertEqual(snap, secret)
    }

    func testSnapshotEmptyNotesBecomesNil() {
        let draft = SecretDraft(password: "p", metadata: [], notes: "")
        let snap = draft.snapshot()
        XCTAssertNil(snap.metadata.notes)
    }

    func testSnapshotNonEmptyNotesPreserved() {
        let draft = SecretDraft(password: "p", metadata: [], notes: "hello")
        let snap = draft.snapshot()
        XCTAssertEqual(snap.metadata.notes, "hello")
    }

    func testSnapshotPreservesMetadataOrder() {
        let draft = SecretDraft(
            password: "p",
            metadata: [
                MetadataPair(key: "z", value: "1"),
                MetadataPair(key: "a", value: "2"),
                MetadataPair(key: "m", value: "3"),
            ]
        )
        let snap = draft.snapshot()
        XCTAssertEqual(snap.metadata.fields.map(\.key), ["z", "a", "m"])
        XCTAssertEqual(snap.metadata.fields.map(\.value), ["1", "2", "3"])
    }

    func testMutatingPasswordAfterSnapshotDoesNotAffectSnapshot() {
        let draft = SecretDraft(password: "before")
        let snap = draft.snapshot()
        draft.password = "after"
        XCTAssertEqual(snap.password, "before")
        XCTAssertEqual(draft.password, "after")
    }

    func testMutatingMetadataAfterSnapshotDoesNotAffectSnapshot() {
        let draft = SecretDraft(
            password: "p",
            metadata: [MetadataPair(key: "user", value: "alice")]
        )
        let snap = draft.snapshot()
        draft.metadata.append(MetadataPair(key: "url", value: "x"))
        draft.metadata[0].value = "bob"
        XCTAssertEqual(snap.metadata.fields.count, 1)
        XCTAssertEqual(snap.metadata.fields[0].key, "user")
        XCTAssertEqual(snap.metadata.fields[0].value, "alice")
    }

    func testMutatingNotesAfterSnapshotDoesNotAffectSnapshot() {
        let draft = SecretDraft(password: "p", notes: "original")
        let snap = draft.snapshot()
        draft.notes = "changed"
        XCTAssertEqual(snap.metadata.notes, "original")
    }

    func testReferenceSemanticsMutationsAreShared() {
        let draftA = SecretDraft(password: "p")
        let draftB = draftA
        draftA.password = "changed"
        XCTAssertEqual(draftB.password, "changed")
        XCTAssertTrue(draftA === draftB)
    }

    /// `SecretDraft` must not be `Codable` — its fields hold cleartext
    /// secret material.
    func testIsNotCodable() {
        XCTAssertFalse((SecretDraft.self as Any) is Encodable.Type)
        XCTAssertFalse((SecretDraft.self as Any) is Decodable.Type)
        let draft: Any = SecretDraft(password: "topsecret")
        XCTAssertNil(draft as? Encodable)
    }

    /// `SecretDraft` must not be string-convertible — prevents
    /// accidental `"\(draft)"` leakage of the password.
    func testIsNotCustomStringConvertible() {
        XCTAssertFalse((SecretDraft.self as Any) is CustomStringConvertible.Type)
        XCTAssertFalse((SecretDraft.self as Any) is CustomDebugStringConvertible.Type)
    }

    /// Default `String(describing:)` for a final class without
    /// `CustomStringConvertible` returns only the type name +
    /// address, never the stored property values.
    func testDefaultStringDescriptionDoesNotLeakPassword() {
        let draft = SecretDraft(password: "topsecret-do-not-leak")
        let described = String(describing: draft)
        XCTAssertFalse(described.contains("topsecret-do-not-leak"))
    }
}
