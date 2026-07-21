public struct TiledWangColor: Codable, Equatable {
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
}

public struct TiledWangTile: Codable, Equatable {
    public var tileid: Int
    public var wangid: [Int]

    public init(tileid: Int, wangid: [Int]) {
        self.tileid = tileid
        self.wangid = wangid
    }
}

public struct TiledWangSet: Codable, Equatable {
    public var name: String
    public var type: String
    public var colors: [TiledWangColor]
    public var wangtiles: [TiledWangTile]

    public init(name: String, type: String, colors: [TiledWangColor], wangtiles: [TiledWangTile]) {
        self.name = name
        self.type = type
        self.colors = colors
        self.wangtiles = wangtiles
    }
}
