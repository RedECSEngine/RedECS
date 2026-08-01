public struct TiledFrame: Codable, Equatable, Sendable {
    public var tileId: Int
    public var duration: Int

    private enum CodingKeys: String, CodingKey {
        case duration
        case tileId = "tileid"
    }

    public init(tileId: Int, duration: Int) {
        self.tileId = tileId
        self.duration = duration
    }
}

public struct TiledTile: Codable, Equatable, Sendable {
    public var id: Int
    public var `class`: String
    public var probability: Double?
    public var image: String?
    public var imageWidth: Int?
    public var imageHeight: Int?
    public var animation: [TiledFrame]
    public var objectGroup: TiledLayer?
    public var properties: [TiledProperty]

    private enum CodingKeys: String, CodingKey {
        case id, type, probability, image, animation, properties
        // Tiled 1.9 renamed a tile's `type` to `class` in exported files
        case objectClass = "class"
        case imageWidth = "imagewidth"
        case imageHeight = "imageheight"
        case objectGroup = "objectgroup"
    }

    public init(
        id: Int,
        class: String,
        probability: Double? = nil,
        image: String? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        animation: [TiledFrame] = [],
        objectGroup: TiledLayer? = nil,
        properties: [TiledProperty] = []
    ) {
        self.id = id
        self.class = `class`
        self.probability = probability
        self.image = image
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.animation = animation
        self.objectGroup = objectGroup
        self.properties = properties
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        `class` = try container.decodeIfPresent(String.self, forKey: .objectClass)
            ?? container.decodeIfPresent(String.self, forKey: .type)
            ?? ""
        probability = try container.decodeIfPresent(Double.self, forKey: .probability)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        imageWidth = try container.decodeIfPresent(Int.self, forKey: .imageWidth)
        imageHeight = try container.decodeIfPresent(Int.self, forKey: .imageHeight)
        animation = try container.decodeIfPresent([TiledFrame].self, forKey: .animation) ?? []
        objectGroup = try container.decodeIfPresent(TiledLayer.self, forKey: .objectGroup)
        properties = try container.decodeIfPresent([TiledProperty].self, forKey: .properties) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(`class`, forKey: .objectClass)
        try container.encodeIfPresent(probability, forKey: .probability)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(imageWidth, forKey: .imageWidth)
        try container.encodeIfPresent(imageHeight, forKey: .imageHeight)
        if !animation.isEmpty { try container.encode(animation, forKey: .animation) }
        try container.encodeIfPresent(objectGroup, forKey: .objectGroup)
        if !properties.isEmpty { try container.encode(properties, forKey: .properties) }
    }
}

public extension TiledTile {
    subscript(property name: String) -> TiledPropertyValue? {
        properties.first { $0.name == name }?.value
    }

    var isAnimated: Bool { !animation.isEmpty }

    var animationDuration: Int { animation.reduce(0) { $0 + max(0, $1.duration) } }

    func animationFrame(atMilliseconds milliseconds: Double) -> TiledFrame? {
        guard !animation.isEmpty else { return nil }
        let total = animationDuration
        guard total > 0 else { return animation.first }
        var remainder = milliseconds.truncatingRemainder(dividingBy: Double(total))
        if remainder < 0 { remainder += Double(total) }
        for frame in animation {
            remainder -= Double(max(0, frame.duration))
            if remainder < 0 { return frame }
        }
        return animation.last
    }
}
