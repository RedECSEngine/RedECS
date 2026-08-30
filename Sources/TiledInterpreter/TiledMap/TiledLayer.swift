public struct TiledLayer: Codable, Equatable, Sendable {
    public var id: Int
    public var name: String
    public var type: TiledLayerType
    public var layerClass: String?

    public var data: [TiledGID]?
    public var objects: [TiledObject]?
    public var layers: [TiledLayer]?
    public var image: String?

    public var opacity: Double
    public var visible: Bool
    public var tintColor: String?

    public var width: Int?
    public var height: Int?
    public var x: Double
    public var y: Double
    public var offsetX: Double
    public var offsetY: Double
    public var parallaxX: Double
    public var parallaxY: Double

    public var properties: [TiledProperty]

    public init(
        id: Int,
        name: String,
        type: TiledLayerType,
        layerClass: String? = nil,
        data: [TiledGID]? = nil,
        objects: [TiledObject]? = nil,
        layers: [TiledLayer]? = nil,
        image: String? = nil,
        opacity: Double = 1,
        visible: Bool = true,
        tintColor: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        x: Double = 0,
        y: Double = 0,
        offsetX: Double = 0,
        offsetY: Double = 0,
        parallaxX: Double = 1,
        parallaxY: Double = 1,
        properties: [TiledProperty] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.layerClass = layerClass
        self.data = data
        self.objects = objects
        self.layers = layers
        self.image = image
        self.opacity = opacity
        self.visible = visible
        self.tintColor = tintColor
        self.width = width
        self.height = height
        self.x = x
        self.y = y
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.parallaxX = parallaxX
        self.parallaxY = parallaxY
        self.properties = properties
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, type, data, objects, layers, image, opacity, visible
        case width, height, x, y, properties, chunks, encoding, compression
        case layerClass = "class"
        case tintColor = "tintcolor"
        case offsetX = "offsetx"
        case offsetY = "offsety"
        case parallaxX = "parallaxx"
        case parallaxY = "parallaxy"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try container.decodeIfPresent(TiledLayerType.self, forKey: .type) ?? .unsupported("")
        layerClass = try container.decodeIfPresent(String.self, forKey: .layerClass)
        objects = try container.decodeIfPresent([TiledObject].self, forKey: .objects)
        layers = try container.decodeIfPresent([TiledLayer].self, forKey: .layers)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1
        visible = try container.decodeIfPresent(Bool.self, forKey: .visible) ?? true
        tintColor = try container.decodeIfPresent(String.self, forKey: .tintColor)
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
        x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 0
        y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 0
        offsetX = try container.decodeIfPresent(Double.self, forKey: .offsetX) ?? 0
        offsetY = try container.decodeIfPresent(Double.self, forKey: .offsetY) ?? 0
        parallaxX = try container.decodeIfPresent(Double.self, forKey: .parallaxX) ?? 1
        parallaxY = try container.decodeIfPresent(Double.self, forKey: .parallaxY) ?? 1
        properties = try container.decodeIfPresent([TiledProperty].self, forKey: .properties) ?? []

        if container.contains(.chunks) {
            throw TiledError.infiniteMapsUnsupported(layer: name)
        }

        data = try Self.decodeData(from: container, layerName: name)
    }

    private static func decodeData(
        from container: KeyedDecodingContainer<CodingKeys>,
        layerName: String
    ) throws -> [TiledGID]? {
        guard container.contains(.data) else { return nil }

        if let values = try? container.decode([UInt32].self, forKey: .data) {
            return values.map(TiledGID.init(rawValue:))
        }

        guard let encoded = try? container.decode(String.self, forKey: .data) else {
            throw TiledError.malformedLayerData(layer: layerName)
        }

        let encoding = try container.decodeIfPresent(String.self, forKey: .encoding) ?? "base64"
        guard encoding == "base64" else {
            throw TiledError.unsupportedLayerDataEncoding(layer: layerName, encoding: encoding)
        }

        if let compression = try container.decodeIfPresent(String.self, forKey: .compression),
           !compression.isEmpty {
            throw TiledError.compressedLayerDataUnsupported(layer: layerName, compression: compression)
        }

        guard let values = Base64.decodeLittleEndianUInt32s(encoded) else {
            throw TiledError.malformedLayerData(layer: layerName)
        }
        return values.map(TiledGID.init(rawValue:))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(layerClass, forKey: .layerClass)
        try container.encodeIfPresent(data?.map(\.rawValue), forKey: .data)
        try container.encodeIfPresent(objects, forKey: .objects)
        try container.encodeIfPresent(layers, forKey: .layers)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(visible, forKey: .visible)
        try container.encodeIfPresent(tintColor, forKey: .tintColor)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        if offsetX != 0 { try container.encode(offsetX, forKey: .offsetX) }
        if offsetY != 0 { try container.encode(offsetY, forKey: .offsetY) }
        if parallaxX != 1 { try container.encode(parallaxX, forKey: .parallaxX) }
        if parallaxY != 1 { try container.encode(parallaxY, forKey: .parallaxY) }
        if !properties.isEmpty { try container.encode(properties, forKey: .properties) }
    }
}

public extension TiledLayer {
    var tileLayers: [TiledLayer] { flattenedLayers(ofType: .tileLayer) }
    var objectLayers: [TiledLayer] { flattenedLayers(ofType: .objectGroup) }

    func flattenedLayers(ofType type: TiledLayerType) -> [TiledLayer] {
        guard self.type == .group else {
            return self.type == type ? [self] : []
        }
        return (layers ?? []).flatMap { child in
            child.inheriting(from: self).flattenedLayers(ofType: type)
        }
    }

    func inheriting(from parent: TiledLayer) -> TiledLayer {
        var inherited = self
        inherited.visible = visible && parent.visible
        inherited.opacity = opacity * parent.opacity
        inherited.offsetX = offsetX + parent.offsetX
        inherited.offsetY = offsetY + parent.offsetY
        inherited.parallaxX = parallaxX * parent.parallaxX
        inherited.parallaxY = parallaxY * parent.parallaxY
        inherited.tintColor = tintColor ?? parent.tintColor
        return inherited
    }

    subscript(property name: String) -> TiledPropertyValue? {
        properties.first { $0.name == name }?.value
    }

    func tile(atColumn column: Int, row: Int) -> TiledGID? {
        guard let data,
              let columns = width,
              let rows = height,
              column >= 0, column < columns,
              row >= 0, row < rows else { return nil }
        let index = (columns * row) + column
        guard index < data.count else { return nil }
        return data[index]
    }

    func tile(atColumn column: Int, rowFromBottom row: Int) -> TiledGID? {
        guard let rows = height else { return nil }
        return tile(atColumn: column, row: (rows - 1) - row)
    }
}
