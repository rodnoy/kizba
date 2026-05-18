import Foundation

enum OTPDiscovery {
    static func firstOTPSecret(in secret: PassSecret) -> OTPSecret? {
        if let otpAuthValue = secret.metadata.fields.first(where: {
            $0.key.caseInsensitiveCompare("otpauth") == .orderedSame
        })?.value {
            return try? OTPAuthURIParser.parse(otpAuthValue)
        }

        guard let notes = secret.metadata.notes else {
            return nil
        }

        for line in notes.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.lowercased().hasPrefix("otpauth://") else {
                continue
            }

            if let parsed = try? OTPAuthURIParser.parse(trimmed) {
                return parsed
            }
        }

        return nil
    }
}
