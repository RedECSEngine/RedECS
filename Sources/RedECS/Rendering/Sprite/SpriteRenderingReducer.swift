import Geometry
import GeometryAlgorithms

public struct SpriteRenderingReducer: Reducer {
    public init() {}
    
    public func reduce(
        state: inout SpriteContext,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<SpriteContext, Never> {
        state.sprite.forEach { (id, spriteComponent) in
            guard let transform = state.transform[id] else { return }
            environment.renderer.enqueue(spriteComponent.renderGroups(
                transform: transform,
                resourceManager: environment.resourceManager
            ))
        }
        return .none
    }
    
    public func reduce(
        state: inout SpriteContext,
        entityEvent: EntityEvent,
        environment: RenderingEnvironment
    ) {

    }
}


