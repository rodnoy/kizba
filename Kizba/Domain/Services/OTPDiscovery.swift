import Foundation

enum OTPDiscovery {
    static func firstOTPSecret(in secret: PassSecret) -> OTPSecret? {
        // 1. Metadata field with key 'otpauth' (case-insensitive).
        //    Try the value verbatim first, then with the 'otpauth:' scheme
        //    re-prepended. The latter recovers from `PassShowParser` splitting
        //    a bare `otpauth://totp/...` body line by its first colon, which
        //    leaves the value starting with `//totp/...` (scheme stripped).
        for field in secret.metadata.fields
        where field.key.caseInsensitiveCompare("otpauth") == .orderedSame {
            if let parsed = tryParse(field.value)
                ?? tryParseWithSchemeRecovered(field.value) {
                return parsed
            }
        }

        // 2. Any other metadata field whose value is itself a full
        //    `otpauth://` URI. Covers users who stored the URI under a
        //    custom key (e.g. `totp`, `2fa`).
        for field in secret.metadata.fields
        where field.key.caseInsensitiveCompare("otpauth") != .orderedSame {
            let trimmed = field.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.lowercased().hasPrefix("otpauth://") else {
                continue
            }
            if let parsed = tryParse(trimmed) {
                return parsed
            }
        }

        // 3. Notes block: scan line-by-line for `otpauth://...`.
        guard let notes = secret.metadata.notes else {
            return nil
        }

        for line in notes.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.lowercased().hasPrefix("otpauth://") else {
                continue
            }
            if let parsed = tryParse(trimmed) {
                return parsed
            }
        }

        return nil
    }

    private static func tryParse(_ value: String) -> OTPSecret? {
        try? OTPAuthURIParser.parse(value)
    }

    /// Re-prepends the `otpauth:` scheme when the value looks like a bare
    /// scheme-less URI body (`//totp/...` or `//hotp/...`). This is the
    /// shape produced by `PassShowParser` when a body line containing only
    /// `otpauth://totp/...` is split on its first colon.
    private static func tryParseWithSchemeRecovered(_ value: String) -> OTPSecret? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        guard lower.hasPrefix("//totp/") || lower.hasPrefix("//hotp/") else {
            return nil
        }
        return try? OTPAuthURIParser.parse("otpauth:" + trimmed)
    }
}
