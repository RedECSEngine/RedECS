import Geometry
import RedECS

/// Sets the bitmap font face name `Text` views in the subtree use by default.
public struct FontModifier<Content: HUDView>: BuiltinHUDView {
    public var fontName: String
    public var content: Content

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        content._size(proposed: proposed, context: modified(context))
    }

    public func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        content._render(context: modified(context), size: size)
    }

    private func modified(_ context: HUDRenderContext) -> HUDRenderContext {
        var context = context
        context.font = fontName
        return context
    }
}

public extension HUDView {
    func font(_ name: String) -> FontModifier<Self> {
        FontModifier(fontName: name, content: self)
    }
}
