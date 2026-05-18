//
//  OTPSecret.swift
//  Kizba
//
//  Domain model for parsed otpauth:// secrets.
//
//  Security invariants:
//  - Intentionally NOT Codable.
//  - Intentionally NOT CustomStringConvertible / CustomDebugStringConvertible.
//  - `secretBase32` must never be logged or printed.
//

import Foundation

public struct OTPSecret: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case totp(period: TimeInterval)
        case hotp(counter: UInt64)
    }

    public enum Algorithm: String, Sendable {
        case sha1
        case sha256
        case sha512
    }

    public let kind: Kind
    /// Raw normalized base32 secret. Never log or print this value.
    public let secretBase32: String
    public let algorithm: Algorithm
    public let digits: Int
    public let label: String?
    public let issuer: String?

    public init(
        kind: Kind,
        secretBase32: String,
        algorithm: Algorithm,
        digits: Int,
        label: String?,
        issuer: String?
    ) {
        self.kind = kind
        self.secretBase32 = secretBase32
        self.algorithm = algorithm
        self.digits = digits
        self.label = label
        self.issuer = issuer
    }
}
