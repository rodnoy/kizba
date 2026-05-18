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
