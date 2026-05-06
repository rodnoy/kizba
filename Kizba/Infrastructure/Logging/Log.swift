//
//  Log.swift
//  Kizba
//
//  Minimal `os.Logger` wrapper. Per `.ai/decisions.md`:
//
//  - Subsystem `app.kizba`.
//  - Categorised loggers (`shell`, `pass`, `clipboard`, `discovery`, `ui`).
//  - Captured `stdout` from `Infrastructure/Shell/` and
//    `Infrastructure/Pass/` MUST NOT reach this logger — callers pass
//    only sanitised metadata (executable path, arg count, exit code,
//    stderr length). Stderr excerpts, when logged at all, must use the
//    `.private` privacy marker.
//
//  This is the minimal surface required for Phase 3.1
//  (`ProcessShellRunner`). Phase 3.2 may grow it (additional helpers,
//  signpost APIs) but should preserve the no-stdout discipline.
//

import Foundation
import os

/// Namespaced access to per-category `os.Logger` instances.
///
/// All identifiers are `internal` — callers stay inside the Kizba
/// module; tests use `@testable import Kizba` if needed.
enum Log {

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
}
