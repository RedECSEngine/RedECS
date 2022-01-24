import Foundation
import RedECS
import RedECSBasicComponents

public struct SpriteReducerContext: GameState {
    public var entities: EntityRepository = .init()
    public var position: [EntityId: PositionComponent]
    public var sprite: [EntityId: SpriteComponent]
    
    public init(
        entities: EntityRepository = .init(),
        position: [EntityId: PositionComponent],
        sprite: [EntityId: SpriteComponent]
    ) {
        self.entities = entities
        self.position = position
        self.sprite = sprite
    }
}
