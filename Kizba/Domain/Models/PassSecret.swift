//
//  PassSecret.swift
//  Kizba
//
//  Domain value type wrapping the decrypted result of `pass show`.
//
//  Security invariants (enforced by tests in later phases):
//  - NOT `Codable` — never serialised to disk or defaults.
//  - NOT `CustomStringConvertible` — no `description` leak.
//  - NOT `CustomDebugStringConvertible` — no `debugDescription` leak.
//  - Held only by the active `EntryDetailModel`, never by `AppState`.
//

import Foundation

/// Decrypted body of a single `pass` entry.
///
/// Holds the cleartext password, parsed ``PassMetadata`` and an optional
/// notes block. Lives only for as long as the user is viewing the
/// corresponding entry; released on selection change.
///
/// This type is intentionally `Sendable` but **not** `Codable` and
/// **not** any flavour of string-convertible. Do not add such
/// conformances — they would defeat the secret-handling discipline
/// codified in `.ai/decisions.md` and the security checklist tests.
public struct PassSecret: Sendable, Equatable {

    /// The first line of the decrypted body, with the trailing newline
    /// stripped. Stored verbatim; never composed with field keys.
    public let password: String

    /// Parsed metadata + notes. Empty by default.
    public let metadata: PassMetadata

    public init(password: String, metadata: PassMetadata = PassMetadata()) {
        self.password = password
        self.metadata = metadata
    }

    public var otpSecret: OTPSecret? {
        OTPDiscovery.firstOTPSecret(in: self)
    }
}
