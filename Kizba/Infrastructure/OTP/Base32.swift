import Foundation

public enum Base32 {
    public static func decode(_ s: String) -> Data? {
        let filtered = s.filter { !$0.isWhitespace }

        if let firstPaddingIndex = filtered.firstIndex(of: "=") {
            let suffix = filtered[firstPaddingIndex...]
            if suffix.contains(where: { $0 != "=" }) {
                return nil
            }
        }

        let normalized = filtered
            .replacingOccurrences(of: "=", with: "")
            .uppercased()

        if normalized.isEmpty {
            return Data()
        }

        var bytes: [UInt8] = []
        bytes.reserveCapacity((normalized.count * 5) / 8)

        var buffer: UInt32 = 0
        var bitsInBuffer = 0

        for char in normalized {
            guard let value = value(for: char) else {
                return nil
            }

            buffer = (buffer << 5) | UInt32(value)
            bitsInBuffer += 5

            while bitsInBuffer >= 8 {
                bitsInBuffer -= 8
                let byte = UInt8((buffer >> UInt32(bitsInBuffer)) & 0xFF)
                bytes.append(byte)
            }
        }

        if bitsInBuffer > 0 {
            let remainderMask = (UInt32(1) << UInt32(bitsInBuffer)) - 1
            if (buffer & remainderMask) != 0 {
                return nil
            }
        }

        return Data(bytes)
    }

    /// RFC 4648 Base32 encoder. Emits the canonical 32-character
    /// alphabet (`A-Z2-7`) with NO `=` padding — consistent with the
    /// otpauth:// URI convention this codebase follows everywhere
    /// (parser strips padding on decode; encoder never produces it).
    ///
    /// Pure / no allocations beyond the result string. Safe to call
    /// with empty input — returns `""`.
    public static func encode(_ data: Data) -> String {
        if data.isEmpty { return "" }

        let alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        var result = ""
        result.reserveCapacity((data.count * 8 + 4) / 5)

        var buffer: UInt32 = 0
        var bitsInBuffer = 0
        for byte in data {
            buffer = (buffer << 8) | UInt32(byte)
            bitsInBuffer += 8
            while bitsInBuffer >= 5 {
                bitsInBuffer -= 5
                let index = Int((buffer >> UInt32(bitsInBuffer)) & 0x1F)
                result.append(alphabet[index])
            }
        }

        if bitsInBuffer > 0 {
            let index = Int((buffer << UInt32(5 - bitsInBuffer)) & 0x1F)
            result.append(alphabet[index])
        }

        return result
    }

    private static func value(for char: Character) -> UInt8? {
        guard let scalar = char.unicodeScalars.first, char.unicodeScalars.count == 1 else {
            return nil
        }

        switch scalar.value {
        case 65...90: // A...Z
            return UInt8(scalar.value - 65)
        case 50...55: // 2...7
            return UInt8(scalar.value - 24)
        default:
            return nil
        }
    }
}
