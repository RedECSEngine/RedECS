public struct TiledText: Codable, Equatable, Sendable {
    public var text: String
    public var color: String?
    public var fontFamily: String?
    public var pixelSize: Int?
    public var horizontalAlignment: String?
    public var verticalAlignment: String?
    public var wrap: Bool

    private enum CodingKeys: String, CodingKey {
        case text, color, wrap
        case fontFamily = "fontfamily"
        case pixelSize = "pixelsize"
        case horizontalAlignment = "halign"
        case verticalAlignment = "valign"
    }

    public init(
        text: String,
        color: String? = nil,
        fontFamily: String? = nil,
        pixelSize: Int? = nil,
        horizontalAlignment: String? = nil,
        verticalAlignment: String? = nil,
        wrap: Bool = false
    ) {
        self.text = text
        self.color = color
        self.fontFamily = fontFamily
        self.pixelSize = pixelSize
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.wrap = wrap
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        color = try container.decodeIfPresent(String.self, forKey: .color)
        fontFamily = try container.decodeIfPresent(String.self, forKey: .fontFamily)
        pixelSize = try container.decodeIfPresent(Int.self, forKey: .pixelSize)
        horizontalAlignment = try container.decodeIfPresent(String.self, forKey: .horizontalAlignment)
        verticalAlignment = try container.decodeIfPresent(String.self, forKey: .verticalAlignment)
        wrap = try container.decodeIfPresent(Bool.self, forKey: .wrap) ?? false
    }
}
