//
//  SourceGrepTests.swift
//  KizbaTests
//
//  Static analysis tests that enforce Kizba's logging and secret-handling
//  discipline at build time. See `.ai/decisions.md`:
//
//  - No raw `print(` in `Kizba/Infrastructure/` — production code must
//    route through the `Log` wrapper (`os.Logger` with privacy markers).
//  - No direct references to the process' standard output stream
//    (`FileHandle.standardOutput`, `Darwin.stdout`, `fputs`/`puts`/
//    `printf`/`fprintf`/`fwrite`) inside `Kizba/Infrastructure/`.
//    Captured `stdout` may leave the runner only as raw `Data` inside
//    `ShellResult.standardOutput`.
//  - No direct `Logger(subsystem:`/`OSLog(` instantiations outside the
//    sanctioned wrapper (`Kizba/Infrastructure/Logging/Log.swift`).
//  - `PassSecret` must not gain `Codable` conformance.
//
//  The tests anchor the repository root via `#filePath` (this file
//  lives at `<repo>/KizbaTests/SourceGrepTests.swift`), then walk the
//  relevant directories with `FileManager.enumerator`. Test sources
//  under `KizbaTests/` are excluded.
//

import Foundation
import XCTest
@testable import Kizba

final class SourceGrepTests: XCTestCase {

    // MARK: - Repo anchoring

    /// Repository root, derived from this file's on-disk location.
    private static let repoRoot: URL = {
        // `#filePath` -> <repo>/KizbaTests/SourceGrepTests.swift
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // KizbaTests/
            .deletingLastPathComponent()  // <repo>/
    }()

    /// Whole-infra root. Step 3.4 broadened scanning beyond
    /// `Shell/`+`Pass/` to the entire `Infrastructure/` tree so that
    /// any future infra subsystem inherits the discipline by default.
    private static let infraRoot: String = "Kizba/Infrastructure"

    /// Path of the sanctioned logging wrapper, relative to repo root.
    /// The only file allowed to instantiate `Logger`/`OSLog` directly.
    private static let logWrapperRelativePath: String =
        "Kizba/Infrastructure/Logging/Log.swift"

    // MARK: - Tests

    /// (1) No raw `print(` calls anywhere under `Kizba/Infrastructure/`.
    /// Test sources under `KizbaTests/` are out of scope. The
    /// sanctioned logging wrapper is excluded because its
    /// documentation legitimately spells out the forbidden tokens.
    func testNoRawPrintInInfrastructure() throws {
        try assertNoMatches(
            roots: [Self.infraRoot],
            patterns: [
                // `print(` not preceded by an identifier character or
                // dot — excludes `someThing.print(` and `imprint(`.
                #"(?<![A-Za-z0-9_.])print\("#,
            ],
            description: "raw print(...) call",
            excludedRelativePaths: [Self.logWrapperRelativePath]
        )
    }

    /// (2) No direct stdout-leaking references under
    /// `Kizba/Infrastructure/`. Banned tokens cover the Foundation,
    /// Darwin and libc surface through which captured `stdout` could
    /// reach the outside world.
    ///
    /// Internal symbol names (tuple labels, enum case associated
    /// values, local `let` bindings) named `stdout` are intentionally
    /// **not** banned: they document the data they carry, never
    /// escape these directories, and the static analyser would
    /// otherwise force semantically-meaningless renames.
    func testNoStdoutReferencesInInfrastructure() throws {
        try assertNoMatches(
            roots: [Self.infraRoot],
            patterns: [
                #"FileHandle\.standardOutput"#,
                #"\bDarwin\.stdout\b"#,
                #"\bfputs\("#,
                #"\bfputc\("#,
                #"\bputs\("#,
                // `printf(` and `fprintf(` are libc, not Swift's
                // `Swift.print`. The negative look-behind keeps the
                // `String(format:)`/`format` family unaffected.
                #"(?<![A-Za-z0-9_.])printf\("#,
                #"(?<![A-Za-z0-9_.])fprintf\("#,
                #"(?<![A-Za-z0-9_.])fwrite\("#,
            ],
            description: "stdout-leaking reference",
            excludedRelativePaths: [Self.logWrapperRelativePath]
        )
    }

    /// (3) Only `Log.swift` is allowed to instantiate `os.Logger` /
    /// `OSLog`. All other infra files must route through the wrapper.
    func testNoDirectLoggerInstantiationOutsideWrapper() throws {
        try assertNoMatches(
            roots: [Self.infraRoot],
            patterns: [
                #"\bLogger\(subsystem:"#,
                #"\bOSLog\("#,
            ],
            description: "direct Logger/OSLog instantiation outside Log wrapper",
            excludedRelativePaths: [Self.logWrapperRelativePath]
        )
    }

    /// (4) `PassSecret` must remain non-`Codable`. Scan the whole
    /// `Kizba/` tree for any `struct PassSecret` / `extension PassSecret`
    /// declaration whose conformance list contains `Codable`,
    /// `Encodable`, or `Decodable`.
    func testPassSecretIsNotCodable() throws {
        let kizbaRoot = Self.repoRoot.appendingPathComponent("Kizba", isDirectory: true)

        // Match either:
        //   struct PassSecret<…>: <conformances containing Codable/...>
        //   extension PassSecret: <conformances containing Codable/...>
        // Conformance list ends at `{` or end-of-line.
        //
        // We use a single regex with alternation; capture group 1
        // holds the conformance list for reporting.
        let pattern =
            #"(?:struct|extension)\s+PassSecret\b[^:{]*:\s*([^{]*?\b(?:Codable|Encodable|Decodable)\b[^{]*)"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])

        var hits: [String] = []
        let files = try Self.swiftFiles(under: kizbaRoot)
        for url in files {
            let contents = try String(contentsOf: url, encoding: .utf8)
            let nsRange = NSRange(contents.startIndex..., in: contents)
            regex.enumerateMatches(in: contents, options: [], range: nsRange) { match, _, _ in
                guard let match else { return }
                let lineNumber = Self.lineNumber(of: match.range.location, in: contents)
                let snippet = (contents as NSString).substring(with: match.range)
                hits.append("\(url.path):\(lineNumber): \(snippet)")
            }
        }

        if !hits.isEmpty {
            XCTFail(
                "PassSecret must NOT conform to Codable/Encodable/Decodable. "
                + "See .ai/decisions.md. Offending declarations:\n"
                + hits.joined(separator: "\n")
            )
        }
    }

    /// (5) `PassSecret` must not be `CustomStringConvertible` or
    /// `CustomDebugStringConvertible`. This runtime check complements
    /// the regex-based Codable check and prevents accidental string
    /// interpolation leaks.
    func testPassSecretIsNotStringConvertible() throws {
        XCTAssertFalse((PassSecret.self as Any) is CustomStringConvertible.Type)
        XCTAssertFalse((PassSecret.self as Any) is CustomDebugStringConvertible.Type)
    }

    /// (6) Broad scan of the whole `Kizba/` source tree for raw
    /// `print(` / `NSLog(` / `debugPrint(` calls. Pragmatic heuristics:
    /// - Skip lines whose trimmed prefix starts with `//` or `/*`.
    /// - Skip files inside any `.ai` folder and test sources.
    /// False positives are acceptable but should be rare.
    func testNoRawPrintInKizbaSource() throws {
        let kizbaRoot = Self.repoRoot.appendingPathComponent("Kizba", isDirectory: true)

        let patterns = [
            #"(?<![A-Za-z0-9_.])print\("#, // raw Swift print(
            #"(?<![A-Za-z0-9_.])NSLog\("#,
            #"(?<![A-Za-z0-9_.])debugPrint\("#,
        ]
        let regexes = try patterns.map { try NSRegularExpression(pattern: $0, options: []) }

        var hits: [String] = []
        let files = try Self.swiftFiles(under: kizbaRoot)
        for url in files {
            // Skip any tooling/state files under `.ai` and test sources.
            if url.pathComponents.contains(".ai") { continue }
            if url.pathComponents.contains("KizbaTests") { continue }

            let contents = try String(contentsOf: url, encoding: .utf8)
            let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
            for (idx, raw) in lines.enumerated() {
                let lineText = String(raw)
                let trimmed = lineText.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty { continue }
                if trimmed.hasPrefix("//") { continue }
                if trimmed.hasPrefix("/*") { continue }

                let range = NSRange(lineText.startIndex..., in: lineText)
                for regex in regexes {
                    if regex.firstMatch(in: lineText, options: [], range: range) != nil {
                        hits.append("\(url.path):\(idx + 1): " + trimmed)
                    }
                }
            }
        }

        if !hits.isEmpty {
            XCTFail("Found raw print/NSLog/debugPrint calls in Kizba source:\n" + hits.joined(separator: "\n"))
        }
    }

    /// (7) `MockPassManager` must be fully gated behind `#if DEBUG` so
    /// release binaries do not contain fixture passwords or the mock
    /// implementation. The test reads the file and asserts the first
    /// non-empty, non-comment line is `#if DEBUG` and the last such line
    /// is `#endif`.
    func testMockPassManagerIsDebugOnly() throws {
        let url = Self.repoRoot
            .appendingPathComponent("Kizba/Infrastructure/Pass/MockPassManager.swift")
        let contents = try String(contentsOf: url, encoding: .utf8)
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)

        func isSkippable(_ s: Substring) -> Bool {
            let t = s.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { return true }
            if t.hasPrefix("//") { return true }
            if t.hasPrefix("/*") { return true }
            return false
        }

        // First non-skippable line
        guard let first = lines.first(where: { !isSkippable($0) })?.trimmingCharacters(in: .whitespaces) else {
            XCTFail("MockPassManager.swift is empty or only comments")
            return
        }
        XCTAssertEqual(first, "#if DEBUG", "MockPassManager.swift must start with #if DEBUG")

        // Last non-skippable line
        guard let last = lines.reversed().first(where: { !isSkippable($0) })?.trimmingCharacters(in: .whitespaces) else {
            XCTFail("MockPassManager.swift is empty or only comments")
            return
        }
        XCTAssertEqual(last, "#endif", "MockPassManager.swift must end with #endif")
    }

    // MARK: - Phase C.6 bans
    //
    // Inline-styling bans inside `Kizba/Presentation/**/*.swift`,
    // EXCLUDING `Kizba/Presentation/DesignSystem/**`. The DesignSystem
    // subtree is the single source of truth for tokens/atoms and is
    // therefore allowed to use raw SwiftUI primitives. Every other
    // Presentation file must consume `theme.*` tokens.
    //
    // Plus repo-wide bans across `Kizba/`:
    //   - `Logger.*stdin` / `print\(.*stdin` (no stdin contents in logs).
    //   - `\bas!\b` (force casts banned per Phase A.3 hygiene).

    /// Subtree scanned by every Phase C.6 inline-styling ban.
    private static let presentationRoot: String = "Kizba/Presentation"

    /// Excluded subtree relative to repo root. The DesignSystem owns
    /// the raw primitives; all other Presentation files must go through
    /// `theme.*` tokens.
    private static let designSystemSubpath: String =
        "Kizba/Presentation/DesignSystem"

    // (8) No numeric `.padding(<number>)` — must use `theme.spacing.*`.
    func testNoInlineNumericPadding_inPresentationOutsideDS() throws {
        try assertNoMatchesInPresentationOutsideDesignSystem(
            patterns: [#"\.padding\(\s*\d"#],
            description: "inline numeric padding (use theme.spacing.*)"
        )
    }

    // (9) No literal SwiftUI color (`Color.<name>`). `Color.clear` is
    //     the single sanctioned exception — it is not a brand color but
    //     a transparent placeholder used to keep layout slots stable.
    func testNoLiteralSwiftUIColor_inPresentationOutsideDS() throws {
        try assertNoMatchesInPresentationOutsideDesignSystem(
            patterns: [#"\bColor\.[A-Za-z]+\b"#],
            description: "literal SwiftUI color (use theme.colors.*; Color.clear is the only allowed exception)",
            lineFilter: { line, regex in
                // Drop the line if every `Color.X` match on it is
                // exactly `Color.clear`. A line mixing `Color.clear`
                // with other literal colors must still fail.
                let nsLine = line as NSString
                let range = NSRange(line.startIndex..., in: line)
                let matches = regex.matches(in: line, options: [], range: range)
                guard !matches.isEmpty else { return false } // not a hit
                for match in matches {
                    let text = nsLine.substring(with: match.range)
                    if text != "Color.clear" { return true } // real hit
                }
                return false // all hits were `Color.clear`
            }
        )
    }

    // (10) No literal foreground shortcuts (`.foregroundColor(.red)`,
    //      `.foregroundStyle(.secondary)` etc.) — these must go through
    //      `theme.colors.*`.
    func testNoLiteralForegroundShortcut_inPresentationOutsideDS() throws {
        try assertNoMatchesInPresentationOutsideDesignSystem(
            patterns: [
                #"\.foregroundColor\(\.[A-Za-z]+\)"#,
                #"\.foregroundStyle\(\.[A-Za-z]+\)"#,
            ],
            description: "literal foregroundColor/foregroundStyle shortcut (use theme.colors.*)"
        )
    }

    // (11) No literal SwiftUI font (`.font(.body)`, `.font(.system(...))`).
    //      `.font(theme.typography.body)` does NOT match because the
    //      argument starts with an identifier, not a `.<name>` shortcut.
    func testNoLiteralFont_inPresentationOutsideDS() throws {
        try assertNoMatchesInPresentationOutsideDesignSystem(
            patterns: [#"\.font\(\.[A-Za-z]+"#],
            description: "literal SwiftUI font (use theme.typography.*)"
        )
    }

    // (12) No numeric corner radius — must use `theme.radius.*`.
    func testNoNumericCornerRadius_inPresentationOutsideDS() throws {
        try assertNoMatchesInPresentationOutsideDesignSystem(
            patterns: [
                #"\.cornerRadius\(\s*\d"#,
                #"RoundedRectangle\(cornerRadius:\s*\d"#,
            ],
            description: "numeric corner radius (use theme.radius.*)"
        )
    }

    // (13) No numeric `.opacity(0.x)` literal. Token-composed
    //      transparency belongs in DesignSystem; consumers should
    //      receive an opaque pre-composited token (e.g. `surfaceHover`,
    //      `scrim`) rather than apply numeric alpha at the call site.
    //      `theme.foo.opacity(0.5)` therefore also matches: a leak of
    //      this kind is a signal that the token model is missing a
    //      pre-composited variant.
    func testNoNumericOpacity_inPresentationOutsideDS() throws {
        try assertNoMatchesInPresentationOutsideDesignSystem(
            patterns: [#"\.opacity\(\s*0\.\d"#],
            description: "inline numeric opacity (encode in tokens or compose in DesignSystem)"
        )
    }

    // (14) No literal SwiftUI animation (`.animation(.easeInOut, ...)`).
    //      Use `theme.motion.animation(.standard, ...)` so that
    //      `accessibilityReduceMotion` is honored uniformly.
    func testNoLiteralAnimation_inPresentationOutsideDS() throws {
        try assertNoMatchesInPresentationOutsideDesignSystem(
            patterns: [#"\.animation\(\.[A-Za-z]+"#],
            description: "literal SwiftUI animation (use theme.motion.animation(...))"
        )
    }

    // (15) Stdin contents must never appear in logs. The ban anchors
    //      on `stdin` as a substring near `Logger`/`print(` to catch
    //      the most likely accidental introductions during Phase E
    //      (`pass insert -m` writes the secret body to stdin).
    func testNoStdinLogging_inKizbaSource() throws {
        try assertNoMatches(
            roots: ["Kizba"],
            patterns: [
                #"Logger.*stdin"#,
                #"print\(.*stdin"#,
            ],
            description: "stdin reference in logging call (never log stdin contents)"
        )
    }

    // (16) No force casts (`as!`) anywhere in `Kizba/`. Phase A.3
    //      removed the only known offender (`UserDefaultsSettingsStore`);
    //      this ban prevents regressions.
    func testNoForceCast_inKizbaSource() throws {
        try assertNoMatches(
            roots: ["Kizba"],
            patterns: [#"\bas!"#], // `\bas!\b` would not match: `!` is non-word.
            description: "force cast (as!) in Kizba sources"
        )
    }

    /// (17) Every Presentation `*Model.swift` that declares a `final class`
    /// whose name ends with `Model` must be annotated with `@Observable`.
    /// Files may opt-out by including the exact comment `// kizba:not-observable-model`.
    func testPresentationModelsRequireObservable() throws {
        let presentationDir = Self.repoRoot.appendingPathComponent(
            Self.presentationRoot, isDirectory: true
        )

        var violations: [String] = []
        var skipped: [String] = []

        // Iterate all swift files under Presentation
        for url in try Self.swiftFiles(under: presentationDir) {
            let name = url.lastPathComponent
            // Only consider files whose filename ends with Model.swift
            guard name.hasSuffix("Model.swift") else { continue }

            let contents = try String(contentsOf: url, encoding: .utf8)

            // If file contains an opt-out comment, record and skip
            if contents.contains("// kizba:not-observable-model") {
                skipped.append(url.path)
                continue
            }

            // Look for a declaration like `final class FooModel` anywhere in the file
            let pattern = #"final\s+class\s+\w+Model\b"#
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(contents.startIndex..., in: contents)
            if regex.firstMatch(in: contents, options: [], range: nsRange) != nil {
                // If a matching class exists, require the `@Observable` token somewhere
                if !contents.contains("@Observable") {
                    violations.append(url.path)
                }
            }
        }

        // Record skipped files as an XCTContext note for visibility.
        if !skipped.isEmpty {
            let msg = "Skipped (opt-out) Presentation model files:\n" + skipped.joined(separator: "\n")
            XCTContext.runActivity(named: "Presentation model opt-outs") { _ in
                XCTFail(msg) // Use XCTFail so the output is visible in xcodebuild logs as a note
            }
        }

        if !violations.isEmpty {
            XCTFail(
                "Found Presentation model classes missing @Observable. "
                + "Annotate with `@Observable` or add `// kizba:not-observable-model` to opt out.\n"
                + violations.joined(separator: "\n")
            )
        }
    }

    /// (18) Forbid constructing `*Model()` instances directly inside
    /// `.sheet { }`, `.popover { }`, or `.fullScreenCover { }` closure
    /// bodies. Files may opt-out by including the exact comment
    /// `// kizba:allow-sheet-init` anywhere in the file.
    func testNoModelConstructorInSheetBody() throws {
        let presentationDir = Self.repoRoot.appendingPathComponent(
            Self.presentationRoot, isDirectory: true
        )

        var violations: [String] = []
        var skipped: [String] = []

        // Iterate all swift files under Presentation
        for url in try Self.swiftFiles(under: presentationDir) {
            let contents = try String(contentsOf: url, encoding: .utf8)

            // If file contains an allow-list comment, record and skip
            if contents.contains("// kizba:allow-sheet-init") {
                skipped.append(url.path)
                continue
            }

            // Only consider files that declare a `final class ...Model`
            let classPattern = #"final\s+class\s+\w+Model\b"#
            let classRegex = try NSRegularExpression(pattern: classPattern, options: [])
            let nsRange = NSRange(contents.startIndex..., in: contents)
            guard classRegex.firstMatch(in: contents, options: [], range: nsRange) != nil else { continue }

            // Find SwiftUI presentation closure bodies: .sheet { ... }, .popover { ... }, .fullScreenCover { ... }
            let sheetPattern = #"\.(?:sheet|popover|fullScreenCover)\s*\{([\s\S]*?)\}"#
            let sheetRegex = try NSRegularExpression(pattern: sheetPattern, options: [.dotMatchesLineSeparators])

            // Model constructor usage pattern like `SomethingModel(`
            let initPattern = #"\b\w+Model\("#
            let initRegex = try NSRegularExpression(pattern: initPattern, options: [])

            sheetRegex.enumerateMatches(in: contents, options: [], range: nsRange) { match, _, _ in
                guard let match = match else { return }
                // capture group 1 holds the closure body contents
                let bodyRange = match.range(at: 1)
                if bodyRange.location == NSNotFound { return }
                let bodyNSString = (contents as NSString).substring(with: bodyRange)
                let bodyNSRange = NSRange(bodyNSString.startIndex..., in: bodyNSString)

                // Search for model constructor calls inside the closure body
                initRegex.enumerateMatches(in: bodyNSString, options: [], range: bodyNSRange) { imatch, _, _ in
                    guard let imatch = imatch else { return }
                    // Compute absolute location in file for line number
                    let absoluteLocation = bodyRange.location + imatch.range.location
                    let lineNumber = Self.lineNumber(of: absoluteLocation, in: contents)
                    // Extract the line for a short snippet
                    let ns = contents as NSString
                    let lineRange = ns.lineRange(for: NSRange(location: absoluteLocation, length: 0))
                    let lineText = ns.substring(with: lineRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    violations.append("\(url.path):\(lineNumber): \(lineText)")
                }
            }
        }

        // Record skipped files as an XCTContext note for visibility.
        if !skipped.isEmpty {
            let msg = "Skipped (allow-list) Presentation files:\n" + skipped.joined(separator: "\n")
            XCTContext.runActivity(named: "Presentation sheet-init allow-list") { _ in
                XCTFail(msg) // Use XCTFail so the output is visible in xcodebuild logs as a note
            }
        }

        if !violations.isEmpty {
            XCTFail(
                "Found model constructor invocations inside sheet/popover/fullScreenCover bodies. "
                + "Move model construction to parent view (use @StateObject/@State) or add `// kizba:allow-sheet-init` to opt out.\n"
                + violations.joined(separator: "\n")
            )
        }
    }

    // MARK: - Engine

    /// Enumerate `.swift` files under `Kizba/Presentation/` excluding
    /// `Kizba/Presentation/DesignSystem/`, scan every line against
    /// `patterns`, optionally filter via `lineFilter`, and fail on any
    /// remaining hit. Sharing this scaffold keeps every Phase C.6 ban
    /// consistent in scope and reporting format.
    ///
    /// `lineFilter`, if provided, is invoked once per (line, regex)
    /// pair where the regex has at least one match; returning `false`
    /// drops the hit (e.g., `Color.clear` whitelist). The default
    /// behavior is "any regex match is a hit".
    private func assertNoMatchesInPresentationOutsideDesignSystem(
        patterns: [String],
        description: String,
        lineFilter: ((String, NSRegularExpression) -> Bool)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let regexes = try patterns.map {
            try NSRegularExpression(pattern: $0, options: [])
        }

        let presentationDir = Self.repoRoot.appendingPathComponent(
            Self.presentationRoot, isDirectory: true
        )
        let designSystemPrefix = Self.repoRoot
            .appendingPathComponent(Self.designSystemSubpath, isDirectory: true)
            .standardizedFileURL
            .path

        var hits: [String] = []

        for url in try Self.swiftFiles(under: presentationDir) {
            // Skip the DesignSystem subtree.
            let path = url.standardizedFileURL.path
            if path == designSystemPrefix
                || path.hasPrefix(designSystemPrefix + "/")
            { continue }

            let contents = try String(contentsOf: url, encoding: .utf8)
            let lines = contents.split(
                separator: "\n",
                omittingEmptySubsequences: false
            )
            for (idx, raw) in lines.enumerated() {
                let lineText = String(raw)
                let range = NSRange(lineText.startIndex..., in: lineText)
                for regex in regexes {
                    guard regex.firstMatch(in: lineText, options: [], range: range) != nil else {
                        continue
                    }
                    let isHit = lineFilter?(lineText, regex) ?? true
                    if isHit {
                        hits.append(
                            "\(url.path):\(idx + 1): "
                            + lineText.trimmingCharacters(in: .whitespaces)
                        )
                    }
                }
            }
        }

        if !hits.isEmpty {
            XCTFail(
                "Found forbidden \(description):\n"
                + hits.joined(separator: "\n"),
                file: file,
                line: line
            )
        }
    }

    /// Enumerate `.swift` files under each root directory (relative to
    /// repo root), scan every line against `patterns`, and fail on any
    /// hit. Comments and strings are intentionally **not** stripped:
    /// a `print(` in a comment still advertises a forbidden pattern.
    private func assertNoMatches(
        roots: [String],
        patterns: [String],
        description: String,
        excludedRelativePaths: [String] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let regexes = try patterns.map {
            try NSRegularExpression(pattern: $0, options: [])
        }
        let excludedAbsolute: Set<String> = Set(
            excludedRelativePaths.map {
                Self.repoRoot.appendingPathComponent($0).standardizedFileURL.path
            }
        )

        var hits: [String] = []

        for relative in roots {
            let dir = Self.repoRoot.appendingPathComponent(relative, isDirectory: true)
            var isDir: ObjCBool = false
            guard
                FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir),
                isDir.boolValue
            else {
                XCTFail(
                    "Source directory missing: \(relative). repoRoot=\(Self.repoRoot.path)",
                    file: file,
                    line: line
                )
                return
            }

            for url in try Self.swiftFiles(under: dir) {
                // Skip ourselves should the test ever be moved into
                // an infra subtree (defensive).
                if url.lastPathComponent == "SourceGrepTests.swift" { continue }
                if excludedAbsolute.contains(url.standardizedFileURL.path) { continue }

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
                                "\(url.path):\(idx + 1): "
                                + lineText.trimmingCharacters(in: .whitespaces)
                            )
                        }
                    }
                }
            }
        }

        if !hits.isEmpty {
            XCTFail(
                "Found forbidden \(description):\n"
                + hits.joined(separator: "\n"),
                file: file,
                line: line
            )
        }
    }

    /// Recursively collect `.swift` files under `root`, skipping
    /// hidden files. `KizbaTests/` is excluded by construction
    /// because callers only ever pass production roots; we still
    /// double-check by path component for safety.
    private static func swiftFiles(under root: URL) throws -> [URL] {
        guard
            let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }
        var out: [URL] = []
        for case let url as URL in enumerator {
            guard url.pathExtension == "swift" else { continue }
            // Defensive: never scan test sources.
            if url.pathComponents.contains("KizbaTests") { continue }
            out.append(url)
        }
        return out
    }

    /// 1-based line number of `utf16Offset` inside `text`.
    private static func lineNumber(of utf16Offset: Int, in text: String) -> Int {
        let nsText = text as NSString
        let upTo = nsText.substring(with: NSRange(location: 0, length: utf16Offset))
        return upTo.reduce(into: 1) { count, ch in
            if ch == "\n" { count += 1 }
        }
    }
}
