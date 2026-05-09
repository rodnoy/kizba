//
//  StoreChangeTests.swift
//  KizbaTests
//
//  Phase D.6 — unit tests for the `StoreChange` event type. Pure value
//  semantics; no infrastructure / UI involvement.
//

import XCTest
@testable import Kizba

final class StoreChangeTests: XCTestCase {

    func testAllCasesConstruct() {
        // Smoke construction — also documents the shape of each case.
        let cases: [StoreChange] = [
            .inserted(path: "a/b"),
            .updated(path: "a/b"),
            .removed(path: "a/b"),
            .moved(from: "a/b", to: "c/d"),
            .bulk,
        ]
        XCTAssertEqual(cases.count, 5)
    }

    func testInsertedEqualityRespectsPath() {
        XCTAssertEqual(StoreChange.inserted(path: "foo"), .inserted(path: "foo"))
        XCTAssertNotEqual(StoreChange.inserted(path: "foo"), .inserted(path: "bar"))
    }

    func testDifferentCasesWithSamePathAreNotEqual() {
        XCTAssertNotEqual(StoreChange.inserted(path: "foo"), .updated(path: "foo"))
        XCTAssertNotEqual(StoreChange.updated(path: "foo"), .removed(path: "foo"))
        XCTAssertNotEqual(StoreChange.inserted(path: "foo"), .removed(path: "foo"))
    }

    func testMovedEqualityIsDirectional() {
        XCTAssertEqual(
            StoreChange.moved(from: "a", to: "b"),
            StoreChange.moved(from: "a", to: "b")
        )
        XCTAssertNotEqual(
            StoreChange.moved(from: "a", to: "b"),
            StoreChange.moved(from: "b", to: "a")
        )
    }

    func testBulkSelfEquality() {
        XCTAssertEqual(StoreChange.bulk, .bulk)
        XCTAssertNotEqual(StoreChange.bulk, .inserted(path: ""))
    }

    func testHashableInSetDeduplicates() {
        let set: Set<StoreChange> = [
            .inserted(path: "a"),
            .inserted(path: "a"),
            .inserted(path: "b"),
            .updated(path: "a"),
            .moved(from: "x", to: "y"),
            .moved(from: "x", to: "y"),
            .moved(from: "y", to: "x"),
            .removed(path: "a"),
            .bulk,
            .bulk,
        ]
        XCTAssertEqual(set.count, 7)
    }

    func testIsSendable() {
        // Compile-time check that `Sendable` conformance is wired in.
        XCTAssertTrue((StoreChange.self as Any) is any Sendable.Type)
    }
}
