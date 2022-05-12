import RedECS
import RedECSBasicComponents

public struct ShapeRenderingContext: GameState {
    public var entities: EntityRepository = .init()
    public var position: [EntityId: PositionComponent]
    public var transform: [EntityId: TransformComponent]
    public var shape: [EntityId: ShapeComponent]
    
    public init(
        entities: EntityRepository = .init(),
        position: [EntityId: PositionComponent],
        transform: [EntityId: TransformComponent],
        shape: [EntityId: ShapeComponent]
    ) {
        self.entities = entities
        self.position = position
        self.transform = transform
        self.shape = shape
    }
}