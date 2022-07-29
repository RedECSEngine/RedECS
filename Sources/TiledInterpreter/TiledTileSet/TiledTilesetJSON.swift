public struct TiledTilesetJSON<TTC: TiledTileClass>: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case name
        case imageWidth = "imagewidth"
        case imageHeight = "imageheight"
        case tileWidth = "tilewidth"
        case tileHeight = "tileheight"
        case tileCount = "tilecount"
        case columns
        case tiles = "tile"
    }
    
    public var name: String
    public var imageWidth: Int
    public var imageHeight: Int
    public var tileWidth: Int
    public var tileHeight: Int
    public var tileCount: Int
    public var columns: Int
    public var tiles: [Tile<TTC>]?
    
    public init(
        name: String,
        imageWidth: Int,
        imageHeight: Int,
        tileWidth: Int,
        tileHeight: Int,
        tileCount: Int,
        columns: Int,
        tiles: [Tile<TTC>]? = nil
    ) {
        self.name = name
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.tileCount = tileCount
        self.columns = columns
        self.tiles = tiles
    }
    
    public func makeTileInfoDictionary() -> [Int: Tile<TTC>] {
        tiles.map {
            // we add 1 to the id to compensate for the difference between tile data ids (where 0 == nothing) and the tile id (where 0 is the first tile)
            $0.reduce(into: [Int: Tile<TTC>]()) { $0[$1.id + 1] = $1 }
        } ?? [:]
    }
}
