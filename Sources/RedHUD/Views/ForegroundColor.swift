import Geometry
import RedECS

public struct ForegroundColor<Content: HUDView>: BuiltinHUDView {
    public var color: Color
    public var content: Content

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        content._size(proposed: proposed, context: modified(context))
    }

    public func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        content._render(context: modified(context), size: size)
    }

    private func modified(_ context: HUDRenderContext) -> HUDRenderContext {
        var context = context
        context.fillColor = color
        return context
    }
}

public extension HUDView {
    func foregroundColor(_ color: Color) -> ForegroundColor<Self> {
        ForegroundColor(color: color, content: self)
    }
}
