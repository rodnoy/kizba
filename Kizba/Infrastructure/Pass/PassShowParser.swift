//
//  PassShowParser.swift
//  Kizba
//
//  Pure parser for the decrypted body of `pass show <entry>`.
//
//  Strictly IO-free: no shell, no FileManager, no logging. The parser
//  must never print, log, or otherwise surface its input — the input
//  is, by definition, secret material.
//

import Foundation

/// Result of parsing a `pass show` body.
///
/// - `password`: the first line of the decrypted body, verbatim except
///   for the terminating `\n` that splits it from the rest of the
///   payload. Leading/trailing whitespace inside the line is preserved.
/// - `metadata`: ordered list of `(key, value)` pairs from the
///   contiguous metadata block that immediately follows the password.
///   Duplicates are preserved in source order.
/// - `notes`: the free-form remainder of the body (joined by `\n`),
///   or `nil` when the body contains only a password and an optional
///   metadata block.
public nonisolated struct PassShowResult: Sendable, Equatable {

    public let password: String
    public let metadata: [(String, String)]
    public let notes: String?

    public init(password: String, metadata: [(String, String)], notes: String?) {
        self.password = password
        self.metadata = metadata
        self.notes = notes
    }

    public static func == (lhs: PassShowResult, rhs: PassShowResult) -> Bool {
        guard lhs.password == rhs.password, lhs.notes == rhs.notes else { return false }
        guard lhs.metadata.count == rhs.metadata.count else { return false }
        for (l, r) in zip(lhs.metadata, rhs.metadata) where l != r { return false }
        return true
    }
}

/// Pure parser for the body returned by `pass show <entry>`.
///
/// Grammar (per `.ai/plan.md`, Phase 4.1):
///
///   body       := password "\n" metadata? notes?
///   password   := <line 1, verbatim>
///   metadata   := metaLine ("\n" metaLine)*  // contiguous, may be empty
///   metaLine   := /^[A-Za-z0-9_.-]+:\s*.*$/
///   notes      := <first non-meta line and everything after, joined by "\n">
///
/// The parser never trims the password's interior whitespace and never
/// reflows notes — newlines inside the notes section are preserved
/// verbatim. Empty input throws ``PassError/parsingFailed(reason:)``.
public nonisolated struct PassShowParser: Sendable {

    /// Regex for the metadata key prefix, anchored at line start.
    /// Splitting on the *first* `:` is performed manually so that values
    /// containing `:` (e.g. `url: https://x.test:8443/path`) are kept intact.
    private static let metaPattern: String = #"^[A-Za-z0-9_.-]+:"#

    /// Parses the raw decrypted body of `pass show`.
    ///
    /// - Parameter raw: the full stdout payload, including any trailing
    ///   newline produced by `pass`.
    /// - Returns: a ``PassShowResult`` whose components match the grammar
    ///   described on the type.
    /// - Throws: ``PassError/parsingFailed(reason:)`` if `raw` is empty.
    public static func parse(_ raw: String) throws -> PassShowResult {
        if raw.isEmpty {
            throw PassError.parsingFailed(reason: "empty pass show output")
        }

        // Split preserving empty trailing lines so that notes round-trip
        // exact newline structure.
        let lines = raw.components(separatedBy: "\n")
        guard let password = lines.first else {
            throw PassError.parsingFailed(reason: "no lines in pass show output")
        }

        // Walk the contiguous metadata block.
        var metadata: [(String, String)] = []
        var index = 1
        while index < lines.count, isMetadataLine(lines[index]) {
            if let pair = splitMetadata(lines[index]) {
                metadata.append(pair)
            }
            index += 1
        }

        // Notes: from the first non-metadata line to the end, joined verbatim.
        let notes: String?
        if index < lines.count {
            // Drop a single trailing empty element produced by a final "\n"
            // when there is no real notes payload.
            let tail = Array(lines[index...])
            if tail == [""] {
                notes = nil
            } else {
                notes = tail.joined(separator: "\n")
            }
        } else {
            notes = nil
        }

        return PassShowResult(password: password, metadata: metadata, notes: notes)
    }

    // MARK: - Helpers

    /// Returns `true` iff `line` starts with `key:` where `key` matches
    /// `[A-Za-z0-9_.-]+`. The remainder of the line is unrestricted.
    private static func isMetadataLine(_ line: String) -> Bool {
        guard let range = line.range(of: metaPattern, options: .regularExpression),
              range.lowerBound == line.startIndex else {
            return false
        }
        return true
    }

    /// Splits a metadata line on the first `:` only. The value portion
    /// has a single leading space stripped (matching `\s*` after the
    /// colon as commonly produced by `pass insert -m`); further internal
    /// whitespace is preserved.
    private static func splitMetadata(_ line: String) -> (String, String)? {
        guard let colon = line.firstIndex(of: ":") else { return nil }
        let key = String(line[..<colon])
        var valueStart = line.index(after: colon)
        // Consume leading whitespace after the colon (`\s*` in the spec).
        while valueStart < line.endIndex, line[valueStart].isWhitespace {
            valueStart = line.index(after: valueStart)
        }
        let value = String(line[valueStart...])
        return (key, value)
    }
}
