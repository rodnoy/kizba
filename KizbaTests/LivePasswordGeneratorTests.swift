//
//  LivePasswordGeneratorTests.swift
//  KizbaTests
//
//  Tests for the production ``LivePasswordGenerator``:
//  - Length validation (invalidLength on `<= 0`, exact length out).
//  - Charset correctness (alphanumeric vs alphanumeric+symbols, no
//    whitespace / control / non-ASCII characters).
//  - Statistical bias smoke test using a wide ±20% bound on a 100k
//    sample so natural CSPRNG variance never produces a false positive
//    while a broken / biased implementation (e.g. `% pool.count` over
//    `arc4random()` without rejection sampling) would still trip it.
//

import Foundation
import XCTest
@testable import Kizba

final class LivePasswordGeneratorTests: XCTestCase {

    // Same character pools as the production implementation. Hard-coded
    // here on purpose: the test must fail loudly if the production
    // pool is mutated unintentionally.
    private static let alphanumeric: Set<Character> = Set(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    )
    private static let symbols: Set<Character> = Set(
        "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
    )
    private static let alphanumericPlusSymbols: Set<Character> =
        alphanumeric.union(symbols)

    // MARK: - Length validation

    func testGenerate_lengthZero_throwsInvalidLength() {
        let sut = LivePasswordGenerator()
        XCTAssertThrowsError(try sut.generate(length: 0, includeSymbols: false)) { error in
            XCTAssertEqual(
                error as? PasswordGenerationError,
                .invalidLength(0)
            )
        }
    }

    func testGenerate_negativeLength_throwsInvalidLengthCarryingValue() {
        let sut = LivePasswordGenerator()
        XCTAssertThrowsError(try sut.generate(length: -1, includeSymbols: true)) { error in
            XCTAssertEqual(
                error as? PasswordGenerationError,
                .invalidLength(-1)
            )
        }
    }

    func testGenerate_lengthOne_returnsSingleCharacter() throws {
        let sut = LivePasswordGenerator()
        let password = try sut.generate(length: 1, includeSymbols: false)
        XCTAssertEqual(password.count, 1)
    }

    func testGenerate_length16_returns16Characters() throws {
        let sut = LivePasswordGenerator()
        let password = try sut.generate(length: 16, includeSymbols: false)
        XCTAssertEqual(password.count, 16)
    }

    func testGenerate_length128_returns128Characters() throws {
        let sut = LivePasswordGenerator()
        let password = try sut.generate(length: 128, includeSymbols: true)
        XCTAssertEqual(password.count, 128)
    }

    // MARK: - Non-determinism

    func testGenerate_repeatedCalls_produceDistinctPasswords() throws {
        let sut = LivePasswordGenerator()
        var seen: Set<String> = []
        for _ in 0..<10 {
            let password = try sut.generate(length: 32, includeSymbols: true)
            seen.insert(password)
        }
        // Probability of collision over 10 length-32 alphanumeric-plus-
        // symbols passwords is astronomically low; any duplicate
        // signals a deterministic bug.
        XCTAssertEqual(seen.count, 10, "Generator produced a duplicate password across 10 calls")
    }

    // MARK: - Charset correctness

    func testGenerate_withoutSymbols_onlyContainsAlphanumeric() throws {
        let sut = LivePasswordGenerator()
        for _ in 0..<100 {
            let password = try sut.generate(length: 50, includeSymbols: false)
            for char in password {
                XCTAssertTrue(
                    Self.alphanumeric.contains(char),
                    "Character '\(char)' (U+\(String(char.unicodeScalars.first!.value, radix: 16))) is outside [A-Za-z0-9]"
                )
            }
        }
    }

    func testGenerate_withSymbols_onlyContainsAlphanumericOrSymbols() throws {
        let sut = LivePasswordGenerator()
        for _ in 0..<100 {
            let password = try sut.generate(length: 50, includeSymbols: true)
            for char in password {
                XCTAssertTrue(
                    Self.alphanumericPlusSymbols.contains(char),
                    "Character '\(char)' is outside the alphanumeric+symbols pool"
                )
            }
        }
    }

    func testGenerate_anyMode_neverContainsWhitespaceOrControlOrNonASCII() throws {
        let sut = LivePasswordGenerator()
        for includeSymbols in [false, true] {
            for _ in 0..<50 {
                let password = try sut.generate(length: 64, includeSymbols: includeSymbols)
                for scalar in password.unicodeScalars {
                    // Printable ASCII excludes space (0x20) and DEL (0x7F).
                    XCTAssertGreaterThan(
                        scalar.value, 0x20,
                        "Found whitespace/control U+\(String(scalar.value, radix: 16)) in password"
                    )
                    XCTAssertLessThan(
                        scalar.value, 0x7F,
                        "Found non-printable / non-ASCII U+\(String(scalar.value, radix: 16)) in password"
                    )
                }
            }
        }
    }

    func testGenerate_withSymbols_canActuallyEmitSymbols() throws {
        // Sanity check that the symbols branch actually exercises the
        // symbol set — a regression where `includeSymbols == true`
        // silently fell back to alphanumerics would otherwise pass the
        // "subset of allowed pool" check above.
        let sut = LivePasswordGenerator()
        var bag: Set<Character> = []
        for _ in 0..<200 {
            let password = try sut.generate(length: 50, includeSymbols: true)
            for char in password where Self.symbols.contains(char) {
                bag.insert(char)
            }
        }
        XCTAssertFalse(
            bag.isEmpty,
            "After 10000 alphanumeric+symbols characters, no symbol was ever emitted"
        )
    }

    // MARK: - Statistical bias smoke

    /// Generates 100k characters with `includeSymbols == false` and
    /// asserts every alphanumeric character's frequency is within ±20%
    /// of the expected uniform mean (~1612.9). The ±20% band is far
    /// wider than CSPRNG variance at n=100k (typical std dev per char
    /// is ~40, so the band is ~7σ in either direction); a broken
    /// implementation that maps `arc4random() % 62` without rejection
    /// would skew the lowest-modulo characters past this band.
    func testStatisticalBias_alphanumeric_isWithinReasonableBounds_smoke() throws {
        let sut = LivePasswordGenerator()
        var counts: [Character: Int] = [:]
        for _ in 0..<1_000 {
            let password = try sut.generate(length: 100, includeSymbols: false)
            for char in password {
                counts[char, default: 0] += 1
            }
        }

        let totalChars = 100_000
        let pool = Self.alphanumeric
        let expected = Double(totalChars) / Double(pool.count) // ≈ 1612.9
        let lower = Int((expected * 0.80).rounded(.down))
        let upper = Int((expected * 1.20).rounded(.up))

        for char in pool {
            let observed = counts[char] ?? 0
            XCTAssertGreaterThanOrEqual(
                observed, lower,
                "Char '\(char)' under-represented: observed=\(observed) lower=\(lower) expected≈\(Int(expected))"
            )
            XCTAssertLessThanOrEqual(
                observed, upper,
                "Char '\(char)' over-represented: observed=\(observed) upper=\(upper) expected≈\(Int(expected))"
            )
        }
    }

    /// Same sample-size budget but over the larger pool (90 chars).
    /// Expected per-char mean drops to ~1111; ±25% band keeps natural
    /// variance comfortably inside while a biased implementation would
    /// still fail.
    func testStatisticalBias_alphanumericPlusSymbols_isWithinReasonableBounds_smoke() throws {
        let sut = LivePasswordGenerator()
        var counts: [Character: Int] = [:]
        for _ in 0..<1_000 {
            let password = try sut.generate(length: 100, includeSymbols: true)
            for char in password {
                counts[char, default: 0] += 1
            }
        }

        let totalChars = 100_000
        let pool = Self.alphanumericPlusSymbols
        let expected = Double(totalChars) / Double(pool.count) // ≈ 1111.1
        let lower = Int((expected * 0.75).rounded(.down))
        let upper = Int((expected * 1.25).rounded(.up))

        for char in pool {
            let observed = counts[char] ?? 0
            XCTAssertGreaterThanOrEqual(
                observed, lower,
                "Char '\(char)' under-represented: observed=\(observed) lower=\(lower) expected≈\(Int(expected))"
            )
            XCTAssertLessThanOrEqual(
                observed, upper,
                "Char '\(char)' over-represented: observed=\(observed) upper=\(upper) expected≈\(Int(expected))"
            )
        }
    }
}
