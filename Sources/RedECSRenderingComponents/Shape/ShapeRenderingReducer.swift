import RedECS
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
            do {
                let triangles = try shapeComponent.shape.triangulate().enumerated()
                    .map { (i, triangle) -> RenderTriangle in
                        let triangle = triangle
                            .offset(by: transform.position)
                            .rotated(around: transform.position, degrees: -transform.rotate)
                        return RenderTriangle(
                            triangle: triangle,
                            fragmentType: .color(shapeComponent.fillColor),
                            zIndex: transform.zIndex
                        )
                    }
                environment.renderer.enqueueTriangles(triangles)
            } catch {
                print("⚠️ couldn't render shape", error)
            }
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


