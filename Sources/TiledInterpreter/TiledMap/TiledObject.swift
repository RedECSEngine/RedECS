public enum TiledPropertyValue: Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    public var stringValue: String? {
        if case let .string(value) = self { return value }
        return nil
    }
    public var intValue: Int? {
        if case let .int(value) = self { return value }
        return nil
    }
    public var doubleValue: Double? {
        if case let .double(value) = self { return value }
        return nil
    }
    public var boolValue: Bool? {
        if case let .bool(value) = self { return value }
        return nil
    }
}

public struct TiledProperty: Codable, Equatable {
    public var name: String
    public var value: TiledPropertyValue

    private enum CodingKeys: String, CodingKey {
        case name, type, value
    }

    public init(name: String, value: TiledPropertyValue) {
        self.name = name
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let type = try container.decodeIfPresent(String.self, forKey: .type) ?? "string"
        switch type {
        case "int": value = .int(try container.decode(Int.self, forKey: .value))
        case "float": value = .double(try container.decode(Double.self, forKey: .value))
        case "bool": value = .bool(try container.decode(Bool.self, forKey: .value))
        default: value = .string(try container.decode(String.self, forKey: .value))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        switch value {
        case let .string(value):
            try container.encode("string", forKey: .type)
            try container.encode(value, forKey: .value)
        case let .int(value):
            try container.encode("int", forKey: .type)
            try container.encode(value, forKey: .value)
        case let .double(value):
            try container.encode("float", forKey: .type)
            try container.encode(value, forKey: .value)
        case let .bool(value):
            try container.encode("bool", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

public struct TiledObject: Codable, Equatable {
    public var id: Int
    public var name: String
    public var rotation: Double
    public var text: TiledText?

    public var type: String?
    public var visible: Bool

    public var width: Double
    public var height: Double
    public var x: Double
    public var y: Double

    public var properties: [TiledProperty]

    public init(
        id: Int,
        name: String,
        type: String?,
        x: Double,
        y: Double,
        width: Double = 0,
        height: Double = 0,
        rotation: Double = 0,
        visible: Bool = true,
        properties: [TiledProperty] = [],
        text: TiledText? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rotation = rotation
        self.visible = visible
        self.properties = properties
        self.text = text
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, rotation, text, type, visible, width, height, x, y, properties
        // Tiled 1.9 renamed an object's `type` to `class` in exported files
        case objectClass = "class"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        rotation = try container.decode(Double.self, forKey: .rotation)
        text = try container.decodeIfPresent(TiledText.self, forKey: .text)
        type = try container.decodeIfPresent(String.self, forKey: .type)
            ?? container.decodeIfPresent(String.self, forKey: .objectClass)
        visible = try container.decode(Bool.self, forKey: .visible)
        width = try container.decode(Double.self, forKey: .width)
        height = try container.decode(Double.self, forKey: .height)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        properties = try container.decodeIfPresent([TiledProperty].self, forKey: .properties) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(rotation, forKey: .rotation)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(visible, forKey: .visible)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        if !properties.isEmpty {
            try container.encode(properties, forKey: .properties)
        }
    }
}

public extension TiledObject {
    subscript(property name: String) -> TiledPropertyValue? {
        properties.first { $0.name == name }?.value
    }
}
