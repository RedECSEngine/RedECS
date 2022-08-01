public struct TileSetReference: Codable, Equatable {
    public var firstgid: Int
    public var source: String
}

public struct TiledMapJSON: Codable, Equatable {
    public enum CodingKeys: String, CodingKey {
        case tileWidth = "tilewidth"
        case tileHeight = "tileheight"
        case tileSets = "tilesets"
        case width
        case height
        case layers
    }
    
    public var tileWidth: Int
    public var tileHeight: Int
    public var width: Int
    public var height: Int
    
    public var layers: [TiledLayer]
    public var tileSets: [TileSetReference]
}

public extension TiledMapJSON {
    var totalWidth: Double {
        Double(tileWidth * width)
    }
    var totalHeight: Double {
        Double(tileHeight * height)
    }
    var tileLayers: [TiledLayer] {
        layers.filter { $0.type == .tileLayer }
    }
    var objectLayers: [TiledLayer] {
        layers.filter { $0.type == .objectGroup }
    }
}
