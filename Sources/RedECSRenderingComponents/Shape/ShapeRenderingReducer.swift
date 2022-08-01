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
                let matrix = Matrix3
                    .identity
                    .rotatedBy(angleInRadians: -transform.rotate.degreesToRadians())
                    .translatedBy(tx: transform.position.x, ty: transform.position.y)
                let triangles = try shapeComponent.shape.triangulate().enumerated()
                    .map { (i, triangle) -> RenderTriangle in
                        RenderTriangle(
                            triangle: triangle,
                            fragmentType: .color(shapeComponent.fillColor),
                            transformMatrix: matrix,
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


