import Foundation
import RedECS
import RedECSBasicComponents

public struct SpriteReducerContext: GameState {
    public var entities: Set<EntityId>
    public var position: [EntityId: PositionComponent]
    public var sprite: [EntityId: SpriteComponent]
    
    public init(
        entities: Set<EntityId>,
        position: [EntityId: PositionComponent],
        sprite: [EntityId: SpriteComponent]
    ) {
        self.entities = entities
        self.position = position
        self.sprite = sprite
    }
}
