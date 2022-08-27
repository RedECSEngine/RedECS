import Geometry
import GeometryAlgorithms

public struct ShapeRenderingReducer: Reducer {
    public init() {}
    
    public func reduce(
        state: inout ShapeRenderingContext,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<ShapeRenderingContext, Never> {
        state.shape.forEach { (id, shapeComponent) in
            guard let transform = state.transform[id] else { return }
            environment.renderer.enqueue(shapeComponent.renderGroups(transform: transform, resourceManager: environment.resourceManager))
        }
        return .none
    }
    
    public func reduce(
        state: inout ShapeRenderingContext,
        entityEvent: EntityEvent,
        environment: RenderingEnvironment
    ) {

    }
}


