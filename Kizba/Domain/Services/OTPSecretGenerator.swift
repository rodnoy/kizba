//
//  OTPSecretGenerator.swift
//  Kizba
//
//  MVP9.2 — domain-layer factory for `OTPSecret` values created from
//  the entry-form "Add TOTP" sheet. Three constructors mirror the
//  three user-facing input methods that don't require parsing an
//  existing `otpauth://` URI:
//
//    - `random(...)`   — CSPRNG (CryptoKit `SymmetricKey(size: .bits160)`).
//                        Matches the RFC 4226 §4 recommendation of 160 bits
//                        for HOTP/TOTP key entropy.
//    - `fromPassphrase(...)` — deterministic SHA-256 of UTF-8 passphrase,
//                              first 20 bytes taken as the secret.
//                              The UI must warn that the same passphrase
//                              always yields the same code: this is a
//                              portability tool, not a security upgrade.
//    - `fromBase32(...)` — validates a user-typed Base32 string and
//                          normalises case + whitespace. Returns `nil`
//                          when the input is empty or contains characters
//                          outside the RFC 4648 alphabet.
//
//  All three default to canonical TOTP parameters
//  (`algorithm = .sha1`, `digits = 6`, `period = 30`) so the generated
//  URI matches the Google Authenticator default-omission convention
//  used by `OTPAuthURIBuilder`.
//
//  Security: never log the produced secret. The generated `OTPSecret`
//  inherits `OTPSecret`'s no-`Codable`/no-`description` discipline.
//

import Foundation
import CryptoKit

public enum OTPSecretGenerator {

    /// Generate a fresh random TOTP secret with 160 bits of entropy
    /// (RFC 4226 §4 recommended size). Uses CryptoKit's
    /// `SymmetricKey(size:)` which draws from the system CSPRNG.
    public static func random(
        label: String? = nil,
        issuer: String? = nil
    ) -> OTPSecret {
        // `SymmetricKeySize` ships fixed cases only at 128/192/256
        // bits; 160 bits is constructed via the bit-count initializer
        // so we get the RFC 4226 §4 recommended HOTP/TOTP key size
        // without rolling our own CSPRNG.
        let key = SymmetricKey(size: SymmetricKeySize(bitCount: 160))
        let bytes = key.withUnsafeBytes { buffer in
            Data(buffer)
        }
        return OTPSecret(
            kind: .totp(period: 30),
            secretBase32: Base32.encode(bytes),
            algorithm: .sha1,
            digits: 6,
            label: label,
            issuer: issuer
        )
    }

    /// Derive a TOTP secret deterministically from a user-supplied
    /// passphrase via SHA-256 (first 160 bits of the digest).
    ///
    /// Same passphrase → same secret → same TOTP code stream. Useful
    /// for "I want a secret I can re-derive on another machine without
    /// a backup" workflows; emphatically NOT a security upgrade over
    /// `random(...)`. The UI surfacing this method must warn the user.
    public static func fromPassphrase(
        _ passphrase: String,
        label: String? = nil,
        issuer: String? = nil
    ) -> OTPSecret {
        let hash = SHA256.hash(data: Data(passphrase.utf8))
        // First 20 bytes (160 bits) — matches `random(...)` entropy
        // size so the generated URI parameters are interchangeable.
        let bytes = Data(hash.prefix(20))
        return OTPSecret(
            kind: .totp(period: 30),
            secretBase32: Base32.encode(bytes),
            algorithm: .sha1,
            digits: 6,
            label: label,
            issuer: issuer
        )
    }

    /// Validate and wrap a user-typed Base32 secret. Returns `nil` if
    /// the input is empty or contains characters outside the RFC 4648
    /// alphabet (after whitespace and padding normalisation).
    public static func fromBase32(
        _ base32: String,
        label: String? = nil,
        issuer: String? = nil
    ) -> OTPSecret? {
        let normalized = base32
            .uppercased()
            .filter { !$0.isWhitespace }
            .replacingOccurrences(of: "=", with: "")

        guard !normalized.isEmpty else { return nil }
        guard Base32.decode(normalized) != nil else { return nil }

        return OTPSecret(
            kind: .totp(period: 30),
            secretBase32: normalized,
            algorithm: .sha1,
            digits: 6,
            label: label,
            issuer: issuer
        )
    }
}
