public struct TextureReference: Equatable, Codable {
    public let textureId: TextureId
    public var frameId: String?
    
    public init(textureId: TextureId, frameId: String?) {
        self.textureId = textureId
        self.frameId = frameId
    }
    
    public static var empty: TextureReference = .init(textureId: "", frameId: nil)
}
