public struct SoundSpriteMap: Equatable, Codable {
    public struct Segment: Equatable {
        public var offsetMs: Double
        public var durationMs: Double
        public var loops: Bool

        public init(offsetMs: Double, durationMs: Double, loops: Bool = false) {
            self.offsetMs = offsetMs
            self.durationMs = durationMs
            self.loops = loops
        }
    }

    public var src: [String]
    public var sprite: [String: Segment]

    public init(src: [String], sprite: [String: Segment]) {
        self.src = src
        self.sprite = sprite
    }
}

extension SoundSpriteMap.Segment: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        offsetMs = try container.decode(Double.self)
        durationMs = try container.decode(Double.self)
        loops = container.isAtEnd ? false : try container.decode(Bool.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(offsetMs)
        try container.encode(durationMs)
        if loops {
            try container.encode(loops)
        }
    }
}
