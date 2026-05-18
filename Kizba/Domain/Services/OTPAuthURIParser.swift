import Foundation

public enum OTPAuthURIParserError: Error, Equatable {
    case invalidScheme
    case unsupportedKind(String)
    case missingSecret
    case invalidBase32
    case unknownAlgorithm(String)
    case invalidDigits
    case invalidPeriod
    case invalidCounter
    case malformedURI
}

public struct OTPAuthURIParser {
    public static func parse(_ uri: String) throws -> OTPSecret {
        guard let components = URLComponents(string: uri),
              components.url != nil
        else {
            throw OTPAuthURIParserError.malformedURI
        }

        guard let scheme = components.scheme else {
            throw OTPAuthURIParserError.malformedURI
        }
        guard scheme.caseInsensitiveCompare("otpauth") == .orderedSame else {
            throw OTPAuthURIParserError.invalidScheme
        }

        guard let host = components.host, !host.isEmpty else {
            throw OTPAuthURIParserError.malformedURI
        }

        let hostLower = host.lowercased()
        guard hostLower == "totp" || hostLower == "hotp" else {
            throw OTPAuthURIParserError.unsupportedKind(host)
        }

        let queryItems = components.queryItems ?? []

        guard let rawSecret = firstQueryValue(named: "secret", in: queryItems),
              !rawSecret.isEmpty
        else {
            throw OTPAuthURIParserError.missingSecret
        }
        let secretBase32 = try normalizeBase32(rawSecret)

        let algorithm = try parseAlgorithm(from: firstQueryValue(named: "algorithm", in: queryItems))
        let digits = try parseDigits(from: firstQueryValue(named: "digits", in: queryItems))

        let labelAndIssuer = parseLabelAndIssuer(fromPath: components.path)
        let queryIssuer = firstQueryValue(named: "issuer", in: queryItems)
        let finalIssuer = queryIssuer?.isEmpty == false ? queryIssuer : labelAndIssuer.issuer

        let kind: OTPSecret.Kind
        if hostLower == "totp" {
            let period = try parsePeriod(from: firstQueryValue(named: "period", in: queryItems))
            kind = .totp(period: period)
        } else {
            let counter = try parseCounter(from: firstQueryValue(named: "counter", in: queryItems))
            kind = .hotp(counter: counter)
        }

        return OTPSecret(
            kind: kind,
            secretBase32: secretBase32,
            algorithm: algorithm,
            digits: digits,
            label: labelAndIssuer.label,
            issuer: finalIssuer
        )
    }

    private static func firstQueryValue(named name: String, in items: [URLQueryItem]) -> String? {
        items.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })?.value
    }

    private static func normalizeBase32(_ raw: String) throws -> String {
        let normalized = raw
            .uppercased()
            .replacingOccurrences(of: "=", with: "")
            .filter { !$0.isWhitespace }

        guard !normalized.isEmpty else {
            throw OTPAuthURIParserError.invalidBase32
        }

        let allowed = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        guard normalized.allSatisfy({ allowed.contains($0) }) else {
            throw OTPAuthURIParserError.invalidBase32
        }

        return normalized
    }

    private static func parseAlgorithm(from raw: String?) throws -> OTPSecret.Algorithm {
        guard let raw else { return .sha1 }
        switch raw.lowercased() {
        case "sha1": return .sha1
        case "sha256": return .sha256
        case "sha512": return .sha512
        default: throw OTPAuthURIParserError.unknownAlgorithm(raw)
        }
    }

    private static func parseDigits(from raw: String?) throws -> Int {
        guard let raw else { return 6 }
        guard let digits = Int(raw), digits == 6 || digits == 8 else {
            throw OTPAuthURIParserError.invalidDigits
        }
        return digits
    }

    private static func parsePeriod(from raw: String?) throws -> TimeInterval {
        guard let raw else { return 30 }
        guard let period = TimeInterval(raw), period > 0 else {
            throw OTPAuthURIParserError.invalidPeriod
        }
        return period
    }

    private static func parseCounter(from raw: String?) throws -> UInt64 {
        guard let raw, let counter = UInt64(raw) else {
            throw OTPAuthURIParserError.invalidCounter
        }
        return counter
    }

    private static func parseLabelAndIssuer(fromPath path: String) -> (label: String?, issuer: String?) {
        var trimmed = path
        while trimmed.hasPrefix("/") {
            trimmed.removeFirst()
        }

        guard !trimmed.isEmpty else {
            return (nil, nil)
        }

        if let separator = trimmed.firstIndex(of: ":") {
            let prefix = String(trimmed[..<separator])
            let account = String(trimmed[trimmed.index(after: separator)...])
            let label = account.isEmpty ? nil : account
            let issuer = prefix.isEmpty ? nil : prefix
            return (label, issuer)
        }

        return (trimmed, nil)
    }
}
