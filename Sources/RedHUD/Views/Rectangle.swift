import Geometry
import GeometryAlgorithms
import RedECS

public struct Rectangle: BuiltinHUDView {
    public init() {}

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        proposed.orDefault()
    }

    public func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        let rect = Rect(origin: .zero, size: size)
        guard let triangulated = try? rect.triangulate() else { return [] }
        return [
            RenderGroup(
                triangles: triangulated.map { RenderTriangle(triangle: $0) },
                transformMatrix: .identity,
                fragmentType: .color(context.fillColor),
                zIndex: 0,
                opacity: context.opacity
            )
        ]
    }
}
