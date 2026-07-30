import Geometry
import GeometryAlgorithms
import RedECS

public struct Rectangle: BuiltinHUDView {
    public init() {}

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        proposed.orDefault()
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        let rect = Rect(origin: .zero, size: size(proposed: proposed, context: context))
        guard let triangulated = try? rect.triangulate() else {
            return HUDNode(frame: rect)
        }
        return HUDNode(
            frame: rect,
            groups: [
                RenderGroup(
                    triangles: triangulated.map { RenderTriangle(triangle: $0) },
                    transformMatrix: .identity,
                    fragmentType: .color(context.fillColor),
                    zIndex: 0,
                    opacity: context.opacity,
                    projectionSpace: context.projectionSpace
                )
            ]
        )
    }
}
