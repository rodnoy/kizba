# Files Retrieved

1. `KizbaTests/SourceGrepTests.swift` — Single file containing all SourceGrep-style tests (914 lines). Contains `testPassSecretIsNotCodable()` (lines 119–153) and `testPassSecretIsNotStringConvertible()` (lines 159–162) which are the exact templates to copy.

# Key Structures

- **`testPassSecretIsNotCodable()`** (lines 119–153): Regex-based scan of all `.swift` files under `Kizba/` for `(?:struct|extension)\s+PassSecret\b[^:{]*:\s*([^{]*?\b(?:Codable|Encodable|Decodable)\b[^{]*)`. Collects hits and XCTFails with a descriptive message.
- **`testPassSecretIsNotStringConvertible()`** (lines 159–162): Runtime metatype check: `XCTAssertFalse((PassSecret.self as Any) is CustomStringConvertible.Type)` and same for `CustomDebugStringConvertible.Type`.
- **`testNoCodableOrCustomStringConvertible_onSearchResult()`** (lines 170+): Combined regex pattern checking both Codable AND CustomStringConvertible in one test — an alternative style already used for `SearchResult`.
- **Helper**: `Self.swiftFiles(under:)` returns all `.swift` file URLs; `Self.repoRoot` is the repo root URL; `Self.lineNumber(of:in:)` computes line number from NSRange location.

# Architecture

All source-grep tests live in one file: `KizbaTests/SourceGrepTests.swift`. They use `NSRegularExpression` to scan production source files at test time. No shell `grep` — pure Swift `String(contentsOf:)` + regex.

# Recommended Starting Point

**Target file:** `KizbaTests/SourceGrepTests.swift`

**Action:** Append two new test methods after line 162 (after `testPassSecretIsNotStringConvertible`):
1. `testOTPSecretIsNotCodable()` — copy lines 119–153, replace `PassSecret` with `OTPSecret` in regex pattern and failure message.
2. `testOTPSecretIsNotStringConvertible()` — copy lines 159–162, replace `PassSecret` with `OTPSecret`.

Alternatively, use the combined style from `testNoCodableOrCustomStringConvertible_onSearchResult()` (line 170) which checks both Codable and StringConvertible in one regex. The plan specifies two separate tests matching the PassSecret style — follow the plan.

# Risks / Unknowns

1. Verify `OTPSecret` is a `struct` (not `class` or `enum`) — the regex uses `struct|extension`. If it's an enum, add `enum` to the alternation.
2. Confirm `OTPSecret` type exists and is importable from `@testable import Kizba` (the plan says it's `public` so no issue).
3. No pbxproj changes needed — file already exists; only appending methods.
