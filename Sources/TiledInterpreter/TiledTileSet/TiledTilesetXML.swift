public struct TiledTilesetXML: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey {
        case name
        case image
        case tileWidth = "tilewidth"
        case tileHeight = "tileheight"
        case tileCount = "tilecount"
        case columns
        case margin
        case spacing
        case tiles = "tile"
    }

    public var name: String
    public var tileWidth: Int
    public var tileHeight: Int
    public var tileCount: Int
    public var columns: Int
    public var margin: Int?
    public var spacing: Int?
    public var image: Image
    public var tiles: [TiledTile]?
}

public extension TiledTilesetXML {
    struct Image: Codable, Equatable, Sendable {
        public var source: String
        public var width: Int
        public var height: Int
    }
}

public extension TiledTilesetXML {
    func toJSONFormat() -> TiledTilesetJSON {
        TiledTilesetJSON(
            name: name,
            image: image.source,
            imageWidth: image.width,
            imageHeight: image.height,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            tileCount: tileCount,
            columns: columns,
            margin: margin ?? 0,
            spacing: spacing ?? 0,
            tiles: tiles ?? []
        )
    }
}
