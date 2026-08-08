public struct BasicOperationComponentContext: GameState {
    public var entities: EntityRepository = .init()
    public var transform: [EntityId: TransformComponent] = [:]
    public var sprite: [EntityId: SpriteComponent] = [:]
    public var movement: [EntityId: MovementComponent] = [:]

    public init(
        entities: EntityRepository,
        transform: [EntityId: TransformComponent],
        sprite: [EntityId: SpriteComponent],
        movement: [EntityId: MovementComponent] = [:]
    ) {
        self.entities = entities
        self.transform = transform
        self.sprite = sprite
        self.movement = movement
    }
}
