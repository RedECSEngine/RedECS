public struct TextureReference: Equatable, Codable {
    public let textureId: TextureId
    public let frameId: String?
    
    public init(textureId: TextureId, frameId: String?) {
        self.textureId = textureId
        self.frameId = frameId
    }
}
