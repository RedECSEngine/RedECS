public struct TiledMap<TOT: TiledObjectType, TTC: TiledTileClass>: Equatable, Codable {
    public let mapInfo: TiledMapInfoJSON<TOT>
    public let tileSetInfo: TiledTilesetJSON<TTC>
    
    public init(
        mapInfo: TiledMapInfoJSON<TOT>,
        tileSetInfo: TiledTilesetJSON<TTC>
    ) throws {
        self.mapInfo = mapInfo
        self.tileSetInfo = tileSetInfo
    }
}

public extension TiledMap {
    var totalWidth: Double {
        Double(mapInfo.tileWidth * mapInfo.width)
    }
    var totalHeight: Double {
        Double(mapInfo.tileHeight * mapInfo.height)
    }
    var tileLayers: [TiledLayer<TOT>] {
        mapInfo.layers.filter { $0.type == .tileLayer }
    }
    var objectLayers: [TiledLayer<TOT>] {
        mapInfo.layers.filter { $0.type == .objectGroup }
    }
}
