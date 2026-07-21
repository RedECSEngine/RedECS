public struct Tile: Codable, Equatable {
    public var id: Int
    public var `class`: String

    private enum CodingKeys: String, CodingKey {
        case id, type
        // Tiled 1.9 renamed a tile's `type` to `class` in exported files
        case objectClass = "class"
    }

    public init(id: Int, class: String) {
        self.id = id
        self.class = `class`
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        `class` = try container.decodeIfPresent(String.self, forKey: .objectClass)
            ?? container.decodeIfPresent(String.self, forKey: .type)
            ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(`class`, forKey: .objectClass)
    }
}
