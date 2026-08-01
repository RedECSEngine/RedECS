public struct TiledTilesetJSON: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey {
        case name
        case image
        case imageWidth = "imagewidth"
        case imageHeight = "imageheight"
        case tileWidth = "tilewidth"
        case tileHeight = "tileheight"
        case tileCount = "tilecount"
        case columns
        case margin
        case spacing
        case tiles
        case wangsets
        case properties
    }

    public let name: String
    public let image: String?
    public let imageWidth: Int?
    public let imageHeight: Int?
    public let tileWidth: Int
    public let tileHeight: Int
    public let tileCount: Int
    public let columns: Int
    public let margin: Int
    public let spacing: Int
    public let tiles: [TiledTile]
    public let wangsets: [TiledWangSet]
    public let properties: [TiledProperty]

    private let tilesById: [Int: TiledTile]

    public init(
        name: String,
        image: String? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        tileWidth: Int,
        tileHeight: Int,
        tileCount: Int,
        columns: Int,
        margin: Int = 0,
        spacing: Int = 0,
        tiles: [TiledTile] = [],
        wangsets: [TiledWangSet] = [],
        properties: [TiledProperty] = []
    ) {
        self.name = name
        self.image = image
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.tileCount = tileCount
        self.columns = columns
        self.margin = margin
        self.spacing = spacing
        self.tiles = tiles
        self.wangsets = wangsets
        self.properties = properties
        self.tilesById = tiles.reduce(into: [:]) { $0[$1.id] = $1 }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decodeIfPresent(String.self, forKey: .name) ?? "",
            image: try container.decodeIfPresent(String.self, forKey: .image),
            imageWidth: try container.decodeIfPresent(Int.self, forKey: .imageWidth),
            imageHeight: try container.decodeIfPresent(Int.self, forKey: .imageHeight),
            tileWidth: try container.decodeIfPresent(Int.self, forKey: .tileWidth) ?? 0,
            tileHeight: try container.decodeIfPresent(Int.self, forKey: .tileHeight) ?? 0,
            tileCount: try container.decodeIfPresent(Int.self, forKey: .tileCount) ?? 0,
            columns: try container.decodeIfPresent(Int.self, forKey: .columns) ?? 0,
            margin: try container.decodeIfPresent(Int.self, forKey: .margin) ?? 0,
            spacing: try container.decodeIfPresent(Int.self, forKey: .spacing) ?? 0,
            tiles: try container.decodeIfPresent([TiledTile].self, forKey: .tiles) ?? [],
            wangsets: try container.decodeIfPresent([TiledWangSet].self, forKey: .wangsets) ?? [],
            properties: try container.decodeIfPresent([TiledProperty].self, forKey: .properties) ?? []
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(imageWidth, forKey: .imageWidth)
        try container.encodeIfPresent(imageHeight, forKey: .imageHeight)
        try container.encode(tileWidth, forKey: .tileWidth)
        try container.encode(tileHeight, forKey: .tileHeight)
        try container.encode(tileCount, forKey: .tileCount)
        try container.encode(columns, forKey: .columns)
        if margin != 0 { try container.encode(margin, forKey: .margin) }
        if spacing != 0 { try container.encode(spacing, forKey: .spacing) }
        if !tiles.isEmpty { try container.encode(tiles, forKey: .tiles) }
        if !wangsets.isEmpty { try container.encode(wangsets, forKey: .wangsets) }
        if !properties.isEmpty { try container.encode(properties, forKey: .properties) }
    }
}

public extension TiledTilesetJSON {
    var rows: Int? {
        guard let imageHeight, tileHeight > 0 else { return nil }
        return imageHeight / tileHeight
    }

    var isImageCollection: Bool { image == nil }

    var textureId: String? {
        guard let image else { return nil }
        let fileName = image.split(separator: "/").last.map(String.init) ?? image
        let components = fileName.split(separator: ".")
        guard components.count > 1 else { return fileName }
        return components.dropLast().joined(separator: ".")
    }

    func tile(withLocalId id: Int) -> TiledTile? {
        tilesById[id]
    }

    subscript(property name: String) -> TiledPropertyValue? {
        properties.first { $0.name == name }?.value
    }
}
