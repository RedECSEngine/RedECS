public struct AnimationReference: Codable, Equatable, Sendable {
    public let textureId: TextureId
    public let animationName: String
    
    public init(textureId: TextureId, animationName: String) {
        self.textureId = textureId
        self.animationName = animationName
    }
}
