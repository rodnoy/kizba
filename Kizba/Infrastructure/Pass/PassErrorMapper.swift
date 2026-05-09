//
//  PassErrorMapper.swift
//  Kizba
//
//  Maps `pass` / `gpg` stderr output (with optional exit code) onto a
//  `PassError` case, and produces a sanitised, length-limited excerpt
//  suitable for UI surfacing and the Diagnostics ring buffer.
//
//  Hard rules (per `.ai/decisions.md` and `.ai/plan.md` Phase 4.3 / 8.5
//  / E.4):
//
//  - This type is pure: no shell, no FileManager, no logging. Inputs may
//    contain user-identifying material (emails, key IDs, paths); outputs
//    that are user-displayed (the `excerpt` tuple element) MUST be
//    scrubbed by `sanitize(_:)`.
//  - Some `PassError` cases carry a contextual payload (an offending
//    email/key id for `recipientNotFound`, an existing path for
//    `entryAlreadyExists`/`sourceNotFound`). These payloads are
//    extracted from the RAW stderr BEFORE sanitisation, so the form
//    layer can render contextual help (e.g. "alice@example.com is not
//    in your .gpg-id"). The separately returned `excerpt` is always
//    sanitised — callers that surface stderr to the UI must use the
//    excerpt, never the case payload.
//  - The mapper never throws; every input yields a `(PassError, String)`
//    pair so callers can propagate a deterministic error UI state.
//  - Sanitisation is idempotent — feeding the result back through
//    `sanitize` produces the same string (verified by tests).
//

import Foundation

/// Pure mapper from `pass` / `gpg` stderr signatures to ``PassError``.
///
/// Recognised signatures (ordered by specificity):
///
/// Read-side (MVP 1):
/// | Signature                                              | Mapped case               |
/// | ------------------------------------------------------ | ------------------------- |
/// | `decryption failed`, `no secret key`, `bad session key`| `.decryptionFailed`       |
/// | `pinentry`, `no pinentry`, `inappropriate ioctl`       | `.pinentryNotConfigured`  |
/// | `<path>: No such file or directory`, `command not found`, `is not in the password store` (binary-shaped path) | `.binaryNotFound(name)` |
/// | exit code matches a configured timeout sentinel, or stderr mentions `timed out` / `timeout` | `.timedOut` |
/// | anything else                                          | `.shellFailure`           |
///
/// Write-side (MVP 2 Phase E.4):
/// | Signature                                              | Mapped case               |
/// | ------------------------------------------------------ | ------------------------- |
/// | `Cowardly refusing`, `mv: refusing to overwrite`, `already exists` | `.entryAlreadyExists(path:)` |
/// | `gpg: <id>: skipped: No public key`, `encryption failed: No public key` | `.recipientNotFound(emailOrKeyId:)` |
/// | `pass-length must be a positive integer`               | `.invalidLength`          |
/// | `password store is empty`, `you must run "pass init"`, `pass init … requires` | `.invalidGpgId` |
/// | `is not in the password store` + `commandContext` ∈ {.move, .remove} | `.sourceNotFound(path:)` |
/// | `is not in the password store` + other context         | `.invalidGpgId`           |
///
/// The accompanying excerpt is always passed through ``sanitize(_:maxLength:)``.
public nonisolated struct PassErrorMapper: Sendable {

    /// Default length cap for sanitised excerpts. Chosen to comfortably
    /// fit a single-line UI message while preserving enough context for
    /// the Diagnostics view.
    public static let defaultMaxLength: Int = 256

    /// The conventional POSIX-ish exit code used by ``ProcessShellRunner``
    /// to signal a timeout. Kept loosely coupled — callers may pass any
    /// exit code; the mapper treats this value (or a stderr "timeout"
    /// signature) as a timeout.
    public static let timeoutExitCode: Int = 124

    /// Disambiguation hint passed by the caller so the mapper can pick
    /// the right case for ambiguous stderr signatures.
    ///
    /// Example: `Error: foo/bar is not in the password store.` is emitted
    /// by both `pass mv` (entry not found ⇒ ``PassError/sourceNotFound``)
    /// and `pass show` against an uninitialised store (⇒
    /// ``PassError/invalidGpgId``). Without context, the mapper falls
    /// back to ``PassError/invalidGpgId`` — historically the read-side
    /// default.
    public enum CommandContext: Sendable, Equatable, Hashable {
        case show
        case list
        case insert
        case generate
        case remove
        case move
        case initStore
    }

    // MARK: - Public API

    /// Map `stderr` (and optional `exitCode`) to a domain ``PassError`` and
    /// a sanitised, length-limited excerpt.
    ///
    /// - Parameters:
    ///   - stderr: raw stderr captured from the child process. May be empty.
    ///   - exitCode: process exit code, if known. `nil` is treated as
    ///     "unknown" and only the stderr is considered.
    ///   - commandContext: which `pass` subcommand was running when the
    ///     stderr was produced. Used to disambiguate signatures shared by
    ///     multiple subcommands (see ``CommandContext``). Defaults to
    ///     `nil` for backward compatibility with read-side call sites.
    /// - Returns: `(error, excerpt)` — `excerpt` is always sanitised and
    ///   trimmed to ``defaultMaxLength``.
    public static func map(
        stderr: String,
        exitCode: Int?,
        commandContext: CommandContext? = nil
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

        // ──────────────────────────────────────────────────────────────
        // Write-side signatures (Phase E.4). Order matters: more specific
        // collision / overwrite signatures must precede the generic
        // "is not in the password store" branch, which itself precedes
        // the "no such file" missing-binary branch.
        // ──────────────────────────────────────────────────────────────

        // `pass insert` / `pass mv` overwrite refusal. Three observed
        // shapes:
        //   - `Cowardly refusing to overwrite '<store>/<path>.gpg'`  (pass 1.7.3)
        //   - `Error: <path> already exists.`                        (pass 1.7.3 / 1.7.4)
        //   - `mv: refusing to overwrite '<store>/<path>.gpg'`       (mv(1) underlying pass mv)
        if lower.contains("cowardly refusing")
            || lower.contains("refusing to overwrite")
            || lower.contains("already exists")
        {
            let path = parseEntryPath(from: stderr, signature: .alreadyExists)
            return (.entryAlreadyExists(path: path), excerpt)
        }

        // `gpg` recipient resolution failure. Two observed shapes:
        //   - `gpg: alice@example.com: skipped: No public key`
        //   - `gpg: [stdin]: encryption failed: No public key`
        // Both reduce to "no public key for at least one recipient".
        if lower.contains("no public key") {
            let id = parseRecipientIdentifier(from: stderr)
            return (.recipientNotFound(emailOrKeyId: id), excerpt)
        }

        // `pass generate` length validation. Real strings:
        //   - `Error: pass-length "abc" must be a positive integer.`
        //   - `Error: pass-length must be a positive integer.`
        if lower.contains("pass-length")
            && lower.contains("must be a positive integer")
        {
            return (.invalidLength, excerpt)
        }

        // Store not initialised / no usable .gpg-id. Real strings:
        //   - `Error: password store is empty. Try "pass init".`
        //   - `You must run "pass init" first.`
        //   - `Error: pass init <gpg-id> requires a key.`
        if lower.contains("password store is empty")
            || lower.contains("you must run \"pass init\"")
            || lower.contains("you must run pass init")
            || (lower.contains("pass init") && lower.contains("requires"))
        {
            return (.invalidGpgId, excerpt)
        }

        // `pass mv` / `pass rm` against a non-existent entry, OR
        // `pass show` against an uninitialised store — same string,
        // different command. The CommandContext disambiguates.
        //
        // Example: `Error: foo/bar is not in the password store.`
        if lower.contains("is not in the password store") {
            switch commandContext {
            case .move, .remove:
                let path = parseEntryPath(from: stderr, signature: .notInStore)
                return (.sourceNotFound(path: path), excerpt)
            default:
                // Read-side default preserves historical behaviour:
                // an uninitialised / mis-configured store surfaces as
                // `.invalidGpgId`, which the UI maps to onboarding.
                return (.invalidGpgId, excerpt)
            }
        }

        // ──────────────────────────────────────────────────────────────
        // Read-side missing-binary fallback. Stays AFTER write-side
        // signatures because some write-side stderrs also mention "no
        // such file or directory" downstream (e.g. mv complaints).
        // ──────────────────────────────────────────────────────────────

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

    /// Discriminator for `parseEntryPath(from:signature:)`. Keeps the
    /// extraction strategy for each stderr family explicit at call sites.
    private enum EntryPathSignature {
        /// `Cowardly refusing to overwrite '<store>/<path>.gpg'`,
        /// `mv: refusing to overwrite '<store>/<path>.gpg'`, or
        /// `Error: <path> already exists.`.
        case alreadyExists
        /// `Error: <path> is not in the password store.`.
        case notInStore
    }

    /// Best-effort extraction of an entry path (relative store path,
    /// without `.gpg` suffix) from a write-side stderr line.
    ///
    /// The returned path is purely informational — the form layer uses it
    /// to render contextual help. Returns an empty string when nothing
    /// recognisable is present (callers must tolerate this; the UI
    /// renders a generic message in that case).
    private static func parseEntryPath(
        from stderr: String,
        signature: EntryPathSignature
    ) -> String {
        switch signature {
        case .alreadyExists:
            // Prefer the quoted absolute path shape used by both
            // `pass`'s "Cowardly refusing" message and mv's "refusing
            // to overwrite". Strip a trailing `.gpg`, then keep only
            // the tail relative to `.password-store/` when present.
            if let quoted = firstQuotedToken(in: stderr) {
                return relativeEntryPath(fromAbsolutePath: quoted)
            }
            // Fallback shape: `Error: <path> already exists.`
            if let range = stderr.range(of: "already exists", options: .caseInsensitive) {
                let head = stderr[..<range.lowerBound]
                let trimmedHead = head.trimmingCharacters(in: .whitespacesAndNewlines)
                let withoutLeader = stripErrorLeader(trimmedHead)
                return withoutLeader.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return ""

        case .notInStore:
            // Shape: `Error: <path> is not in the password store.`
            if let range = stderr.range(of: "is not in the password store", options: .caseInsensitive) {
                let head = stderr[..<range.lowerBound]
                let trimmedHead = head.trimmingCharacters(in: .whitespacesAndNewlines)
                let withoutLeader = stripErrorLeader(trimmedHead)
                return withoutLeader.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return ""
        }
    }

    /// Returns the first single-quoted token in `stderr`, or `nil`.
    /// Used to lift the absolute path out of `'<store>/<path>.gpg'`.
    private static func firstQuotedToken(in stderr: String) -> String? {
        guard let openIndex = stderr.firstIndex(of: "'") else { return nil }
        let afterOpen = stderr.index(after: openIndex)
        guard afterOpen < stderr.endIndex else { return nil }
        guard let closeIndex = stderr[afterOpen...].firstIndex(of: "'") else { return nil }
        return String(stderr[afterOpen..<closeIndex])
    }

    /// Convert `'<store>/<path>.gpg'` → `<path>`. When `path` does not
    /// look like an absolute path under `.password-store/`, returns the
    /// input with any trailing `.gpg` removed.
    private static func relativeEntryPath(fromAbsolutePath path: String) -> String {
        var p = path
        // Strip the .gpg suffix if present.
        if p.lowercased().hasSuffix(".gpg") {
            p = String(p.dropLast(4))
        }
        // Find `.password-store/` (the conventional store directory
        // name) and keep only the suffix.
        if let range = p.range(of: ".password-store/") {
            return String(p[range.upperBound...])
        }
        // Otherwise return the last path component as a best-effort
        // fallback; better to surface SOMETHING contextual than an
        // empty string.
        return (p as NSString).lastPathComponent
    }

    /// Strip a leading `Error:` (or `Error :`) prefix from `s`.
    private static func stripErrorLeader(_ s: some StringProtocol) -> String {
        let lower = s.lowercased()
        if lower.hasPrefix("error:") {
            return String(s.dropFirst("error:".count)).trimmingCharacters(in: .whitespaces)
        }
        if lower.hasPrefix("error :") {
            return String(s.dropFirst("error :".count)).trimmingCharacters(in: .whitespaces)
        }
        return String(s)
    }

    /// Best-effort extraction of the offending recipient (email or hex
    /// key id) from a `gpg` "no public key" stderr line.
    ///
    /// Two shapes handled:
    /// - `gpg: alice@example.com: skipped: No public key`
    /// - `gpg: 0123456789ABCDEF: skipped: No public key`
    ///
    /// The third common shape, `gpg: [stdin]: encryption failed: No public key`,
    /// carries no usable identifier — returns an empty string.
    private static func parseRecipientIdentifier(from stderr: String) -> String {
        // Scan line-by-line; the recipient line is usually the first
        // `gpg:` line that is followed by `skipped: No public key`.
        for rawLine in stderr.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
            let line = String(rawLine).trimmingCharacters(in: .whitespaces)
            let lower = line.lowercased()
            guard lower.contains("no public key") else { continue }

            // Drop a leading `gpg:` (and any optional whitespace).
            var body = line
            if lower.hasPrefix("gpg:") {
                body = String(body.dropFirst("gpg:".count))
                    .trimmingCharacters(in: .whitespaces)
            }

            // Split on `:` once; the head is the candidate identifier.
            // `body` now looks like one of:
            //   "alice@example.com: skipped: No public key"
            //   "0123456789ABCDEF: skipped: No public key"
            //   "[stdin]: encryption failed: No public key"
            //   "encryption failed: No public key"
            guard let firstColon = body.firstIndex(of: ":") else { continue }
            let candidate = String(body[..<firstColon])
                .trimmingCharacters(in: .whitespaces)

            // Reject obvious non-identifiers (sentinel tokens used by
            // `gpg` for the encryption-failed shape).
            let candidateLower = candidate.lowercased()
            if candidate.isEmpty
                || candidateLower == "[stdin]"
                || candidateLower == "encryption failed"
            {
                continue
            }
            return candidate
        }
        return ""
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
