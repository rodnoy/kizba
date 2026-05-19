//
//  CSVRow.swift
//  Kizba
//
//  RFC 4180 CSV parser / serializer used by the Generic and 1Password
//  CSV importers/exporters. Handles double-quoted fields, escaped
//  quotes (`""` inside a quoted value), and multi-line quoted values
//  (a CR or LF inside a `"..."` block is part of the field).
//
//  Pure value-level helpers — no `Foundation` URL / Stream APIs, no
//  I/O. Callers feed a `String` (already decoded as UTF-8) and get
//  `[[String]]` back.
//

import Foundation

/// RFC 4180 CSV row utilities.
public enum CSVRow {

    /// Parses a single CSV record (one logical row) from a string
    /// WITHOUT line endings. Used internally by ``parseAll(_:)`` and
    /// exposed for tests / callers that have already split on
    /// newlines and know the input contains no embedded newlines.
    ///
    /// - Note: This entry point does NOT handle multi-line quoted
    ///   values. Use ``parseAll(_:)`` for general CSV input.
    public static func parse(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let c = line[i]
            if inQuotes {
                if c == "\"" {
                    // Lookahead for the `""` escaped quote.
                    let next = line.index(after: i)
                    if next < line.endIndex, line[next] == "\"" {
                        current.append("\"")
                        i = next
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(c)
                }
            } else {
                if c == "," {
                    fields.append(current)
                    current = ""
                } else if c == "\"" && current.isEmpty {
                    // A quote at the start of a field opens a quoted
                    // value. Mid-field quotes are treated as literal
                    // characters (lenient mode — Bitwarden / 1Password
                    // exports never emit them, but some hand-rolled
                    // CSVs do).
                    inQuotes = true
                } else {
                    current.append(c)
                }
            }
            i = line.index(after: i)
        }
        fields.append(current)
        return fields
    }

    /// Parses entire CSV text into rows.
    ///
    /// Differences from ``parse(_:)``:
    /// - Honors `"..."` blocks across newlines (a CR/LF inside a
    ///   quoted value becomes part of the field).
    /// - Recognises `\n`, `\r\n`, and lone `\r` as row terminators
    ///   (handles exports from any of macOS / Windows / classic Mac).
    /// - Drops completely blank trailing rows (a final newline after
    ///   the last record does not produce an empty row).
    ///
    /// Iterates over Unicode scalars (not extended grapheme clusters)
    /// because Swift's `Character` model collapses CR+LF into a single
    /// grapheme cluster, which would otherwise hide the line ending
    /// from our `c == "\n"` / `c == "\r"` checks.
    public static func parseAll(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var current = ""
        var inQuotes = false

        let scalars = Array(text.unicodeScalars)
        var i = 0
        let n = scalars.count

        while i < n {
            let c = scalars[i]
            if inQuotes {
                if c == "\"" {
                    // Lookahead for `""` escaped quote.
                    if i + 1 < n, scalars[i + 1] == "\"" {
                        current.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.unicodeScalars.append(c)
                }
            } else {
                if c == "\"" && current.isEmpty {
                    inQuotes = true
                } else if c == "," {
                    currentRow.append(current)
                    current = ""
                } else if c == "\n" || c == "\r" {
                    currentRow.append(current)
                    current = ""
                    if !(currentRow.count == 1 && currentRow[0].isEmpty) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                    // CRLF — consume the matching LF so it doesn't
                    // start a second empty row.
                    if c == "\r", i + 1 < n, scalars[i + 1] == "\n" {
                        i += 1
                    }
                } else {
                    current.unicodeScalars.append(c)
                }
            }
            i += 1
        }
        // Flush trailing row (no terminator).
        if !current.isEmpty || !currentRow.isEmpty {
            currentRow.append(current)
            rows.append(currentRow)
        }
        return rows
    }

    /// Serialises a single row to an RFC 4180 line (no trailing
    /// newline). Fields containing comma, quote, CR, or LF are
    /// quoted; embedded `"` is escaped as `""`.
    public static func serialize(_ fields: [String]) -> String {
        fields.map { field in
            if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
                let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escaped)\""
            }
            return field
        }.joined(separator: ",")
    }
}
