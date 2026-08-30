enum Base64 {
    private static let padding = UInt8(ascii: "=")

    private static func value(of character: UInt8) -> UInt8? {
        switch character {
        case UInt8(ascii: "A")...UInt8(ascii: "Z"):
            return character - UInt8(ascii: "A")
        case UInt8(ascii: "a")...UInt8(ascii: "z"):
            return character - UInt8(ascii: "a") + 26
        case UInt8(ascii: "0")...UInt8(ascii: "9"):
            return character - UInt8(ascii: "0") + 52
        case UInt8(ascii: "+"):
            return 62
        case UInt8(ascii: "/"):
            return 63
        default:
            return nil
        }
    }

    static func decode(_ string: String) -> [UInt8]? {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(string.utf8.count / 4 * 3)

        var accumulator: UInt32 = 0
        var accumulatedCharacters = 0
        var reachedPadding = false

        for character in string.utf8 {
            if character == UInt8(ascii: " ")
                || character == UInt8(ascii: "\n")
                || character == UInt8(ascii: "\r")
                || character == UInt8(ascii: "\t") {
                continue
            }
            if character == padding {
                reachedPadding = true
                continue
            }
            if reachedPadding {
                return nil
            }
            guard let value = value(of: character) else { return nil }

            accumulator = (accumulator << 6) | UInt32(value)
            accumulatedCharacters += 1

            if accumulatedCharacters == 4 {
                bytes.append(UInt8((accumulator >> 16) & 0xFF))
                bytes.append(UInt8((accumulator >> 8) & 0xFF))
                bytes.append(UInt8(accumulator & 0xFF))
                accumulator = 0
                accumulatedCharacters = 0
            }
        }

        switch accumulatedCharacters {
        case 0:
            break
        case 2:
            bytes.append(UInt8((accumulator >> 4) & 0xFF))
        case 3:
            bytes.append(UInt8((accumulator >> 10) & 0xFF))
            bytes.append(UInt8((accumulator >> 2) & 0xFF))
        default:
            return nil
        }

        return bytes
    }

    static func decodeLittleEndianUInt32s(_ string: String) -> [UInt32]? {
        guard let bytes = decode(string), bytes.count % 4 == 0 else { return nil }
        var values: [UInt32] = []
        values.reserveCapacity(bytes.count / 4)
        var index = 0
        while index < bytes.count {
            let value = UInt32(bytes[index])
                | (UInt32(bytes[index + 1]) << 8)
                | (UInt32(bytes[index + 2]) << 16)
                | (UInt32(bytes[index + 3]) << 24)
            values.append(value)
            index += 4
        }
        return values
    }
}
