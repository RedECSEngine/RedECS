public enum TiledLayerType: Equatable, Hashable, Codable, Sendable {
    case tileLayer
    case objectGroup
    case imageLayer
    case group
    case unsupported(String)

    public init(rawValue: String) {
        switch rawValue {
        case "tilelayer": self = .tileLayer
        case "objectgroup": self = .objectGroup
        case "imagelayer": self = .imageLayer
        case "group": self = .group
        default: self = .unsupported(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .tileLayer: return "tilelayer"
        case .objectGroup: return "objectgroup"
        case .imageLayer: return "imagelayer"
        case .group: return "group"
        case .unsupported(let rawValue): return rawValue
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
