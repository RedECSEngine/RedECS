import RedECS
import RedECSBasicComponents

public struct SpriteRenderingContext: GameState {
    public var entities: EntityRepository = .init()
    public var position: [EntityId: PositionComponent]
    public var transform: [EntityId: TransformComponent]
    public var sprite: [EntityId: SpriteComponent]
    
    public init(
        entities: EntityRepository = .init(),
        position: [EntityId: PositionComponent],
        transform: [EntityId: TransformComponent],
        sprite: [EntityId: SpriteComponent]
    ) {
        self.entities = entities
        self.position = position
        self.transform = transform
        self.sprite = sprite
    }
}
