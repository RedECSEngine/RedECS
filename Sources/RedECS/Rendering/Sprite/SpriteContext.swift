public struct SpriteContext: GameState {
    public var entities: EntityRepository = .init()
    public var transform: [EntityId: TransformComponent]
    public var sprite: [EntityId: SpriteComponent]

    public init(
        entities: EntityRepository = .init(),
        transform: [EntityId: TransformComponent],
        sprite: [EntityId: SpriteComponent]
    ) {
        self.entities = entities
        self.transform = transform
        self.sprite = sprite
    }
}
