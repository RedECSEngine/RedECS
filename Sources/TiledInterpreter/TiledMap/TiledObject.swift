public enum TiledPropertyValue: Equatable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case color(String)
    case file(String)
    case object(Int)
    case unsupported

    public var stringValue: String? {
        switch self {
        case let .string(value), let .color(value), let .file(value): return value
        default: return nil
        }
    }
    public var intValue: Int? {
        switch self {
        case let .int(value), let .object(value): return value
        default: return nil
        }
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

public struct TiledProperty: Codable, Equatable, Sendable {
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
        case "color": value = .color(try container.decode(String.self, forKey: .value))
        case "file": value = .file(try container.decode(String.self, forKey: .value))
        case "object": value = .object(try container.decode(Int.self, forKey: .value))
        case "string": value = .string(try container.decode(String.self, forKey: .value))
        default:
            if let string = try? container.decode(String.self, forKey: .value) {
                value = .string(string)
            } else if let int = try? container.decode(Int.self, forKey: .value) {
                value = .int(int)
            } else if let double = try? container.decode(Double.self, forKey: .value) {
                value = .double(double)
            } else if let bool = try? container.decode(Bool.self, forKey: .value) {
                value = .bool(bool)
            } else {
                value = .unsupported
            }
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
        case let .color(value):
            try container.encode("color", forKey: .type)
            try container.encode(value, forKey: .value)
        case let .file(value):
            try container.encode("file", forKey: .type)
            try container.encode(value, forKey: .value)
        case let .object(value):
            try container.encode("object", forKey: .type)
            try container.encode(value, forKey: .value)
        case .unsupported:
            break
        }
    }
}

public struct TiledPoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public enum TiledObjectShape: Equatable, Sendable {
    case rectangle
    case point
    case ellipse
    case polygon([TiledPoint])
    case polyline([TiledPoint])
    case text(TiledText)
    case tile(TiledGID)
}

public struct TiledObject: Codable, Equatable, Sendable {
    public var id: Int
    public var name: String
    public var type: String?
    public var shape: TiledObjectShape
    public var template: String?

    public var rotation: Double
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
        shape: TiledObjectShape = .rectangle,
        template: String? = nil,
        properties: [TiledProperty] = []
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
        self.shape = shape
        self.template = template
        self.properties = properties
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, rotation, text, type, visible, width, height, x, y, properties
        case point, ellipse, polygon, polyline, gid, template
        // Tiled 1.9 renamed an object's `type` to `class` in exported files
        case objectClass = "class"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        rotation = try container.decodeIfPresent(Double.self, forKey: .rotation) ?? 0
        type = try container.decodeIfPresent(String.self, forKey: .type)
            ?? container.decodeIfPresent(String.self, forKey: .objectClass)
        visible = try container.decodeIfPresent(Bool.self, forKey: .visible) ?? true
        width = try container.decodeIfPresent(Double.self, forKey: .width) ?? 0
        height = try container.decodeIfPresent(Double.self, forKey: .height) ?? 0
        x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 0
        y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 0
        template = try container.decodeIfPresent(String.self, forKey: .template)
        properties = try container.decodeIfPresent([TiledProperty].self, forKey: .properties) ?? []

        if try container.decodeIfPresent(Bool.self, forKey: .point) == true {
            shape = .point
        } else if try container.decodeIfPresent(Bool.self, forKey: .ellipse) == true {
            shape = .ellipse
        } else if let polygon = try container.decodeIfPresent([TiledPoint].self, forKey: .polygon) {
            shape = .polygon(polygon)
        } else if let polyline = try container.decodeIfPresent([TiledPoint].self, forKey: .polyline) {
            shape = .polyline(polyline)
        } else if let text = try container.decodeIfPresent(TiledText.self, forKey: .text) {
            shape = .text(text)
        } else if let gid = try container.decodeIfPresent(UInt32.self, forKey: .gid) {
            shape = .tile(TiledGID(rawValue: gid))
        } else {
            shape = .rectangle
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(rotation, forKey: .rotation)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(visible, forKey: .visible)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encodeIfPresent(template, forKey: .template)
        switch shape {
        case .rectangle:
            break
        case .point:
            try container.encode(true, forKey: .point)
        case .ellipse:
            try container.encode(true, forKey: .ellipse)
        case let .polygon(points):
            try container.encode(points, forKey: .polygon)
        case let .polyline(points):
            try container.encode(points, forKey: .polyline)
        case let .text(text):
            try container.encode(text, forKey: .text)
        case let .tile(gid):
            try container.encode(gid.rawValue, forKey: .gid)
        }
        if !properties.isEmpty {
            try container.encode(properties, forKey: .properties)
        }
    }
}

public extension TiledObject {
    subscript(property name: String) -> TiledPropertyValue? {
        properties.first { $0.name == name }?.value
    }

    var gid: TiledGID? {
        if case let .tile(gid) = shape { return gid }
        return nil
    }

    var text: TiledText? {
        if case let .text(text) = shape { return text }
        return nil
    }
}
