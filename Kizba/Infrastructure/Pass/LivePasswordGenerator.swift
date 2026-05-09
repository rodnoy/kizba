//
//  LivePasswordGenerator.swift
//  Kizba
//
//  Production ``PasswordGenerating`` implementation backed by Swift's
//  `SystemRandomNumberGenerator` (CSPRNG; on Darwin this wraps
//  `arc4random_buf`). Used by Phase F's "New entry" form to preview a
//  candidate password before it is committed to the store via
//  `pass insert`. In-place regeneration of an existing entry uses
//  `pass generate --in-place` instead (Phase G) and does not go through
//  this type.
//
//  Charset matches `pass generate`'s defaults:
//  - Always: `[A-Za-z0-9]` (62 chars).
//  - When `includeSymbols == true`: also `pass`'s default symbol set
//    `!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~` (28 chars; ASCII printable
//    excluding alphanumerics, space and backtick-context oddities).
//    Source: `pass`'s `generate` shell function uses GNU `tr` with the
//    `[:graph:]` character class minus alphanumerics by default; the
//    explicit set codified here is the conservative, shell-safe subset
//    that matches the intent across `pass` versions 1.7.3 / 1.7.4.
//
//  Rejection sampling against modulo bias is delegated to the standard
//  library: `Int.random(in:)` uses `SystemRandomNumberGenerator` and
//  implements unbiased selection internally (it is the rejection-sampled
//  equivalent of `arc4random_uniform` on Darwin). We therefore do NOT
//  implement manual rejection here.
//
//  Security:
//  - Generated passwords are never logged.
//  - This file imports `Foundation` only; no third-party deps.
//

import Foundation

/// CSPRNG-backed ``PasswordGenerating`` for production use.
public struct LivePasswordGenerator: PasswordGenerating {

    // MARK: - Charsets

    /// `[A-Za-z0-9]` — the always-on alphanumeric character pool.
    private static let alphanumeric: [Character] = Array(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    )

    /// `pass generate`'s default symbol set (28 chars). See file header
    /// for the source / reasoning behind this exact list.
    private static let symbols: [Character] = Array(
        "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
    )

    /// Pre-built combined pool used when `includeSymbols == true`. Kept
    /// as a constant so we pay the concatenation cost at type-init
    /// rather than on every `generate(...)` call.
    private static let alphanumericPlusSymbols: [Character] =
        alphanumeric + symbols

    // MARK: - Init

    public init() {}

    // MARK: - PasswordGenerating

    public func generate(length: Int, includeSymbols: Bool) throws -> String {
        guard length > 0 else {
            throw PasswordGenerationError.invalidLength(length)
        }

        let pool: [Character] = includeSymbols
            ? Self.alphanumericPlusSymbols
            : Self.alphanumeric

        // `Int.random(in:)` uses `SystemRandomNumberGenerator` (CSPRNG)
        // and implements rejection sampling internally — picking each
        // index this way gives an unbiased uniform selection over
        // `pool`. Building the password as a `[Character]` first and
        // initialising the `String` once at the end avoids repeated
        // string-buffer reallocations.
        var characters: [Character] = []
        characters.reserveCapacity(length)
        for _ in 0..<length {
            let index = Int.random(in: 0..<pool.count)
            characters.append(pool[index])
        }
        return String(characters)
    }
}
