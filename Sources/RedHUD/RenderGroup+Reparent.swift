import Geometry
import GeometryAlgorithms
import RedECS

extension RenderGroup {
    /// A copy of this group translated into a parent's frame; containers use
    /// this to place already-rendered children at their laid-out positions.
    func reparented(by offset: Point) -> RenderGroup {
        withTransformMatrix(
            .multiply(
                Matrix3.identity.translatedBy(tx: offset.x, ty: offset.y),
                transformMatrix
            )
        )
    }
}
