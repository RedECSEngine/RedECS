import RedECS

public struct StaticTextureComponent: GameComponent {
    public var entity: EntityId
    public var textureName: String
    public var lastSetTextureName: String?

    public init(
        entity: EntityId,
        textureName: String
    ) {
        self.entity = entity
        self.textureName = textureName
    }
}

