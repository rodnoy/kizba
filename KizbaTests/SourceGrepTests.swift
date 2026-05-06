//
//  SourceGrepTests.swift
//  KizbaTests
//
//  Static analysis tests that enforce Kizba's logging discipline at
//  build time. See `.ai/decisions.md`:
//
//  - No raw `print(` in `Infrastructure/Shell/` or
//    `Infrastructure/Pass/` — production code must route through the
//    `Log` wrapper (`os.Logger` with privacy markers).
//  - No direct references to process `stdout` / `FileHandle.standardOutput`
//    in those directories — captured `stdout` must never be logged
//    or otherwise echoed; it leaves the runner only as raw `Data`
//    inside `ShellResult.standardOutput`.
//
//  The tests anchor the repository root via `#filePath` (this file
//  lives at `<repo>/KizbaTests/SourceGrepTests.swift`), then walk the
//  two infra directories with `FileManager.enumerator`.
//

import Foundation
import XCTest

final class SourceGrepTests: XCTestCase {

    // MARK: - Repo anchoring

    /// Repository root, derived from this file's on-disk location.
    private static let repoRoot: URL = {
        // `#filePath` -> <repo>/KizbaTests/SourceGrepTests.swift
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // KizbaTests/
            .deletingLastPathComponent()  // <repo>/
    }()

    private static let infraDirectories: [String] = [
        "Kizba/Infrastructure/Shell",
        "Kizba/Infrastructure/Pass",
    ]

    // MARK: - Tests

    func testNoRawPrintInInfraShellAndPass() throws {
        try assertNoMatches(
            patterns: [
                // `print(` not preceded by an identifier character or
                // dot — excludes `someThing.print(` and `imprint(`.
                #"(?<![A-Za-z0-9_.])print\("#,
            ],
            description: "raw print(...) call"
        )
    }

    func testNoStdoutReferencesInInfraShellAndPass() throws {
        // We forbid the patterns through which captured `stdout` could
        // reach the outside world: writing to the *process'* standard
        // output via `FileHandle.standardOutput` (or its writeable
        // counterpart `FileHandle.standardOutput.write(...)`), and the
        // C-style global `stdout` symbol exposed by Darwin.
        //
        // Internal symbol names (tuple labels, enum case associated
        // values, local `let` bindings) named `stdout` are intentionally
        // **not** banned: they document the data they carry, never
        // escape these directories, and the static analyser would
        // otherwise force semantically-meaningless renames.
        try assertNoMatches(
            patterns: [
                #"FileHandle\.standardOutput"#,
                // Darwin's C `stdout` global, written via `fputs` etc.
                #"\bDarwin\.stdout\b"#,
                #"\bfputs\("#,
                #"\bfputc\("#,
                #"\bputs\("#,
                #"\bfwrite\("#,
            ],
            description: "stdout-leaking reference"
        )
    }

    // MARK: - Engine

    /// Enumerate `.swift` files under each infra directory, scan
    /// every line against `patterns`, and fail on any hit. Comments
    /// and strings are intentionally **not** stripped: a `print(` in
    /// a comment is still wrong (it advertises a forbidden pattern).
    private func assertNoMatches(
        patterns: [String],
        description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let regexes = try patterns.map {
            try NSRegularExpression(pattern: $0, options: [])
        }

        var hits: [String] = []

        for relative in Self.infraDirectories {
            let dir = Self.repoRoot.appendingPathComponent(relative, isDirectory: true)
            var isDir: ObjCBool = false
            guard
                FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir),
                isDir.boolValue
            else {
                XCTFail(
                    "Infra directory missing: \(relative). repoRoot=\(Self.repoRoot.path)",
                    file: file,
                    line: line
                )
                return
            }

            guard
                let enumerator = FileManager.default.enumerator(
                    at: dir,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                )
            else {
                XCTFail("Cannot enumerate \(relative)", file: file, line: line)
                return
            }

            for case let url as URL in enumerator {
                guard url.pathExtension == "swift" else { continue }
                // Skip ourselves should the test ever be moved into
                // an infra subtree (defensive).
                if url.lastPathComponent == "SourceGrepTests.swift" { continue }

                let contents = try String(contentsOf: url, encoding: .utf8)
                let lines = contents.split(
                    separator: "\n",
                    omittingEmptySubsequences: false
                )
                for (idx, raw) in lines.enumerated() {
                    let lineText = String(raw)
                    let range = NSRange(lineText.startIndex..., in: lineText)
                    for regex in regexes {
                        if regex.firstMatch(in: lineText, options: [], range: range) != nil {
                            hits.append(
                                "\(url.path):\(idx + 1): \(lineText.trimmingCharacters(in: .whitespaces))"
                            )
                        }
                    }
                }
            }
        }

        if !hits.isEmpty {
            XCTFail(
                "Found forbidden \(description) in Shell/ or Pass/ infra:\n"
                + hits.joined(separator: "\n"),
                file: file,
                line: line
            )
        }
    }
}
