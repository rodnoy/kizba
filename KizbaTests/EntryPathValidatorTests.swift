//
//  EntryPathValidatorTests.swift
//  KizbaTests
//
//  Phase D.2 — exhaustive rule coverage for `EntryPathValidator`.
//

import XCTest
@testable import Kizba

final class EntryPathValidatorTests: XCTestCase {

    // MARK: - Helpers

    private func assertSuccess(_ path: String, file: StaticString = #filePath, line: UInt = #line) {
        switch EntryPathValidator.validate(path) {
        case .success(let value):
            XCTAssertEqual(value, path, file: file, line: line)
        case .failure(let error):
            XCTFail("expected success for \(path), got \(error)", file: file, line: line)
        }
    }

    private func assertFailure(
        _ path: String,
        _ expected: EntryPathValidator.ValidationError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch EntryPathValidator.validate(path) {
        case .success(let value):
            XCTFail("expected \(expected) for \(path), got success(\(value))", file: file, line: line)
        case .failure(let error):
            XCTAssertEqual(error, expected, file: file, line: line)
        }
    }

    // MARK: - Failure cases

    func testEmptyStringRejected() {
        assertFailure("", .empty)
    }

    func testWhitespaceOnlyRejected() {
        assertFailure("  ", .whitespaceComponent)
    }

    func testLeadingSlashRejected() {
        assertFailure("/personal/github", .leadingSlash)
    }

    func testSingleSlashRejected() {
        assertFailure("/", .leadingSlash)
    }

    func testTrailingSlashRejected() {
        assertFailure("personal/", .trailingSlash)
    }

    func testGpgSuffixRejected() {
        assertFailure("personal/github.gpg", .gpgSuffix)
    }

    func testDotComponentRejected() {
        assertFailure("personal/.", .dotComponent)
    }

    func testDotDotComponentRejected() {
        assertFailure("personal/..", .dotDotComponent)
    }

    func testEmptyMiddleComponentRejected() {
        assertFailure("personal//github", .whitespaceComponent)
    }

    func testWhitespaceOnlyMiddleComponentRejected() {
        assertFailure("personal/  /github", .whitespaceComponent)
    }

    func testLeadingWhitespaceRejected() {
        assertFailure(" personal", .whitespaceComponent)
    }

    func testTrailingWhitespaceRejected() {
        assertFailure("personal ", .whitespaceComponent)
    }

    // MARK: - Success cases

    func testSimpleNestedPathAccepted() {
        assertSuccess("personal/github")
    }

    func testTopLevelEntryAccepted() {
        assertSuccess("github")
    }

    func testDeeplyNestedPathAccepted() {
        assertSuccess("deep/nested/folder/entry")
    }

    func testUnicodePathAccepted() {
        assertSuccess("café/naïve")
    }

    /// `pass` accepts entry names with internal whitespace
    /// (e.g. `Personal/My Bank`); we follow suit.
    func testInternalWhitespaceInComponentAccepted() {
        assertSuccess("perso nal")
    }

    func testInternalWhitespaceInNestedComponentAccepted() {
        assertSuccess("Personal/My Bank")
    }

    // MARK: - Result shape

    func testSuccessReturnsOriginalPathUnchanged() {
        let original = "personal/github"
        let result = EntryPathValidator.validate(original)
        if case .success(let value) = result {
            XCTAssertEqual(value, original)
        } else {
            XCTFail("expected success, got \(result)")
        }
    }
}
