import Foundation
import RedECS
import RedECSBasicComponents
import SpriteKit

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

public struct SpriteRenderingEnvironment {
    public var renderer: Renderer
    public init(
        renderer: Renderer
    ) {
        self.renderer = renderer
    }
}

public struct SpriteRenderingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout SpriteReducerContext,
        delta: Double,
        environment: SpriteRenderingEnvironment
    ) -> GameEffect<SpriteReducerContext, Never> {
        state.sprite.forEach { (id, sprite) in
            guard let position = state.position[id] else { return }
            if sprite.node.parent == nil {
                environment.renderer.add(sprite.node)
            }
            sprite.node.position = CGPoint(x: position.point.x, y: position.point.y)
            sprite.node.zPosition = CGFloat(-position.point.y)
        }
        return .none
    }
}
