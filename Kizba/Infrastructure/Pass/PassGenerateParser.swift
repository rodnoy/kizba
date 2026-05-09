//
//  PassGenerateParser.swift
//  Kizba
//
//  Pure parser for the stdout of `pass generate <path> <length>` and
//  its `--in-place` variant. Phase D.5 / `.ai/plan.md`.
//
//  Strictly IO-free: no shell, no FileManager, no logging. The parser
//  must never print, log, or otherwise surface its input or its
//  return value — both contain freshly minted secret material.
//

import Foundation

/// Pure extractor for the password emitted on stdout by
/// `pass generate <path> <length>` (and `pass generate --in-place ...`).
///
/// `pass` 1.7.x stdout shapes (observed in fixtures from 1.7.3 and
/// 1.7.4, with and without TTY-driven ANSI coloring):
///
/// Plain:
/// ```
/// The generated password for foo/bar is:
/// <password>
/// ```
///
/// Coloured (path underlined, password bold-yellow):
/// ```
/// The generated password for ESC[4mfoo/barESC[24m is:
/// ESC[1mESC[33m<password>ESC[0m
/// ```
///
/// `--in-place` shares the same stdout shape; the difference is purely
/// in side effects (file rewrite vs new entry creation) and stderr
/// emission, neither of which reaches this parser.
///
/// **Strategy**: strip ANSI escape sequences from the raw output, then
/// return the LAST non-empty trimmed line. The password is always the
/// final meaningful token on stdout — banner first, password second —
/// and `pass`-internal git output (when present) is routed to stderr,
/// not stdout. This rule is robust to:
///   - banner present / banner absent (older custom builds);
///   - trailing newlines (one or many);
///   - leading whitespace on the password line;
///   - any combination of ANSI SGR sequences wrapping the line.
///
/// The parsed value is returned verbatim (after trimming surrounding
/// whitespace) and is not validated for charset or length — that is
/// the caller's responsibility, and `pass generate` itself enforces
/// `--length` server-side.
public enum PassGenerateParser {

    /// Errors raised by ``parse(_:)``.
    public enum ParsingError: Error, Equatable, Sendable {
        /// The input was empty or contained only whitespace / blank
        /// lines after ANSI stripping. Emitted instead of returning an
        /// empty password so the caller cannot accidentally treat
        /// "nothing was generated" as a successful result.
        case emptyOutput
    }

    /// Pre-compiled ANSI SGR regex. Matches `ESC '[' digits-and-semicolons 'm'`,
    /// which covers every coloring sequence `pass` (and the standard
    /// `gettext` helpers it relies on) produces. Other CSI sequences
    /// (cursor movement, erase, etc.) are not emitted by `pass generate`
    /// and are intentionally not stripped — leaving them in would
    /// surface as a parse failure rather than silent corruption.
    ///
    /// `NSRegularExpression` is preferred over Swift `Regex` literals
    /// to keep this type trivially Sendable/strict-concurrency safe
    /// across all supported toolchains.
    private static let ansiRegex: NSRegularExpression = {
        // Force-try is safe: the pattern is a compile-time constant
        // verified by tests; a malformed pattern would fail in CI
        // before any user ever ran the binary.
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: "\u{001B}\\[[0-9;]*m", options: [])
    }()

    /// Extracts the generated password from `pass generate` stdout.
    ///
    /// - Parameter raw: the full `standardOutput` payload of the
    ///   subprocess invocation, decoded as UTF-8. May contain ANSI
    ///   escape sequences and any number of trailing newlines.
    /// - Returns: the password line, with ANSI stripped and
    ///   surrounding whitespace trimmed.
    /// - Throws: ``ParsingError/emptyOutput`` if no non-empty line
    ///   survives ANSI stripping and trimming.
    public static func parse(_ raw: String) throws -> String {
        let cleaned = stripAnsi(raw)
        let lines = cleaned.components(separatedBy: "\n")
        let trimmed = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let last = trimmed.last else {
            throw ParsingError.emptyOutput
        }
        return last
    }

    /// Removes ANSI SGR escape sequences (`ESC '[' params 'm'`) from
    /// `raw`. Non-ANSI content — including bare `[` characters that
    /// happen to appear inside notes or paths — is preserved verbatim.
    ///
    /// Public so tests can exercise the strip in isolation without
    /// going through the line-extraction wrapper.
    public static func stripAnsi(_ raw: String) -> String {
        let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        return ansiRegex.stringByReplacingMatches(
            in: raw,
            options: [],
            range: range,
            withTemplate: ""
        )
    }
}
