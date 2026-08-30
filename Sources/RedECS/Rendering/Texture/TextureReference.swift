public struct TextureReference: Equatable, Codable, Sendable {
    public let textureId: TextureId
    public var frameId: String?
    
    public init(textureId: TextureId, frameId: String?) {
        self.textureId = textureId
        self.frameId = frameId
    }
    
    public static let empty: TextureReference = .init(textureId: "", frameId: nil)
}
