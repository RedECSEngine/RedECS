import Geometry
import RedECS

/// Sets the bitmap font face name `Text` views in the subtree use by default.
public struct FontModifier<Content: HUDView>: BuiltinHUDView {
    public var fontName: String
    public var content: Content

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var context = context
        context.font = fontName
        return content._resolve(proposed: proposed, context: context)
    }
}

public extension HUDView {
    func font(_ name: String) -> FontModifier<Self> {
        FontModifier(fontName: name, content: self)
    }
}
