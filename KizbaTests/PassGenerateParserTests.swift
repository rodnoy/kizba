//
//  PassGenerateParserTests.swift
//  KizbaTests
//
//  Phase D.5 / `.ai/plan.md`. Coverage for `PassGenerateParser`:
//   - ANSI SGR stripping (empty, none, single, multi, nested, bracket-safe).
//   - Real-world fixtures from `pass` 1.7.3 and 1.7.4 (plain + colored,
//     `--in-place` variant).
//   - Defensive shapes (no banner, leading/trailing whitespace, multiple
//     trailing newlines, git-style noise prefix).
//   - Error path on empty / whitespace-only input.
//   - Idempotence of `stripAnsi`.
//

import XCTest
@testable import Kizba

final class PassGenerateParserTests: XCTestCase {

    // MARK: - stripAnsi

    func testStripAnsiOnEmptyStringReturnsEmpty() {
        XCTAssertEqual(PassGenerateParser.stripAnsi(""), "")
    }

    func testStripAnsiOnPlainTextIsIdentity() {
        let raw = "The generated password for foo/bar is:\nhunter2"
        XCTAssertEqual(PassGenerateParser.stripAnsi(raw), raw)
    }

    func testStripAnsiRemovesSingleSequence() {
        let raw = "\u{001B}[33mhello\u{001B}[0m"
        XCTAssertEqual(PassGenerateParser.stripAnsi(raw), "hello")
    }

    func testStripAnsiRemovesMultipleAdjacentSequences() {
        let raw = "\u{001B}[1m\u{001B}[33mTr0ub4dor&3\u{001B}[0m"
        XCTAssertEqual(PassGenerateParser.stripAnsi(raw), "Tr0ub4dor&3")
    }

    func testStripAnsiRemovesParameterizedSequences() {
        // SGR with multiple semicolon-separated parameters is common.
        let raw = "\u{001B}[1;31;40mERROR\u{001B}[0m"
        XCTAssertEqual(PassGenerateParser.stripAnsi(raw), "ERROR")
    }

    func testStripAnsiPreservesBareBracketCharacters() {
        // Make sure `[` and `]` outside a CSI escape are NOT touched.
        let raw = "[main 1234abc] commit message [v2]"
        XCTAssertEqual(PassGenerateParser.stripAnsi(raw), raw)
    }

    func testStripAnsiPreservesContentBetweenSequences() {
        let raw = "before \u{001B}[4mmiddle\u{001B}[24m after"
        XCTAssertEqual(
            PassGenerateParser.stripAnsi(raw),
            "before middle after"
        )
    }

    func testStripAnsiIsIdempotent() {
        let inputs = [
            "",
            "no ansi here",
            "\u{001B}[33mcolored\u{001B}[0m",
            "\u{001B}[1m\u{001B}[33mTr0ub4dor&3\u{001B}[0m",
            "[main 1234abc] note [v2]"
        ]
        for input in inputs {
            let once = PassGenerateParser.stripAnsi(input)
            let twice = PassGenerateParser.stripAnsi(once)
            XCTAssertEqual(once, twice, "stripAnsi must be idempotent for: \(input)")
        }
    }

    // MARK: - parse: pass 1.7.3 fixtures

    func testParsePass173PlainOutput() throws {
        let raw = """
        The generated password for foo/bar is:
        Tr0ub4dor&3
        """
        XCTAssertEqual(try PassGenerateParser.parse(raw), "Tr0ub4dor&3")
    }

    func testParsePass173ColoredOutput() throws {
        // Path underlined (ESC[4m ... ESC[24m), password bold-yellow
        // (ESC[1m ESC[33m ... ESC[0m). Matches `pass` 1.7.3 with TTY.
        let raw =
            "The generated password for \u{001B}[4mfoo/bar\u{001B}[24m is:\n"
            + "\u{001B}[1m\u{001B}[33mTr0ub4dor&3\u{001B}[0m\n"
        XCTAssertEqual(try PassGenerateParser.parse(raw), "Tr0ub4dor&3")
    }

    // MARK: - parse: pass 1.7.4 fixtures

    func testParsePass174PlainOutput() throws {
        let raw = """
        The generated password for site/example is:
        hunter2!@#
        """
        XCTAssertEqual(try PassGenerateParser.parse(raw), "hunter2!@#")
    }

    func testParsePass174ColoredOutput() throws {
        let raw =
            "The generated password for \u{001B}[4msite/example\u{001B}[24m is:\n"
            + "\u{001B}[1m\u{001B}[33mhunter2!@#\u{001B}[0m\n"
        XCTAssertEqual(try PassGenerateParser.parse(raw), "hunter2!@#")
    }

    // MARK: - parse: --in-place variant

    func testParseInPlacePlainOutput() throws {
        // `pass generate --in-place` emits the same stdout shape as the
        // non-in-place variant; the difference is purely in side effects.
        let raw = """
        The generated password for foo/bar is:
        NewP@ssw0rd
        """
        XCTAssertEqual(try PassGenerateParser.parse(raw), "NewP@ssw0rd")
    }

    func testParseInPlaceColoredOutput() throws {
        let raw =
            "The generated password for \u{001B}[4mfoo/bar\u{001B}[24m is:\n"
            + "\u{001B}[1m\u{001B}[33mNewP@ssw0rd\u{001B}[0m\n"
        XCTAssertEqual(try PassGenerateParser.parse(raw), "NewP@ssw0rd")
    }

    // MARK: - parse: defensive shapes

    func testParseTolerantToSingleTrailingNewline() throws {
        let raw = "The generated password for foo/bar is:\nTr0ub4dor&3\n"
        XCTAssertEqual(try PassGenerateParser.parse(raw), "Tr0ub4dor&3")
    }

    func testParseTolerantToMultipleTrailingNewlines() throws {
        let raw = "The generated password for foo/bar is:\nTr0ub4dor&3\n\n\n"
        XCTAssertEqual(try PassGenerateParser.parse(raw), "Tr0ub4dor&3")
    }

    func testParseTrimsLeadingWhitespaceOnPasswordLine() throws {
        let raw = "The generated password for foo/bar is:\n   Tr0ub4dor&3   \n"
        XCTAssertEqual(try PassGenerateParser.parse(raw), "Tr0ub4dor&3")
    }

    func testParseAcceptsBareSinglePasswordLine() throws {
        // Some custom builds / wrappers might emit only the password.
        let raw = "JustAPassword"
        XCTAssertEqual(try PassGenerateParser.parse(raw), "JustAPassword")
    }

    func testParseAcceptsBareSinglePasswordLineWithTrailingNewline() throws {
        let raw = "JustAPassword\n"
        XCTAssertEqual(try PassGenerateParser.parse(raw), "JustAPassword")
    }

    func testParseDefensiveAgainstGitStyleStdoutNoise() throws {
        // `pass` itself routes git output to stderr, but if a wrapper
        // ever conflates streams the LAST-non-empty-line rule still
        // recovers the password (since the password is emitted last).
        let raw = """
        [main 1234abc] Generate password for foo/bar.
         1 file changed, 1 insertion(+)
         create mode 100644 foo/bar.gpg
        The generated password for foo/bar is:
        ButterflyEffect42
        """
        XCTAssertEqual(try PassGenerateParser.parse(raw), "ButterflyEffect42")
    }

    func testParseStripsAnsiBeforeLastLineSelection() throws {
        // A coloured banner with no trailing newline must still leave
        // the coloured password as the last non-empty line.
        let raw =
            "\u{001B}[1mBanner\u{001B}[0m\n"
            + "\u{001B}[33mFinalPassword\u{001B}[0m"
        XCTAssertEqual(try PassGenerateParser.parse(raw), "FinalPassword")
    }

    // MARK: - parse: error path

    func testParseEmptyStringThrows() {
        XCTAssertThrowsError(try PassGenerateParser.parse("")) { error in
            XCTAssertEqual(
                error as? PassGenerateParser.ParsingError,
                .emptyOutput
            )
        }
    }

    func testParseWhitespaceOnlyStringThrows() {
        XCTAssertThrowsError(try PassGenerateParser.parse("   \n\n   ")) { error in
            XCTAssertEqual(
                error as? PassGenerateParser.ParsingError,
                .emptyOutput
            )
        }
    }

    func testParseSingleNewlineThrows() {
        XCTAssertThrowsError(try PassGenerateParser.parse("\n")) { error in
            XCTAssertEqual(
                error as? PassGenerateParser.ParsingError,
                .emptyOutput
            )
        }
    }

    func testParseAnsiOnlyInputThrows() {
        // ANSI sequences with no payload reduce to empty after stripping.
        XCTAssertThrowsError(
            try PassGenerateParser.parse("\u{001B}[33m\u{001B}[0m\n")
        ) { error in
            XCTAssertEqual(
                error as? PassGenerateParser.ParsingError,
                .emptyOutput
            )
        }
    }
}
