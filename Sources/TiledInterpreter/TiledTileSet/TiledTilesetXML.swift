public struct TiledTilesetXML: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case name
        case image
        case tileWidth = "tilewidth"
        case tileHeight = "tileheight"
        case tileCount = "tilecount"
        case columns
        case tiles = "tile"
    }
    
    public var name: String
    public var tileWidth: Int
    public var tileHeight: Int
    public var tileCount: Int
    public var columns: Int
    public var image: Image
    public var tiles: [Tile]?
    
    public func makeTileInfoDictionary() -> [Int: Tile] {
        tiles.map {
            // we add 1 to the id to compensate for the difference between tile data ids (where 0 == nothing) and the tile id (where 0 is the first tile)
            $0.reduce(into: [Int: Tile]()) { $0[$1.id + 1] = $1 }
        } ?? [:]
    }
}

public extension TiledTilesetXML {
    struct Image: Codable, Equatable {
        public var source: String
        public var width: Int
        public var height: Int
    }
}

public extension TiledTilesetXML {
    func toJSONFormat() -> TiledTilesetJSON {
        return TiledTilesetJSON(
            name: name,
            image: image.source,
            imageWidth: image.width,
            imageHeight: image.height,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            tileCount: tileCount,
            columns: columns,
            tiles: tiles ?? []
        )
    }
}
