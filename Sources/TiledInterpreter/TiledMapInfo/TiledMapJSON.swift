public struct TiledMapInfoJSON<TOT: TiledObjectType>: Codable, Equatable {
    public enum CodingKeys: String, CodingKey {
        case tileWidth = "tilewidth"
        case tileHeight = "tileheight"
        case width
        case height
        case layers
    }
    
    public var tileWidth: Int
    public var tileHeight: Int
    public var width: Int
    public var height: Int
    
    public var layers: [TiledLayer<TOT>]
}
