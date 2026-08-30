
public protocol BasicOperationCapableState: GameState {
    var transform: [EntityId: TransformComponent] { get set }
    var sprite: [EntityId: SpriteComponent] { get set }
}

public struct BasicOperationComponentContext: GameState, BasicOperationCapableState {
    public var entities: EntityRepository = .init()
    public var transform: [EntityId: TransformComponent] = [:]
    public var sprite: [EntityId: SpriteComponent] = [:]

    public init(
        entities: EntityRepository,
        transform: [EntityId: TransformComponent],
        sprite: [EntityId: SpriteComponent]
    ) {
        self.entities = entities
        self.transform = transform
        self.sprite = sprite
    }
}
