//
//  MetadataValidatorTests.swift
//  KizbaTests
//
//  Phase D.2 — rule coverage for `MetadataValidator`.
//

import XCTest
@testable import Kizba

final class MetadataValidatorTests: XCTestCase {

    // MARK: - Helpers

    private func assertSuccess(
        _ pairs: [MetadataPair],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch MetadataValidator.validate(pairs) {
        case .success(let value):
            XCTAssertEqual(value, pairs, file: file, line: line)
        case .failure(let error):
            XCTFail("expected success, got \(error)", file: file, line: line)
        }
    }

    private func assertFailure(
        _ pairs: [MetadataPair],
        _ expected: MetadataValidator.ValidationError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch MetadataValidator.validate(pairs) {
        case .success(let value):
            XCTFail("expected \(expected), got success(\(value.count) pairs)", file: file, line: line)
        case .failure(let error):
            XCTAssertEqual(error, expected, file: file, line: line)
        }
    }

    // MARK: - Success cases

    func testEmptyListAccepted() {
        assertSuccess([])
    }

    func testSinglePairAccepted() {
        assertSuccess([MetadataPair(key: "user", value: "alice")])
    }

    func testTwoDistinctPairsAccepted() {
        assertSuccess([
            MetadataPair(key: "user", value: "alice"),
            MetadataPair(key: "url", value: "https://example.test"),
        ])
    }

    func testCaseSensitiveKeysAccepted() {
        // "Foo" and "foo" are treated as distinct keys.
        assertSuccess([
            MetadataPair(key: "Foo", value: "1"),
            MetadataPair(key: "foo", value: "2"),
        ])
    }

    func testValueWithColonAccepted() {
        // The body format permits any character in the value position
        // (everything after the first ':' on a line is the value).
        assertSuccess([MetadataPair(key: "url", value: "https://example.test:8443/path")])
    }

    func testValueWithNewlineAccepted() {
        // Notes-style values may legitimately contain newlines.
        assertSuccess([MetadataPair(key: "block", value: "line1\nline2")])
    }

    // MARK: - Failure cases

    func testEmptyKeyRejected() {
        assertFailure(
            [MetadataPair(key: "", value: "anything")],
            .emptyKey(at: 0)
        )
    }

    func testKeyWithColonRejected() {
        assertFailure(
            [MetadataPair(key: "us:er", value: "alice")],
            .keyContainsColon(at: 0)
        )
    }

    func testKeyWithNewlineRejected() {
        assertFailure(
            [MetadataPair(key: "us\ner", value: "alice")],
            .keyContainsNewline(at: 0)
        )
    }

    func testDuplicateKeyReportsBothIndices() {
        assertFailure(
            [
                MetadataPair(key: "foo", value: "1"),
                MetadataPair(key: "bar", value: "2"),
                MetadataPair(key: "foo", value: "3"),
            ],
            .duplicateKey(at: 2, conflictsWithIndexAt: 0)
        )
    }

    func testFirstViolationByIndexWins() {
        // Empty key at index 1 must be reported before the duplicate
        // at index 2 — iteration order is the only ordering rule.
        assertFailure(
            [
                MetadataPair(key: "alpha", value: "1"),
                MetadataPair(key: "", value: "2"),
                MetadataPair(key: "alpha", value: "3"),
            ],
            .emptyKey(at: 1)
        )
    }

    func testDuplicateAdjacentKeys() {
        assertFailure(
            [
                MetadataPair(key: "foo", value: "1"),
                MetadataPair(key: "foo", value: "2"),
            ],
            .duplicateKey(at: 1, conflictsWithIndexAt: 0)
        )
    }

    // MARK: - Result shape

    func testSuccessReturnsOriginalListUnchanged() {
        let pairs = [
            MetadataPair(key: "user", value: "alice"),
            MetadataPair(key: "url", value: "https://example.test"),
        ]
        let result = MetadataValidator.validate(pairs)
        if case .success(let value) = result {
            XCTAssertEqual(value, pairs)
        } else {
            XCTFail("expected success, got \(result)")
        }
    }
}
