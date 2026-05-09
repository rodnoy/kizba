//
//  MetadataPairTests.swift
//  KizbaTests
//
//  Phase D.1 — initialization, equality, value-semantics and
//  security non-conformance tests for `MetadataPair`.
//

import XCTest
@testable import Kizba

final class MetadataPairTests: XCTestCase {

    func testInitWithAutoIDProducesUniqueIdentifiers() {
        let a = MetadataPair(key: "user", value: "alice")
        let b = MetadataPair(key: "user", value: "alice")
        XCTAssertNotEqual(a.id, b.id)
        // Same fields, different ids — equality must reflect the id too.
        XCTAssertNotEqual(a, b)
    }

    func testInitWithExplicitID() {
        let id = UUID()
        let pair = MetadataPair(id: id, key: "user", value: "alice")
        XCTAssertEqual(pair.id, id)
        XCTAssertEqual(pair.key, "user")
        XCTAssertEqual(pair.value, "alice")
    }

    func testEqualityRequiresAllThreeFields() {
        let id = UUID()
        let base = MetadataPair(id: id, key: "user", value: "alice")
        XCTAssertEqual(base, MetadataPair(id: id, key: "user", value: "alice"))
        XCTAssertNotEqual(base, MetadataPair(id: id, key: "user", value: "bob"))
        XCTAssertNotEqual(base, MetadataPair(id: id, key: "url", value: "alice"))
        XCTAssertNotEqual(base, MetadataPair(id: UUID(), key: "user", value: "alice"))
    }

    func testValueSemanticsForKeyMutation() {
        var pair = MetadataPair(key: "user", value: "alice")
        let copy = pair
        pair.key = "username"
        XCTAssertEqual(pair.key, "username")
        XCTAssertEqual(copy.key, "user")
    }

    func testValueSemanticsForValueMutation() {
        var pair = MetadataPair(key: "user", value: "alice")
        let copy = pair
        pair.value = "bob"
        XCTAssertEqual(pair.value, "bob")
        XCTAssertEqual(copy.value, "alice")
    }

    func testHashableUsableInSet() {
        let id = UUID()
        let a = MetadataPair(id: id, key: "user", value: "alice")
        let b = MetadataPair(id: id, key: "user", value: "alice")
        let c = MetadataPair(key: "user", value: "alice")
        let set: Set<MetadataPair> = [a, b, c]
        // a == b → only two distinct entries.
        XCTAssertEqual(set.count, 2)
    }

    /// `MetadataPair` must not be `Codable` — its `value` may carry
    /// secret material.
    func testIsNotCodable() {
        XCTAssertFalse((MetadataPair.self as Any) is Encodable.Type)
        XCTAssertFalse((MetadataPair.self as Any) is Decodable.Type)
    }

    /// `MetadataPair` must not be string-convertible — prevents
    /// accidental `"\(pair)"` leakage of the value.
    func testIsNotCustomStringConvertible() {
        XCTAssertFalse((MetadataPair.self as Any) is CustomStringConvertible.Type)
        XCTAssertFalse((MetadataPair.self as Any) is CustomDebugStringConvertible.Type)
    }

    /// Runtime cast confirms no `Encodable` conformance has been
    /// added via an extension elsewhere in the module.
    func testRuntimeIsNotEncodable() {
        let pair: Any = MetadataPair(key: "user", value: "topsecret")
        XCTAssertNil(pair as? Encodable)
    }
}
