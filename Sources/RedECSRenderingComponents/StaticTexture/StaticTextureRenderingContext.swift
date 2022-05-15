import RedECS
import RedECSBasicComponents

public struct StaticTextureRenderingContext: GameState {
    public var entities: EntityRepository
    public var transform: [EntityId: TransformComponent]
    public var staticTextureRendering: [EntityId: StaticTextureComponent]
    
    public init(
        entities: EntityRepository,
        transform: [EntityId: TransformComponent],
        staticTextureRendering: [EntityId: StaticTextureComponent]
    ) {
        self.entities = entities
        self.transform = transform
        self.staticTextureRendering = staticTextureRendering
    }
}
