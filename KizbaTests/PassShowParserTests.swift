//
//  PassShowParserTests.swift
//  KizbaTests
//
//  Unit tests for `PassShowParser` (Phase 4.1). These tests are pure
//  string-level checks; no fixtures from disk, no shell, no IO.
//

import XCTest
@testable import Kizba

final class PassShowParserTests: XCTestCase {

    // MARK: - Single-password bodies

    func testPasswordOnly() throws {
        // `pass show` always emits a trailing newline after the password.
        let raw = "hunter2\n"
        let result = try PassShowParser.parse(raw)

        XCTAssertEqual(result.password, "hunter2")
        XCTAssertTrue(result.metadata.isEmpty)
        XCTAssertNil(result.notes)
    }

    func testPasswordOnly_noTrailingNewline() throws {
        let result = try PassShowParser.parse("hunter2")

        XCTAssertEqual(result.password, "hunter2")
        XCTAssertTrue(result.metadata.isEmpty)
        XCTAssertNil(result.notes)
    }

    // MARK: - Metadata block

    func testWithMetadata() throws {
        let raw = """
        s3cret
        user: alice
        url: https://example.test
        """
        let result = try PassShowParser.parse(raw)

        XCTAssertEqual(result.password, "s3cret")
        XCTAssertEqual(result.metadata.count, 2)
        XCTAssertEqual(result.metadata[0].0, "user")
        XCTAssertEqual(result.metadata[0].1, "alice")
        XCTAssertEqual(result.metadata[1].0, "url")
        XCTAssertEqual(result.metadata[1].1, "https://example.test")
        XCTAssertNil(result.notes)
    }

    func testDuplicateKeys() throws {
        let raw = """
        pw
        tag: red
        tag: blue
        tag: green
        """
        let result = try PassShowParser.parse(raw)

        XCTAssertEqual(result.password, "pw")
        XCTAssertEqual(result.metadata.map(\.0), ["tag", "tag", "tag"])
        XCTAssertEqual(result.metadata.map(\.1), ["red", "blue", "green"])
        XCTAssertNil(result.notes)
    }

    func testColonInValue() throws {
        let raw = """
        pw
        url: https://x.test:8443/path
        ratio: 1:2:3
        """
        let result = try PassShowParser.parse(raw)

        XCTAssertEqual(result.metadata.count, 2)
        XCTAssertEqual(result.metadata[0].0, "url")
        XCTAssertEqual(result.metadata[0].1, "https://x.test:8443/path")
        XCTAssertEqual(result.metadata[1].0, "ratio")
        XCTAssertEqual(result.metadata[1].1, "1:2:3")
        XCTAssertNil(result.notes)
    }

    // MARK: - Notes

    func testWithNotes_singleLine() throws {
        let raw = """
        pw
        user: alice
        Free-form note line.
        """
        let result = try PassShowParser.parse(raw)

        XCTAssertEqual(result.password, "pw")
        XCTAssertEqual(result.metadata.count, 1)
        XCTAssertEqual(result.metadata[0].0, "user")
        XCTAssertEqual(result.metadata[0].1, "alice")
        XCTAssertEqual(result.notes, "Free-form note line.")
    }

    func testWithNotes_multiLine_preservesNewlines() throws {
        let raw = """
        pw
        user: alice
        First note line.

        Third note line, after a blank.
        """
        let result = try PassShowParser.parse(raw)

        XCTAssertEqual(result.metadata.count, 1)
        XCTAssertEqual(
            result.notes,
            "First note line.\n\nThird note line, after a blank."
        )
    }

    func testNotesContainingKeyLikeLines() throws {
        // After the first non-metadata line, every subsequent line is
        // notes — even lines that look exactly like `key: value`.
        let raw = """
        pw
        user: alice
        Some prose introducing the recovery info.
        recovery: do-not-parse-me
        backup: also-notes
        """
        let result = try PassShowParser.parse(raw)

        XCTAssertEqual(result.metadata.count, 1, "metadata block must be contiguous")
        XCTAssertEqual(result.metadata[0].0, "user")
        XCTAssertEqual(result.metadata[0].1, "alice")
        XCTAssertEqual(
            result.notes,
            "Some prose introducing the recovery info.\nrecovery: do-not-parse-me\nbackup: also-notes"
        )
    }

    func testNotesStartingImmediatelyAfterPassword() throws {
        // No metadata at all: line 2 is already notes.
        let raw = """
        pw
        Just a note, no key here.
        Second line of notes.
        """
        let result = try PassShowParser.parse(raw)

        XCTAssertEqual(result.password, "pw")
        XCTAssertTrue(result.metadata.isEmpty)
        XCTAssertEqual(
            result.notes,
            "Just a note, no key here.\nSecond line of notes."
        )
    }

    // MARK: - Empty input

    func testEmptyInput_throws() {
        XCTAssertThrowsError(try PassShowParser.parse("")) { error in
            guard case PassError.parsingFailed = error else {
                XCTFail("expected PassError.parsingFailed, got \(error)")
                return
            }
        }
    }
}
