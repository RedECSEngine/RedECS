import Foundation
import RedECS
import RedECSBasicComponents

public struct ShapeReducerContext: GameState {
    public var entities: Set<EntityId>
    public var position: [EntityId: PositionComponent]
    public var transform: [EntityId: TransformComponent]
    public var shape: [EntityId: ShapeComponent]
    
    public init(
        entities: Set<EntityId>,
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
