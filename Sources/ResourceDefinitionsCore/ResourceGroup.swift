public enum ResourceGroup: CaseIterable, Sendable {
    case images
    case fonts
    case tileMaps
    case tileSets
    case json
    case csv
    case sounds

    public var enumName: String {
        switch self {
        case .images: "Images"
        case .fonts: "Fonts"
        case .tileMaps: "TileMaps"
        case .tileSets: "TileSets"
        case .json: "JSON"
        case .csv: "CSV"
        case .sounds: "Sounds"
        }
    }

    public var resourceTypeCase: String {
        switch self {
        case .images: "image"
        case .fonts: "bitmapFont"
        case .tileMaps: "tilemap"
        case .tileSets: "tileset"
        case .json: "json"
        case .csv: "csv"
        case .sounds: "soundSprite"
        }
    }

    public var isPreloadable: Bool {
        self != .sounds
    }
}

public struct ResourceEntry: Equatable, Sendable {
    public let identifier: String
    public let name: String
    public let ext: String

    public init(identifier: String, name: String, ext: String) {
        self.identifier = identifier
        self.name = name
        self.ext = ext
    }
}

public struct ResourceCatalog: Equatable, Sendable {
    var groups: [ResourceGroup: [ResourceEntry]] = [:]

    public init() {}

    public func entries(in group: ResourceGroup) -> [ResourceEntry] {
        groups[group] ?? []
    }
}

public struct ResourceDiagnostic: Equatable, Sendable {
    public enum Severity: Sendable {
        case warning
        case error
    }

    public let severity: Severity
    public let message: String

    static func warning(_ message: String) -> ResourceDiagnostic {
        ResourceDiagnostic(severity: .warning, message: message)
    }

    static func error(_ message: String) -> ResourceDiagnostic {
        ResourceDiagnostic(severity: .error, message: message)
    }
}

public struct ResourceClassification: Equatable, Sendable {
    public let catalog: ResourceCatalog
    public let diagnostics: [ResourceDiagnostic]

    public var hasErrors: Bool {
        diagnostics.contains { $0.severity == .error }
    }
}
