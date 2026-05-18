import CryptoKit
import Foundation

private typealias SHA1 = Insecure.SHA1

public struct LiveOTPGenerator: OTPGenerating {
    public init() {}

    public func generate(_ secret: OTPSecret, at date: Date) -> String {
        let digits = validatedDigits(secret.digits)

        guard let keyData = Base32.decode(secret.secretBase32) else {
            return String(repeating: "0", count: digits)
        }

        let counter: UInt64
        switch secret.kind {
        case let .totp(period):
            guard period > 0 else {
                return String(repeating: "0", count: digits)
            }
            counter = UInt64(floor(date.timeIntervalSince1970 / period))
        case let .hotp(value):
            counter = value
        }

        var counterBigEndian = counter.bigEndian
        let counterData = Data(bytes: &counterBigEndian, count: MemoryLayout<UInt64>.size)
        let key = SymmetricKey(data: keyData)

        let digest: [UInt8]
        switch secret.algorithm {
        case .sha1:
            digest = Array(HMAC<SHA1>.authenticationCode(for: counterData, using: key))
        case .sha256:
            digest = Array(HMAC<SHA256>.authenticationCode(for: counterData, using: key))
        case .sha512:
            digest = Array(HMAC<SHA512>.authenticationCode(for: counterData, using: key))
        }

        // Never log secret material.
        let offset = Int(digest[digest.count - 1] & 0x0F)
        guard offset + 3 < digest.count else {
            return String(repeating: "0", count: digits)
        }

        let binary = ((UInt32(digest[offset]) & 0x7F) << 24)
            | (UInt32(digest[offset + 1]) << 16)
            | (UInt32(digest[offset + 2]) << 8)
            | UInt32(digest[offset + 3])

        let modulus = UInt32(truncatingIfNeeded: Int(pow(10.0, Double(digits))))
        let code = binary % modulus
        return String(format: "%0*u", digits, code)
    }

    private func validatedDigits(_ digits: Int) -> Int {
        if digits == 6 || digits == 8 {
            return digits
        }
        return 6
    }
}
