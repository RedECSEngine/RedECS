public struct TiledWangColor: Codable, Equatable, Sendable {
    public var name: String
    public var color: String
    public var probability: Double
    public var tile: Int

    public init(name: String, color: String, probability: Double, tile: Int) {
        self.name = name
        self.color = color
        self.probability = probability
        self.tile = tile
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? ""
        probability = try container.decodeIfPresent(Double.self, forKey: .probability) ?? 1
        tile = try container.decodeIfPresent(Int.self, forKey: .tile) ?? -1
    }
}

public struct TiledWangTile: Codable, Equatable, Sendable {
    public var tileid: Int
    public var wangid: [Int]

    public init(tileid: Int, wangid: [Int]) {
        self.tileid = tileid
        self.wangid = wangid
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tileid = try container.decodeIfPresent(Int.self, forKey: .tileid) ?? 0
        wangid = try container.decodeIfPresent([Int].self, forKey: .wangid) ?? []
    }
}

public struct TiledWangSet: Codable, Equatable, Sendable {
    public var name: String
    public var type: String
    public var tile: Int
    public var colors: [TiledWangColor]
    public var wangtiles: [TiledWangTile]
    public var properties: [TiledProperty]

    public init(
        name: String,
        type: String,
        tile: Int = -1,
        colors: [TiledWangColor] = [],
        wangtiles: [TiledWangTile] = [],
        properties: [TiledProperty] = []
    ) {
        self.name = name
        self.type = type
        self.tile = tile
        self.colors = colors
        self.wangtiles = wangtiles
        self.properties = properties
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        tile = try container.decodeIfPresent(Int.self, forKey: .tile) ?? -1
        colors = try container.decodeIfPresent([TiledWangColor].self, forKey: .colors) ?? []
        wangtiles = try container.decodeIfPresent([TiledWangTile].self, forKey: .wangtiles) ?? []
        properties = try container.decodeIfPresent([TiledProperty].self, forKey: .properties) ?? []
    }
}
