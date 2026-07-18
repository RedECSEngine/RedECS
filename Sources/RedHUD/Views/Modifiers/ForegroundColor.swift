import Geometry
import RedECS

public struct ForegroundColor<Content: HUDView>: BuiltinHUDView {
    public var color: Color
    public var content: Content

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var context = context
        context.fillColor = color
        return content._resolve(proposed: proposed, context: context)
    }
}

public extension HUDView {
    func foregroundColor(_ color: Color) -> ForegroundColor<Self> {
        ForegroundColor(color: color, content: self)
    }
}
