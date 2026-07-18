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

    /// A copy at `factor` of this group's opacity, routed the way each
    /// fragment type actually blends: the renderers read `opacity` only for
    /// texture groups, while color groups blend with their fill color's own
    /// alpha — so the factor must fold into the color there.
    func applyingOpacityFactor(_ factor: Double) -> RenderGroup {
        switch fragmentType {
        case .color(let color):
            return RenderGroup(
                triangles: triangles,
                transformMatrix: transformMatrix,
                fragmentType: .color(color.withAlpha(color.alpha * factor)),
                zIndex: zIndex,
                opacity: opacity * factor,
                projectionSpace: projectionSpace
            )
        case .texture:
            return withOpacity(opacity * factor)
        }
    }
}
