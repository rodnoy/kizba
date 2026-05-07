//
//  PassErrorMapper.swift
//  Kizba
//
//  Maps `pass` / `gpg` stderr output (with optional exit code) onto a
//  `PassError` case, and produces a sanitised, length-limited excerpt
//  suitable for UI surfacing and the Diagnostics ring buffer.
//
//  Hard rules (per `.ai/decisions.md` and `.ai/plan.md` Phase 4.3 / 8.5):
//
//  - This type is pure: no shell, no FileManager, no logging. Inputs may
//    contain user-identifying material (emails, key IDs); outputs MUST
//    NOT.
//  - The sanitiser strips email addresses and long hex sequences (which
//    cover OpenPGP key IDs and fingerprints), collapses whitespace, and
//    caps the excerpt length.
//  - The mapper never throws; every input yields a `(PassError, String)`
//    pair so callers can propagate a deterministic error UI state.
//  - Sanitisation is idempotent — feeding the result back through
//    `sanitize` produces the same string (verified by tests).
//

import Foundation

/// Pure mapper from `pass` / `gpg` stderr signatures to ``PassError``.
///
/// The mapper recognises a small, intentional set of stderr signatures
/// observed when invoking `pass show`:
///
/// | Signature                                              | Mapped case               |
/// | ------------------------------------------------------ | ------------------------- |
/// | `decryption failed`, `no secret key`, `bad session key`| `.decryptionFailed`       |
/// | `pinentry`, `no pinentry`, `inappropriate ioctl`       | `.pinentryNotConfigured`  |
/// | `<path>: No such file or directory`, `command not found`, `is not in the password store` (binary-shaped path) | `.binaryNotFound(name)` |
/// | exit code matches a configured timeout sentinel, or stderr mentions `timed out` / `timeout` | `.timedOut` |
/// | anything else                                          | `.shellFailure`           |
///
/// The accompanying excerpt is always passed through ``sanitize(_:maxLength:)``.
public struct PassErrorMapper: Sendable {

    /// Default length cap for sanitised excerpts. Chosen to comfortably
    /// fit a single-line UI message while preserving enough context for
    /// the Diagnostics view.
    public static let defaultMaxLength: Int = 256

    /// The conventional POSIX-ish exit code used by ``ProcessShellRunner``
    /// to signal a timeout. Kept loosely coupled — callers may pass any
    /// exit code; the mapper treats this value (or a stderr "timeout"
    /// signature) as a timeout.
    public static let timeoutExitCode: Int = 124

    // MARK: - Public API

    /// Map `stderr` (and optional `exitCode`) to a domain ``PassError`` and
    /// a sanitised, length-limited excerpt.
    ///
    /// - Parameters:
    ///   - stderr: raw stderr captured from the child process. May be empty.
    ///   - exitCode: process exit code, if known. `nil` is treated as
    ///     "unknown" and only the stderr is considered.
    /// - Returns: `(error, excerpt)` — `excerpt` is always sanitised and
    ///   trimmed to ``defaultMaxLength``.
    public static func map(
        stderr: String,
        exitCode: Int?
    ) -> (error: PassError, excerpt: String) {
        let excerpt = sanitize(stderr)
        let lower = stderr.lowercased()

        // Timeout — exit-code signal first, then stderr text.
        if let code = exitCode, code == timeoutExitCode {
            return (.timedOut, excerpt)
        }
        if matchesAny(lower, ["timed out", " timeout", "operation timed out"]) {
            return (.timedOut, excerpt)
        }

        // Decryption failures (gpg).
        if matchesAny(lower, [
            "decryption failed",
            "no secret key",
            "bad session key",
            "secret key not available",
        ]) {
            return (.decryptionFailed(stderrExcerpt: excerpt), excerpt)
        }

        // Pinentry not configured / unavailable.
        if matchesAny(lower, [
            "no pinentry",
            "pinentry",
            "inappropriate ioctl for device",
            "gpg-agent",
        ]) {
            return (.pinentryNotConfigured, excerpt)
        }

        // Missing binary. We try to recover the binary name from common
        // shell error shapes.
        if let binary = parseMissingBinaryName(from: stderr) {
            return (.binaryNotFound(binary), excerpt)
        }
        if matchesAny(lower, [
            "no such file or directory",
            "command not found",
            "could not find executable",
        ]) {
            return (.binaryNotFound(""), excerpt)
        }

        // Fallback: generic shell failure with the original (possibly
        // unknown) exit code preserved.
        let code = Int32(exitCode ?? -1)
        return (.shellFailure(exitCode: code, stderrExcerpt: excerpt), excerpt)
    }

    /// Sanitise a raw stderr string for safe display in UI / Diagnostics.
    ///
    /// Pipeline:
    /// 1. Replace email-shaped tokens (`\S+@\S+`) with `<redacted-email>`.
    /// 2. Replace long hex-like runs (`\b[0-9a-f]{8,}\b`, case-insensitive)
    ///    with `<redacted-id>` — covers OpenPGP key IDs / fingerprints.
    /// 3. Collapse runs of whitespace (incl. newlines) into a single space.
    /// 4. Trim leading/trailing whitespace.
    /// 5. Cap at `maxLength` characters; append `…` when truncated.
    ///
    /// The function is idempotent: `sanitize(sanitize(x)) == sanitize(x)`.
    public static func sanitize(_ raw: String, maxLength: Int = defaultMaxLength) -> String {
        var s = raw

        // 1. Emails. `\S+@\S+` matches the canonical token shape and
        //    deliberately includes any trailing punctuation glued to it
        //    (better to over-redact than to leak).
        s = replace(in: s, pattern: #"\S+@\S+"#, with: "<redacted-email>")

        // 2. Long hex IDs. After email redaction so `<redacted-email>`
        //    itself does not match the hex rule.
        s = replace(in: s, pattern: #"(?i)\b[0-9a-f]{8,}\b"#, with: "<redacted-id>")

        // 3. Collapse whitespace runs.
        s = replace(in: s, pattern: #"\s+"#, with: " ")

        // 4. Trim.
        s = s.trimmingCharacters(in: .whitespaces)

        // 5. Length cap. The ellipsis is part of the budget so the final
        //    string is always <= maxLength characters — required for
        //    idempotency: a second pass sees `count == maxLength` and
        //    leaves the string untouched.
        if s.count > maxLength {
            let cut = max(0, maxLength - 1)
            let endIndex = s.index(s.startIndex, offsetBy: cut)
            s = String(s[..<endIndex]) + "…"
        }

        return s
    }

    // MARK: - Private helpers

    /// Returns `true` if `haystack` contains any of `needles` as a
    /// substring. `haystack` is assumed already lower-cased.
    private static func matchesAny(_ haystack: String, _ needles: [String]) -> Bool {
        for needle in needles where haystack.contains(needle) {
            return true
        }
        return false
    }

    /// Best-effort extraction of a missing-binary name from stderr. Handles
    /// two common shapes:
    ///
    /// - `"/usr/bin/pass: No such file or directory"` →  `"pass"`
    /// - `"zsh: command not found: gpg"`             →  `"gpg"`
    private static func parseMissingBinaryName(from stderr: String) -> String? {
        let lower = stderr.lowercased()

        // Shape A: "<path>: No such file or directory"
        if lower.contains("no such file or directory") {
            // Take the first whitespace-separated token; if it's a path,
            // return its last path component without trailing punctuation.
            let firstToken = stderr
                .split(whereSeparator: { $0.isWhitespace })
                .first
                .map(String.init) ?? ""
            let trimmed = firstToken.trimmingCharacters(in: CharacterSet(charactersIn: ":,"))
            if !trimmed.isEmpty {
                let component = (trimmed as NSString).lastPathComponent
                if !component.isEmpty {
                    return component
                }
            }
        }

        // Shape B: "<shell>: command not found: <name>"
        if let range = lower.range(of: "command not found:") {
            let tail = stderr[range.upperBound...]
            let token = tail
                .split(whereSeparator: { $0.isWhitespace })
                .first
                .map(String.init) ?? ""
            let trimmed = token.trimmingCharacters(in: CharacterSet(charactersIn: ":,"))
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return nil
    }

    /// Tiny wrapper around `NSRegularExpression` that returns the input
    /// untouched when the pattern fails to compile (defensive, since the
    /// patterns here are static literals).
    private static func replace(in input: String, pattern: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return input
        }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(
            in: input,
            options: [],
            range: range,
            withTemplate: template
        )
    }
}
