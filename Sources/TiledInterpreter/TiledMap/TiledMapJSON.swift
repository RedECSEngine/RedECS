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
    
    public init(
        tileWidth: Int,
        tileHeight: Int,
        width: Int,
        height: Int,
        layers: [TiledLayer],
        tileSets: [TileSetReference]
    ) {
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.width = width
        self.height = height
        self.layers = layers
        self.tileSets = tileSets
    }
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
    
    func splitTileLayersToMaps() -> [TiledMapJSON] {
        (0..<layers.count)
            .compactMap { i in
                guard layers[i].type == .tileLayer else { return nil }
                return TiledMapJSON(
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    width: width,
                    height: height,
                    layers: [layers[i]],
                    tileSets: tileSets
                )
            }
    }

}
