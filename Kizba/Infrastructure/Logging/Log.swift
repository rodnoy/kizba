//
//  Log.swift
//  Kizba
//
//  `os.Logger` wrapper for the whole module. The single source of
//  truth for logging conventions in Kizba.
//
//  ## Subsystem & categories
//
//  Subsystem: `app.kizba`. Categories:
//
//  - `shell`     — `Infrastructure/Shell/` process spawn metadata.
//  - `pass`      — `Infrastructure/Pass/` `pass` CLI orchestration.
//  - `clipboard` — `Infrastructure/Clipboard/` token / changeCount
//                  transitions only.
//  - `discovery` — `Infrastructure/Discovery/` binary resolution.
//  - `ui`        — `Presentation/` high-level lifecycle events.
//
//  ## Privacy & redaction discipline (durable, see `.ai/decisions.md`)
//
//  - Captured **`stdout`** from `Infrastructure/Shell/` and
//    `Infrastructure/Pass/` MUST NEVER be logged. There is no helper
//    on this type that accepts `stdout` data; if a value labelled
//    "stdout" must be referenced for diagnostics, only its byte
//    length may be logged (and only when there is a concrete need).
//  - **Stderr excerpts**, **file paths**, **store locations**,
//    **entry paths**, **environment variable values**, and any
//    free-form error description MUST be interpolated with
//    `privacy: .private`.
//  - **Exit codes**, **byte counts**, **argument counts**,
//    **boolean flags** and other shape-only metadata MAY be logged
//    `.public` (default) — they are sanctioned shape-only signals.
//  - The wrapper does not strip or hash payloads itself; it relies on
//    the standard `os.Logger` privacy-marker rendering. The redact()
//    helper is provided for the rare case a string must be stored
//    *outside* of `os_log` (e.g. ring buffers in Phase 8 Diagnostics)
//    where privacy markers do not apply.
//  - A static grep test (`SourceGrepTests`, Phase 3.4) bans raw
//    `print(`, `FileHandle.standardOutput` and `stdout` in
//    `Infrastructure/Shell/` + `Infrastructure/Pass/`.
//
//  ## Threading
//
//  All members are `nonisolated`. `os.Logger` is thread-safe and
//  Sendable; callers may use these loggers from any actor or detached
//  context (notably `Foundation.Process`'s private dispatch queues).
//

import Foundation
import os

/// Namespaced access to per-category `os.Logger` instances and to
/// small helpers that codify Kizba's logging discipline.
///
/// Tests use `@testable import Kizba` to reach this type.
enum Log {

    // MARK: - Subsystem & categories

    /// Reverse-DNS subsystem identifier shared by every category.
    nonisolated static let subsystem = "app.kizba"

    /// Logger for `Infrastructure/Shell/` — process spawn metadata
    /// only. Never receives `stdout` bytes.
    nonisolated static let shell = Logger(subsystem: subsystem, category: "shell")

    /// Logger for `Infrastructure/Pass/` — `pass` CLI orchestration.
    /// Never receives decrypted secrets.
    nonisolated static let pass = Logger(subsystem: subsystem, category: "pass")

    /// Logger for `Infrastructure/Clipboard/` — token / changeCount
    /// transitions only.
    nonisolated static let clipboard = Logger(subsystem: subsystem, category: "clipboard")

    /// Logger for `Infrastructure/Discovery/` — binary resolution.
    nonisolated static let discovery = Logger(subsystem: subsystem, category: "discovery")

    /// Logger for `Presentation/` — high-level UI lifecycle events.
    nonisolated static let ui = Logger(subsystem: subsystem, category: "ui")

    // MARK: - Helpers

    /// Maximum length of a stderr excerpt that we are willing to
    /// surface (after sanitisation) anywhere outside the live
    /// `os.Logger` stream. `PassErrorMapper` re-applies its own cap
    /// in Phase 4.3; this constant is the upper bound.
    nonisolated static let maxStderrExcerpt = 512

    /// Redact a free-form string for storage outside of `os_log`
    /// (e.g. an in-memory ring buffer that is later rendered into the
    /// Diagnostics view). `os.Logger` privacy markers do not apply
    /// once a value leaves the unified logging system, so callers
    /// must redact explicitly.
    ///
    /// The current implementation is a length-bounded passthrough —
    /// the stronger sanitiser (email / hex-id stripping) is the job
    /// of `PassErrorMapper` (Phase 4.3). The point of this helper is
    /// to give every call site a single, audited entry point.
    nonisolated static func redact(_ value: String, max: Int = maxStderrExcerpt) -> String {
        guard value.count > max else { return value }
        let cutoff = value.index(value.startIndex, offsetBy: max)
        return String(value[..<cutoff]) + "…"
    }
}
