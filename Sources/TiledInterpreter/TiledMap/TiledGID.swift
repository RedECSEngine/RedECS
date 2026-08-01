public struct TiledGID: Equatable, Hashable, Codable, Sendable {
    public static let empty = TiledGID(rawValue: 0)

    static let flippedHorizontallyFlag: UInt32 = 0x8000_0000
    static let flippedVerticallyFlag: UInt32 = 0x4000_0000
    static let flippedDiagonallyFlag: UInt32 = 0x2000_0000
    static let rotatedHexagonal120Flag: UInt32 = 0x1000_0000
    static let idMask: UInt32 = 0x0FFF_FFFF

    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(
        id: Int,
        flippedHorizontally: Bool = false,
        flippedVertically: Bool = false,
        flippedDiagonally: Bool = false
    ) {
        var raw = UInt32(truncatingIfNeeded: id) & Self.idMask
        if flippedHorizontally { raw |= Self.flippedHorizontallyFlag }
        if flippedVertically { raw |= Self.flippedVerticallyFlag }
        if flippedDiagonally { raw |= Self.flippedDiagonallyFlag }
        self.rawValue = raw
    }

    public var id: Int { Int(rawValue & Self.idMask) }
    public var isEmpty: Bool { rawValue & Self.idMask == 0 }
    public var isFlippedHorizontally: Bool { rawValue & Self.flippedHorizontallyFlag != 0 }
    public var isFlippedVertically: Bool { rawValue & Self.flippedVerticallyFlag != 0 }
    public var isFlippedDiagonally: Bool { rawValue & Self.flippedDiagonallyFlag != 0 }
    public var isRotatedHexagonal120: Bool { rawValue & Self.rotatedHexagonal120Flag != 0 }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(UInt32.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
