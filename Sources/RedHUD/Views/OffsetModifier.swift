import Geometry
import RedECS

public struct OffsetModifier<Content: HUDView>: BuiltinHUDView {
    public var x: Double
    public var y: Double
    public var content: Content

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        content._size(proposed: proposed, context: context)
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var child = content._resolve(proposed: proposed, context: context.descending(into: 0))
        let size = child.frame.size
        child.frame.origin = Point(x: x, y: y)
        return HUDNode(
            frame: Rect(origin: .zero, size: size),
            children: [child]
        )
    }
}

public extension HUDView {
    func offset(x: Double = 0, y: Double = 0) -> OffsetModifier<Self> {
        OffsetModifier(x: x, y: y, content: self)
    }
}
