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
                    .translatedBy(tx: transform.position.x, ty: transform.position.y)
                    .rotatedBy(angleInRadians: -transform.rotate.degreesToRadians())
                let triangles = try shapeComponent.shape.triangulate().enumerated()
                    .map { (i, triangle) -> RenderTriangle in
                        RenderTriangle(triangle: triangle)
                    }
                environment.renderer.enqueue([
                    RenderGroup(
                        triangles: triangles,
                        transformMatrix: matrix,
                        fragmentType: .color(shapeComponent.fillColor),
                        zIndex: transform.zIndex
                    )
                ])
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


