public struct TiledTilesetReference: Codable, Equatable, Sendable {
    public var firstGid: Int
    public var source: String?
    public var tileSet: TiledTilesetJSON?

    public init(firstGid: Int, source: String) {
        self.firstGid = firstGid
        self.source = source
        self.tileSet = nil
    }

    public init(firstGid: Int, tileSet: TiledTilesetJSON, source: String? = nil) {
        self.firstGid = firstGid
        self.source = source
        self.tileSet = tileSet
    }

    private enum CodingKeys: String, CodingKey {
        case source
        case firstGid = "firstgid"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstGid = try container.decodeIfPresent(Int.self, forKey: .firstGid) ?? 1
        source = try container.decodeIfPresent(String.self, forKey: .source)
        tileSet = source == nil ? try TiledTilesetJSON(from: decoder) : nil
    }

    public func encode(to encoder: Encoder) throws {
        if let source {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(firstGid, forKey: .firstGid)
            try container.encode(source, forKey: .source)
            return
        }
        try tileSet?.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstGid, forKey: .firstGid)
    }

    public var isResolved: Bool { tileSet != nil }
}

public struct TiledMapJSON: Codable, Equatable, Sendable {
    public enum CodingKeys: String, CodingKey {
        case tileWidth = "tilewidth"
        case tileHeight = "tileheight"
        case tileSets = "tilesets"
        case renderOrder = "renderorder"
        case width
        case height
        case layers
        case infinite
        case orientation
        case properties
    }

    public var tileWidth: Int
    public var tileHeight: Int
    public var width: Int
    public var height: Int
    public var infinite: Bool
    public var orientation: String?
    public var renderOrder: String?
    public var properties: [TiledProperty]

    public var layers: [TiledLayer]
    public var tileSets: [TiledTilesetReference] {
        didSet { tileSets.sort { $0.firstGid < $1.firstGid } }
    }

    public init(
        tileWidth: Int,
        tileHeight: Int,
        width: Int,
        height: Int,
        layers: [TiledLayer],
        tileSets: [TiledTilesetReference],
        infinite: Bool = false,
        orientation: String? = "orthogonal",
        renderOrder: String? = nil,
        properties: [TiledProperty] = []
    ) {
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.width = width
        self.height = height
        self.layers = layers
        self.tileSets = tileSets.sorted { $0.firstGid < $1.firstGid }
        self.infinite = infinite
        self.orientation = orientation
        self.renderOrder = renderOrder
        self.properties = properties
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            tileWidth: try container.decodeIfPresent(Int.self, forKey: .tileWidth) ?? 0,
            tileHeight: try container.decodeIfPresent(Int.self, forKey: .tileHeight) ?? 0,
            width: try container.decodeIfPresent(Int.self, forKey: .width) ?? 0,
            height: try container.decodeIfPresent(Int.self, forKey: .height) ?? 0,
            layers: try container.decodeIfPresent([TiledLayer].self, forKey: .layers) ?? [],
            tileSets: try container.decodeIfPresent([TiledTilesetReference].self, forKey: .tileSets) ?? [],
            infinite: try container.decodeIfPresent(Bool.self, forKey: .infinite) ?? false,
            orientation: try container.decodeIfPresent(String.self, forKey: .orientation),
            renderOrder: try container.decodeIfPresent(String.self, forKey: .renderOrder),
            properties: try container.decodeIfPresent([TiledProperty].self, forKey: .properties) ?? []
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tileWidth, forKey: .tileWidth)
        try container.encode(tileHeight, forKey: .tileHeight)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(layers, forKey: .layers)
        try container.encode(tileSets, forKey: .tileSets)
        try container.encode(infinite, forKey: .infinite)
        try container.encodeIfPresent(orientation, forKey: .orientation)
        try container.encodeIfPresent(renderOrder, forKey: .renderOrder)
        if !properties.isEmpty { try container.encode(properties, forKey: .properties) }
    }
}

public struct TiledTileReference: Equatable, Sendable {
    public let tileSet: TiledTilesetJSON
    public let localId: Int
    public let tile: TiledTile?

    public init(tileSet: TiledTilesetJSON, localId: Int, tile: TiledTile?) {
        self.tileSet = tileSet
        self.localId = localId
        self.tile = tile
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
        layers.flatMap { $0.tileLayers }
    }
    var objectLayers: [TiledLayer] {
        layers.flatMap { $0.objectLayers }
    }
    var objects: [TiledObject] {
        objectLayers.flatMap { $0.objects ?? [] }
    }

    subscript(property name: String) -> TiledPropertyValue? {
        properties.first { $0.name == name }?.value
    }

    func splitTileLayersToMaps() -> [TiledMapJSON] {
        tileLayers.map { layer in
            TiledMapJSON(
                tileWidth: tileWidth,
                tileHeight: tileHeight,
                width: width,
                height: height,
                layers: [layer],
                tileSets: tileSets,
                infinite: infinite,
                orientation: orientation,
                renderOrder: renderOrder,
                properties: properties
            )
        }
    }

    func tileSetIndex(forGid gid: TiledGID) -> Int? {
        guard !gid.isEmpty else { return nil }
        var match: Int?
        for (index, reference) in tileSets.enumerated() {
            if reference.firstGid <= gid.id {
                match = index
            } else {
                break
            }
        }
        return match
    }

    func tileSetReference(forGid gid: TiledGID) -> TiledTilesetReference? {
        tileSetIndex(forGid: gid).map { tileSets[$0] }
    }

    var maximumTileSize: (width: Int, height: Int) {
        tileSets.reduce((width: tileWidth, height: tileHeight)) { largest, reference in
            guard let tileSet = reference.tileSet else { return largest }
            return (
                width: max(largest.width, tileSet.tileWidth),
                height: max(largest.height, tileSet.tileHeight)
            )
        }
    }

    func tileSet(forGid gid: TiledGID) -> TiledTilesetJSON? {
        tileSetReference(forGid: gid)?.tileSet
    }

    func tile(forGid gid: TiledGID) -> TiledTileReference? {
        guard let reference = tileSetReference(forGid: gid), let tileSet = reference.tileSet else {
            return nil
        }
        let localId = gid.id - reference.firstGid
        return TiledTileReference(
            tileSet: tileSet,
            localId: localId,
            tile: tileSet.tile(withLocalId: localId)
        )
    }

    var unresolvedTileSetSources: [String] {
        tileSets.compactMap { $0.isResolved ? nil : $0.source }
    }

    func resolvingTileSets(from resolved: [String: TiledTilesetJSON]) throws -> TiledMapJSON {
        var map = self
        map.tileSets = try tileSets.map { reference in
            guard !reference.isResolved, let source = reference.source else { return reference }
            guard let tileSet = resolved[source] else {
                throw TiledError.unresolvedTileSet(source: source)
            }
            return TiledTilesetReference(firstGid: reference.firstGid, tileSet: tileSet, source: source)
        }
        return map
    }
}
