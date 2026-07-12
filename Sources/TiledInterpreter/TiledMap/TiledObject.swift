public struct TiledObject: Codable, Equatable {
    public var id: Int
    public var name: String
    public var rotation: Double
    public var text: TiledText?

    public var type: String?
    public var visible: Bool

    public var width: Double
    public var height: Double
    public var x: Double
    public var y: Double

    private enum CodingKeys: String, CodingKey {
        case id, name, rotation, text, type, visible, width, height, x, y
        // Tiled 1.9 renamed an object's `type` to `class` in exported files
        case objectClass = "class"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        rotation = try container.decode(Double.self, forKey: .rotation)
        text = try container.decodeIfPresent(TiledText.self, forKey: .text)
        type = try container.decodeIfPresent(String.self, forKey: .type)
            ?? container.decodeIfPresent(String.self, forKey: .objectClass)
        visible = try container.decode(Bool.self, forKey: .visible)
        width = try container.decode(Double.self, forKey: .width)
        height = try container.decode(Double.self, forKey: .height)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(rotation, forKey: .rotation)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(visible, forKey: .visible)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}
