import RedECS
import RedECSBasicComponents

public struct StaticTextureRenderingContext: GameState {
    public var entities: EntityRepository
    public var position: [EntityId: PositionComponent]
    public var transform: [EntityId: TransformComponent]
    public var staticTextureRendering: [EntityId: StaticTextureComponent]
    
    public init(
        entities: EntityRepository,
        position: [EntityId: PositionComponent],
        transform: [EntityId: TransformComponent],
        staticTextureRendering: [EntityId: StaticTextureComponent]
    ) {
        self.entities = entities
        self.position = position
        self.transform = transform
        self.staticTextureRendering = staticTextureRendering
    }
}
