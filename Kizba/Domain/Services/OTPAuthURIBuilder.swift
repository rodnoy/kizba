//
//  OTPAuthURIBuilder.swift
//  Kizba
//
//  MVP9.2 — inverse of `OTPAuthURIParser`. Constructs canonical
//  `otpauth://` URIs from `OTPSecret` values for export (QR code,
//  Copy URI, Copy manual secret) and for round-tripping a freshly
//  generated secret back into the entry's metadata.
//
//  Defaults policy (Google Authenticator KeyUriFormat):
//    - `algorithm=SHA1`, `digits=6`, `period=30` are omitted because
//      every consuming authenticator treats them as defaults; encoding
//      them only inflates the QR payload.
//    - HOTP always emits `counter=...` (no default for HOTP counters).
//    - Label uses the `Issuer:Account` form when both are present,
//      otherwise falls back to whichever side is non-empty, and
//      ultimately to a `"Secret"` placeholder when neither is set so
//      the URI stays well-formed.
//
//  Security: never logs `secret.secretBase32`. The return string IS
//  the sensitive material — treat it like a password at the call site.
//

import Foundation

public enum OTPAuthURIBuilder {

    /// Build a canonical `otpauth://` URI per RFC 6238 /
    /// Google Authenticator KeyUriFormat.
    ///
    /// The output round-trips through `OTPAuthURIParser.parse`
    /// modulo the documented default-omission rules above.
    public static func build(_ secret: OTPSecret) -> String {
        var components = URLComponents()
        components.scheme = "otpauth"

        switch secret.kind {
        case .totp:
            components.host = "totp"
        case .hotp:
            components.host = "hotp"
        }

        components.path = "/" + label(for: secret)

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "secret", value: secret.secretBase32),
        ]

        if let issuer = secret.issuer, !issuer.isEmpty {
            queryItems.append(URLQueryItem(name: "issuer", value: issuer))
        }

        if secret.algorithm != .sha1 {
            queryItems.append(
                URLQueryItem(
                    name: "algorithm",
                    value: secret.algorithm.rawValue.uppercased()
                )
            )
        }

        if secret.digits != 6 {
            queryItems.append(
                URLQueryItem(name: "digits", value: String(secret.digits))
            )
        }

        switch secret.kind {
        case .totp(let period):
            // Encode the period only when it differs from the spec
            // default (30s). Format as an integer when fractional
            // seconds would round-trip cleanly; otherwise keep one
            // decimal so callers preserving sub-second periods are
            // still representable.
            if period != 30 {
                queryItems.append(
                    URLQueryItem(name: "period", value: formatPeriod(period))
                )
            }
        case .hotp(let counter):
            // HOTP has no default counter — always emit.
            queryItems.append(
                URLQueryItem(name: "counter", value: String(counter))
            )
        }

        components.queryItems = queryItems
        return components.string ?? ""
    }

    // MARK: - Helpers

    private static func label(for secret: OTPSecret) -> String {
        let issuer = secret.issuer.flatMap { $0.isEmpty ? nil : $0 }
        let account = secret.label.flatMap { $0.isEmpty ? nil : $0 }
        switch (issuer, account) {
        case let (i?, a?):
            return "\(i):\(a)"
        case let (nil, a?):
            return a
        case let (i?, nil):
            return i
        case (nil, nil):
            return "Secret"
        }
    }

    private static func formatPeriod(_ period: TimeInterval) -> String {
        if period.rounded() == period {
            return String(Int(period))
        }
        return String(period)
    }
}
