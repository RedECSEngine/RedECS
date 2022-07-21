import RedECS

public struct SpriteComponent: GameComponent {
    public var entity: EntityId
    public var texture: TextureReference
    
    public init(
        entity: EntityId,
        texture: TextureReference
    ) {
        self.entity = entity
        self.texture = texture
    }
}
